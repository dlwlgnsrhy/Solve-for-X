import 'package:flutter/material.dart';
import '../config/app_config.dart';

class SecureChatPage extends StatefulWidget {
  const SecureChatPage({super.key});

  @override
  State<SecureChatPage> createState() => _SecureChatPageState();
}

class _SecureChatPageState extends State<SecureChatPage> {
  final List<Map<String, dynamic>> _messages = [
    {"sender": "bot", "text": "Welcome to your SafeSpace sanctuary chat. Log daily thoughts with complete hardware isolation.", "time": "Just now"},
  ];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        "sender": "user",
        "text": _controller.text.trim(),
        "time": "Just now",
      });
      String text = _controller.text.toLowerCase();
      _controller.clear();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          String reply = "Your safe space diary has updated. This log stays locally on device.";
          if (text.contains("sad") || text.contains("anxious") || text.contains("stress")) {
            reply = "Take a slow, deep breath. Your logs are secure and isolated. Feel free to clear them anytime.";
          } else if (text.contains("todo") || text.contains("task")) {
            reply = "Task ideas recorded securely. You can catalog them in your Checklist tab.";
          }
          _messages.add({
            "sender": "bot",
            "text": reply,
            "time": "Just now",
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConfig.cardColor,
        elevation: 0,
        title: const Text(
          'Mindful Advisor',
          style: TextStyle(color: AppConfig.primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: AppConfig.secondaryColor),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  "sender": "bot",
                  "text": "Memory wipe complete. SafeSpace logs pristine.",
                  "time": "Just now"
                });
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? AppConfig.primaryColor : AppConfig.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppConfig.borderRadius),
                        topRight: const Radius.circular(AppConfig.borderRadius),
                        bottomLeft: Radius.circular(isUser ? AppConfig.borderRadius : 0),
                        bottomRight: Radius.circular(isUser ? 0 : AppConfig.borderRadius),
                      ),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Text(
                      msg["text"],
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.grey.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: AppConfig.cardColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Reflect on your mood...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppConfig.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: AppConfig.primaryColor,
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                )
              ], 
            ),
          )
        ],
      ),
    );
  }
}