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
    setState(() { _messages.add({'role': 'user', 'content': text}); _isLoading = true; });
    _controller.clear();
    final history = _messages.take(_messages.length - 1).map((m) => {'role': m['role']!, 'content': m['content']!}).toList();
    final response = await _apiService.chatWithCerebras(text, history: history);
    if (mounted) setState(() { _messages.add({'role': 'assistant', 'content': response}); _isLoading = false; });
  }

  Widget _buildMessage(Map<String, String> message) {
    bool isUser = message['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryRed : AppColors.darkCardLight,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
          ),
          border: isUser ? null : Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: isUser
            ? Text(message['content'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15))
            : MarkdownBody(data: message['content'] ?? '', styleSheet: MarkdownStyleSheet(p: const TextStyle(color: AppColors.textPrimary, fontSize: 15))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.accentPurple.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.auto_awesome, color: AppColors.accentPurple, size: 20)),
          const SizedBox(width: 10),
          const Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        backgroundColor: AppColors.darkSurface, foregroundColor: AppColors.textPrimary, elevation: 0,
      ),
      body: Column(children: [
        if (_messages.isEmpty)
          Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.accentPurple.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, color: AppColors.accentPurple, size: 48)),
            const SizedBox(height: 20),
            const Text('RoadSoS AI', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Ask about hospitals, first aid,\nor emergency tips!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textTertiary, fontSize: 15)),
          ])))
        else
          Expanded(child: ListView.builder(padding: const EdgeInsets.only(top: 10, bottom: 20), itemCount: _messages.length, itemBuilder: (_, i) => _buildMessage(_messages[i]))),
        if (_isLoading) Padding(padding: const EdgeInsets.all(8.0), child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          const SizedBox(width: 16),
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.accentPurple, strokeWidth: 2)),
          const SizedBox(width: 8),
          Text('Thinking...', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ])),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.darkSurface, border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06)))),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type your message...', hintStyle: TextStyle(color: AppColors.textTertiary),
                filled: true, fillColor: AppColors.darkCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            )),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.accentPurple, AppColors.accentPink]), borderRadius: BorderRadius.circular(14)),
              child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22), onPressed: _sendMessage),
            ),
          ]),
        ),
      ]),
    );
  }
}
