async function sendMessage() {
    const input = document.getElementById("user-input");
    const chatBox = document.getElementById("chat-box");

    const msg = input.value.trim();
    if (!msg) return;
    
    input.value = "";

    // Remove welcome message on first interaction
    const welcomeMsg = chatBox.querySelector('.welcome-message');
    if (welcomeMsg) {
        welcomeMsg.remove();
    }

    chatBox.innerHTML += `<div class="user"><strong>You:</strong> ${msg}</div>`;
    chatBox.scrollTop = chatBox.scrollHeight;

    // Show loading message with animation
    chatBox.innerHTML += `<div class="bot loading"><strong>Assistant:</strong> Thinking...</div>`;
    chatBox.scrollTop = chatBox.scrollHeight;

    try {
        const res = await fetch("/chat", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ message: msg })
        });

        const data = await res.json();
        
        // Remove loading message and add response
        const messages = chatBox.querySelectorAll('.bot');
        messages[messages.length - 1].remove();
        
        chatBox.innerHTML += `<div class="bot"><strong>Assistant:</strong> ${data.reply}</div>`;
        chatBox.scrollTop = chatBox.scrollHeight;
    } catch (error) {
        // Remove loading message and show error
        const messages = chatBox.querySelectorAll('.bot');
        messages[messages.length - 1].remove();
        
        chatBox.innerHTML += `<div class="bot"><strong>Assistant:</strong> ❌ Error connecting to server</div>`;
        chatBox.scrollTop = chatBox.scrollHeight;
    }
}

// Add Enter key support
document.getElementById("user-input").addEventListener("keypress", function(event) {
    if (event.key === "Enter") {
        sendMessage();
    }
});
