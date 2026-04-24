import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = String.fromEnvironment('GROQ_API_KEY');
  final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer \$apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': 'llama-3.1-8b-instant',
        'messages': [{'role': 'user', 'content': 'Test'}],
        'max_tokens': 10,
      }),
    );
    if (response.statusCode == 200) {
      print('SUCCESS');
    } else {
      print('FAILED: ' + response.statusCode.toString() + ' - ' + response.body);
    }
  } catch (e) {
    print('ERROR: ' + e.toString());
  }
}
