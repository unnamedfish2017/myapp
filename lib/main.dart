import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

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
    const String apiUrl =
        "http://116.205.182.116:3000/messages"; // 替换为你的 MongoDB 后端 API URL
    try {
      // 调用 MongoDB 后端 API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': userMessage,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final replyMessage =
            data['replyMessage'] as String; // 根据后端返回的数据结构调整获取回复消息的方式
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
        throw Exception('接收到错误响应: ${response.statusCode}');
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
    WidgetsBinding.instance!.addPostFrameCallback((_) {
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
                    final isUserMessage = message['isUserMessage'];
                    final alignment = isUserMessage
                        ? Alignment.centerRight
                        : Alignment.centerLeft;
                    final color =
                        isUserMessage ? Colors.blue[200] : Colors.grey[300];
                    final avatar = isUserMessage
                        ? 'assets/user_avatar.jpg'
                        : 'assets/system_avatar.png';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      alignment: alignment,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUserMessage)
                            CircleAvatar(
                              backgroundImage: AssetImage(avatar),
                            ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                message['text'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          if (isUserMessage) const SizedBox(width: 8),
                          if (isUserMessage)
                            CircleAvatar(
                              backgroundImage: AssetImage(avatar),
                            ),
                        ],
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
                          hintText: '输入消息',
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
