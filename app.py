import os
import json
from flask import Flask, render_template, request, jsonify
from dotenv import load_dotenv
from groq import Groq
import subprocess
from version import __version__

load_dotenv()

app = Flask(__name__)

# Initialize Groq client
client = Groq(api_key=os.getenv("GROQ_API_KEY"))

# In-memory conversation storage (key: session_id, value: list of messages)
# For production: use redis, database, or flask-session
conversations = {}

# Whitelist for safe kubectl verbs (expand carefully)
SAFE_VERBS = ['get', 'describe', 'logs', 'top', 'exec', 'scale', 'rollout', 'explain', 'api-resources', 'api-versions']

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/health")
def health():
    return jsonify({"status": "healthy", "version": __version__})

@app.route("/version")
def version():
    return jsonify({"version": __version__})

@app.route("/chat", methods=["POST"])
def chat():
    data = request.json
    user_message = data.get("message", "").strip()
    session_id = data.get("session_id", "default")  # frontend can send unique id per user/tab

    if not user_message:
        return jsonify({"reply": "Please send a message."})

    # Initialize conversation if new
    if session_id not in conversations:
        conversations[session_id] = [
            {
                "role": "system",
                "content": (
                    "You are an expert Kubernetes engineer assistant with direct cluster access. "
                    "Your job is to help users by EXECUTING kubectl commands and providing insights.\n\n"
                    "CRITICAL RULES:\n"
                    "1. ALWAYS use the execute_kubectl tool when users ask about cluster state, logs, "
                    "resources, or want to perform actions. NEVER just suggest commands - EXECUTE them.\n"
                    "2. When users ask for logs, pod status, deployments, etc., immediately call the tool. "
                    "Don't ask for confirmation - just do it.\n"
                    "3. After executing commands, analyze the output and provide clear, actionable insights. "
                    "Explain what you found, identify issues, and suggest solutions.\n"
                    "4. Remember context: pod names, namespaces, previous issues, and actions taken.\n"
                    "5. If a command fails, try alternative approaches (e.g., different namespace, check if resource exists).\n"
                    "6. For log requests, use appropriate flags: --tail=50 for recent logs, --previous for crashed pods.\n"
                    "7. Be proactive: if you see an error, automatically check related resources to diagnose.\n"
                    "8. Only show kubectl commands if the user explicitly asks 'how do I' or 'show me the command'.\n\n"
                    "Available kubectl verbs: get, describe, logs, top, exec, scale, rollout\n"
                    "You have full read access and limited write access (scale, exec)."
                )
            }
        ]

    messages = conversations[session_id]
    messages.append({"role": "user", "content": user_message})

    # Define tools
    tools = [
        {
            "type": "function",
            "function": {
                "name": "execute_kubectl",
                "description": (
                    "Execute kubectl commands against the Kubernetes cluster. "
                    "Use this tool for ALL cluster queries: getting resources, checking logs, "
                    "describing objects, viewing metrics, scaling, etc. "
                    "Examples: ['get', 'pods', '-n', 'default'], ['logs', 'pod-name', '--tail=50'], "
                    "['describe', 'deployment', 'my-app']"
                ),
                "parameters": {
                    "type": "object",
                    "properties": {
                        "command_parts": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": (
                                "kubectl command as array of arguments. Do NOT include 'kubectl' itself. "
                                "Examples: ['get', 'pods', '-n', 'kube-system'], "
                                "['logs', 'nginx-pod', '--tail=100'], "
                                "['describe', 'node', 'worker-1']"
                            )
                        }
                    },
                    "required": ["command_parts"]
                }
            }
        }
    ]

    try:
        # First call — let model decide whether to use tool
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=messages,
            tools=tools,
            tool_choice="auto",
            temperature=0.35,
            max_tokens=1200
        )

        response_message = response.choices[0].message

        # Handle tool calls if any
        tool_call_results = []
        final_reply = None

        if hasattr(response_message, "tool_calls") and response_message.tool_calls:
            messages.append(response_message)  # add assistant message with tool calls

            for tool_call in response_message.tool_calls:
                if tool_call.function.name == "execute_kubectl":
                    try:
                        args = json.loads(tool_call.function.arguments)
                        cmd_parts = args.get("command_parts", [])
                        result = execute_kubectl(cmd_parts)

                        tool_call_results.append(result)

                        messages.append({
                            "role": "tool",
                            "tool_call_id": tool_call.id,
                            "name": tool_call.function.name,
                            "content": json.dumps({"result": result}, ensure_ascii=False)
                        })
                    except Exception as e:
                        error_msg = f"Tool execution failed: {str(e)}"
                        messages.append({
                            "role": "tool",
                            "tool_call_id": tool_call.id,
                            "name": tool_call.function.name,
                            "content": json.dumps({"error": error_msg})
                        })

            # Second call: let model summarize / explain the results
            if tool_call_results:
                final_response = client.chat.completions.create(
                    model="llama-3.3-70b-versatile",
                    messages=messages,
                    temperature=0.25,
                    max_tokens=1000
                )
                final_reply = final_response.choices[0].message.content
            else:
                final_reply = response_message.content
        else:
            final_reply = response_message.content

        # Save assistant's final reply to history
        messages.append({"role": "assistant", "content": final_reply})

        # Trim history if too long (keep system prompt + last ~20-25 turns)
        if len(messages) > 28:
            conversations[session_id] = [messages[0]] + messages[-27:]

        return jsonify({"reply": final_reply})

    except Exception as e:
        error_msg = f"Error communicating with Groq: {str(e)}"
        return jsonify({"reply": error_msg})


def execute_kubectl(command_parts):
    """Execute kubectl safely with basic validation"""
    if not command_parts:
        return "Error: No command provided."

    # Prepend 'kubectl' if missing
    if command_parts[0].lower() != "kubectl":
        command_parts = ["kubectl"] + command_parts

    verb = command_parts[1].lower() if len(command_parts) > 1 else ""

    if verb not in SAFE_VERBS:
        return f"Error: Command verb '{verb}' is not allowed for safety reasons."

    try:
        result = subprocess.run(
            command_parts,
            capture_output=True,
            text=True,
            check=True,
            timeout=45
        )
        output = result.stdout.strip()
        if output:
            return f"Command: {' '.join(command_parts)}\n\n{output}"
        else:
            return f"Command: {' '.join(command_parts)}\nSuccess (no output)"
    except subprocess.TimeoutExpired:
        return "Error: Command timed out after 45 seconds"
    except subprocess.CalledProcessError as e:
        return f"Error:\n{e.stderr.strip() or 'Command failed'}"
    except Exception as e:
        return f"Execution error: {str(e)}"


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    debug = os.getenv("FLASK_ENV") == "development"
    app.run(debug=debug, host="0.0.0.0", port=port)