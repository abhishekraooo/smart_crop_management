import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> messages = [];
  final TextEditingController _controller = TextEditingController();

  Future<String> getBotResponse(String userMessage) async {
    // 🔑 Replace with your actual Cohere API key
    final String apiKey = "NhRwJblRiBOqgtnMm0EnSG5eO7k5gf4Ew4OYGGXd";
    final String apiUrl = 'https://api.cohere.ai/v1/generate';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Cohere-Version': '2022-12-06',
      },
      body: jsonEncode({
        "model": "command-r-plus", // You can also try "command-r-plus"
        "prompt":
            "You are an agricultural assistant. Answer the following query:\n\n$userMessage",
        "max_tokens": 400,
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        return data['generations'][0]['text'].trim();
      } catch (e) {
        return "Failed to parse AI response.";
      }
    } else {
      // 🐞 Print detailed error for debugging
      print('🔴 API Error Status Code: ${response.statusCode}');
      print('🔴 Response Body: ${response.body}');
      return "API Error: ${response.statusCode}";
    }
  }

  void _handleSubmit(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add(Message(text: text, isUser: true));
    });

    _controller.clear();

    String botReply = await getBotResponse(text);

    setState(() {
      messages.add(Message(text: botReply, isUser: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AgriBot 🌱"), backgroundColor: Colors.green),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  alignment:
                      message.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color:
                          message.isUser ? Colors.green[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask about crops, pests, or farming...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _handleSubmit(_controller.text),
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
