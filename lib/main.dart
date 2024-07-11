import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat UI Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage(String text, bool isUserMessage) {
    setState(() {
      _messages.add({
        'text': text,
        'isUserMessage': isUserMessage,
      });
      if (isUserMessage) {
        _controller.clear();
        _simulateAutoReply(text);
      }
    });
  }

  Future<void> _simulateAutoReply(String userMessage) async {
    // 调用 Moonshot API 获取自动回复
    const String apiUrl = 'https://api.moonshot.cn/v1/chat/completions'; // 替换为你的 Moonshot API URL
    const String apiKey = 'sk-3sq88ly5bVhIQNbuqPi7xPiLlG5mtNrucHI0LbHK6RnDmDGb'; // 替换为你的 API KEY
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: json.encode({
        'model': 'moonshot-v1-8k',
        'messages': [
          {
            'role': 'system',
            'content': '你是 Kimi，由 Moonshot AI 提供的人工智能助手，你更擅长中文和英文的对话。你会为用户提供安全，有帮助，准确的回答。同时，你会拒绝一切涉及恐怖主义，种族歧视，黄色暴力等问题的回答。Moonshot AI 为专有名词，不可翻译成其他语言。'
          },
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': 0.3
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final replyMessage = data['choices'][0]['message']['content']; // 假设 API 返回的 JSON 包含一个 'reply' 字段

      setState(() {
        _messages.add({
          'text': replyMessage,
          'isUserMessage': false,
        });
      });
    } else {
      // 处理 API 请求失败的情况
      setState(() {
        _messages.add({
          'text': 'Failed to get reply from Moonshot API',
          'isUserMessage': false,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final alignment = message['isUserMessage']
                    ? Alignment.centerRight
                    : Alignment.centerLeft;
                final color = message['isUserMessage']
                    ? Colors.blue[200]
                    : Colors.grey[300];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 14),
                  alignment: alignment,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(message['text']),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter a message',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text, true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
