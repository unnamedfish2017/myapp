import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'select.dart'; // 替换为第一页的Dart文件路径

void main() {
  runApp(MyApp());
}

class ChatArguments {
  final String girlId;
  final String userId; // 新增用户信息字段

  ChatArguments(this.girlId, this.userId);
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  // 定义路由映射
  final Map<String, WidgetBuilder> routes = {
    '/': (context) => const FirstPage(), // 首页
    '/chat': (context) => const ChatScreen(), // 聊天页面
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Navigation Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // 设置初始路由为首页
      routes: routes, // 将路由映射传递给 MaterialApp
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

  static const int maxMessages = 1000; // 最大消息历史记录
  late String girlId; // 聊天对象标识符
  late String userId; // 用户标识符
  late String greeting;
  late String bg_img;
  late String avatar_img;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 获取从上一个页面传递的参数

    final args = ModalRoute.of(context)?.settings.arguments as ChatArguments?;
    if (args != null) {
      girlId = args.girlId;
      userId = args.userId;
    } else {
      girlId = '';
      userId = '';
    }

    greeting = girlId == 'xiaoxia'
        ? '小夏'
        : girlId == 'shihan'
            ? '诗涵'
            : '';
    bg_img = girlId == 'xiaoxia'
        ? 'background.png'
        : girlId == 'shihan'
            ? 'background_sh.png'
            : '';
    avatar_img = girlId == 'xiaoxia'
        ? 'system_avatar.png'
        : girlId == 'shihan'
            ? 'system_avatar_sh.png'
            : '';

    _loadMessages(); // 加载存储的聊天记录
  }

  Future<void> _loadMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedMessages;

    if (girlId == 'xiaoxia') {
      storedMessages = prefs.getStringList('xiaoxia_messages');
    } else if (girlId == 'shihan') {
      storedMessages = prefs.getStringList('shihan_messages');
    }

    if (storedMessages != null) {
      setState(() {
        _messages.clear();
        for (String message in storedMessages ?? []) {
          _messages.add(jsonDecode(message));
        }
      });
    }
  }

  Future<void> _saveMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 根据 girlId 存储不同的聊天记录
    List<String> storedMessages = _messages
        .where((message) => message['girlId'] == 'xiaoxia')
        .map((message) => jsonEncode(message))
        .toList();
    await prefs.setStringList('xiaoxia_messages', storedMessages);

    storedMessages = _messages
        .where((message) => message['girlId'] == 'shihan')
        .map((message) => jsonEncode(message))
        .toList();
    await prefs.setStringList('shihan_messages', storedMessages);
  }

  void _sendMessage(String text, bool isUserMessage) {
    setState(() {
      if (_messages.length >= maxMessages) {
        _messages.removeAt(0); // 删除最旧的消息，以保留最新的 maxMessages 条消息
      }
      _messages.add({
        'text': text,
        'isUserMessage': isUserMessage,
        'girlId': girlId,
        'userId': userId,
      });
      if (isUserMessage) {
        _controller.clear();
        _simulateAutoReply(text);
      }
      _scrollToBottom(); // 每次添加新消息时滚动到底部
    });
    _saveMessages(); // 每次发送消息后保存聊天记录
  }

  Future<void> _simulateAutoReply(String userMessage) async {
    const String apiUrl =
        "http://116.205.182.116:3000/messages"; // 替换为你的 MongoDB 后端 API URL
    const String username = "gfs";
    const String password = "gfs202407";
    String basicAuth = 'Basic ' +
        base64Encode(utf8.encode('$username:$password')); // 替换为实际的用户名和密码

    try {
      // 调用 MongoDB 后端 API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': basicAuth, // 添加授权信息到请求头
        },
        body: json.encode({
          'content': userMessage,
          'girlId': girlId,
          'userId': userId,
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
            'girlId': girlId,
            'userId': userId,
          });
          _scrollToBottom(); // 每次添加新消息时滚动到底部
        });
        _saveMessages(); // 保存聊天记录
      } else {
        throw Exception('接收到错误响应: ${response.statusCode}');
      }
    } catch (e) {
      // 将异常对象转换为字符串
      String errorMessage = "稍等哈~"; //e.toString();

      setState(() {
        // 更新状态，添加异常信息作为文本消息
        _messages.add({
          'text': errorMessage,
          'isUserMessage': false,
          'girlId': girlId,
          'userId': userId,
        });
        _scrollToBottom(); // 每次添加新消息时滚动到底部
      });
      _saveMessages(); // 保存聊天记录
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
        title: Text('Chat with $greeting'), // 使用聊天对象标识符作为标题
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/$bg_img', // 确保在你的项目中有这个图片文件
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
                        : 'assets/$avatar_img';

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
                      color: Color.fromARGB(169, 61, 46, 46),
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
