import 'package:flutter/material.dart';
import 'main.dart'; // 替换为您的聊天页面文件路径

class FirstPage extends StatelessWidget {
  const FirstPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GFs'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments:
                      ChatArguments('shihan', 'unique_chat_id'), // 示例用户信息
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/shihan.png', // 替换为您的图片路径
                  width: 200,
                  height: 200,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments:
                      ChatArguments('xiaoxia', 'unique_chat_id'), // 示例用户信息
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/xiaoxia.png', // 替换为您的图片路径
                  width: 200,
                  height: 200,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
