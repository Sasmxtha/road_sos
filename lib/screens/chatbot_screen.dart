import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();

    // The chat history (excluding the very recent message since we pass it as prompt)
    final history = _messages
        .take(_messages.length - 1)
        .map((m) => {'role': m['role']!, 'content': m['content']!})
        .toList();

    final response = await _apiService.chatWithCerebras(text, history: history);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _isLoading = false;
      });
    }
  }

  Widget _buildMessage(Map<String, String> message) {
    bool isUser = message['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryRed : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(2, 2)),
          ],
        ),
        child: isUser
            ? Text(
                message['content'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              )
            : MarkdownBody(
                data: message['content'] ?? '',
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: AppColors.darkGrey, fontSize: 16),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoadSoS AI Assistant'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.lightGrey,
      body: Column(
        children: [
          if (_messages.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Ask me about nearby hospitals,\nfirst aid, or emergency tips!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primaryRed,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
