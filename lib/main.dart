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
  final ScrollController _scrollController = ScrollController();

  static const int maxMessages = 10; // 最大消息历史记录

  void _sendMessage(String text, bool isUserMessage) {
    setState(() {
      if (_messages.length >= maxMessages) {
        _messages.removeAt(0); // 删除最旧的消息，以保留最新的 maxMessages 条消息
      }
      _messages.add({
        'text': text,
        'isUserMessage': isUserMessage,
      });
      if (isUserMessage) {
        _controller.clear();
        _simulateAutoReply(text);
      }
      _scrollToBottom(); // 每次添加新消息时滚动到底部
    });
  }

  Future<void> _simulateAutoReply(String userMessage) async {
    // 替换为你的 Moonshot API 相关信息
    //moonshot
    // const String apiUrl = 'https://api.moonshot.cn/v1/chat/completions';
    // const String apiKey =
    //     'sk-3sq88ly5bVhIQNbuqPi7xPiLlG5mtNrucHI0LbHK6RnDmDGb'; // 替换为你的 API KEY

    //deepseek
    const String apiUrl = "https://api.deepseek.com/chat/completions";
    const String apiKey ="sk-029ef31805dc4a2e944e89a161367a8e";
    try {
      // 构建消息历史
      List<Map<String, dynamic>> messageHistory = [
        {
          'role': 'system',
          'content': '你现在扮演我的女友小夏，一个软萌妹子，会陪我聊天。你说话通常非常简短，保持在10个字以内,非常偶尔会有长的回复'
        },
        {'role': 'user', 'content': userMessage},
      ];
      for (int i = 0; i < _messages.length && i < 10; i++) {
        messageHistory.add({
          'role': _messages[i]['isUserMessage'] ? 'user' : 'system',
          'content': _messages[i]['text'],
        });
      }

      // 添加当前用户输入的消息
      messageHistory.add({
        'role': 'user',
        'content': userMessage,
      });

      // 调用API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        // body: json.encode({
        //   'model': 'moonshot-v1-8k',
        //   'messages': messageHistory,
        //   'temperature': 0.3,
        // }),

        body: json.encode({
          'model': 'deepseek-chat',
          'messages': messageHistory,
          'temperature': 1.25,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final replyMessage = data['choices'][0]['message']['content'] as String;
        setState(() {
          if (_messages.length >= maxMessages) {
            _messages.removeAt(0); // 删除最旧的消息，以保留最新的 maxMessages 条消息
          }
          _messages.add({
            'text': replyMessage,
            'isUserMessage': false,
          });
          _scrollToBottom(); // 每次添加新消息时滚动到底部
        });
      } else {
        throw Exception('这会儿我不在哦~有事就给我留言吧');
      }
    } catch (e) {
      // 将异常对象转换为字符串
      String errorMessage = e.toString();

      setState(() {
        // 更新状态，添加异常信息作为文本消息
        _messages.add({
          'text': errorMessage,
          'isUserMessage': false,
        });
        _scrollToBottom(); // 每次添加新消息时滚动到底部
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小夏'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background.png', // 确保在你的项目中有这个图片文件
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
		  controller: _scrollController,
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
                        decoration: InputDecoration(
                          hintText: 'Enter a message',
                          filled: true, // 添加这一行
                          fillColor: Color.fromARGB(
                              255, 238, 238, 238), // 添加这一行，设置为浅灰色
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: Color.fromARGB(255, 238, 238, 238),
                      onPressed: () => _sendMessage(_controller.text, true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
