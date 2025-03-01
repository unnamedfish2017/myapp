import 'package:flutter/material.dart';
import 'main.dart'; // 替换为您的聊天页面文件路径
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class FirstPage extends StatelessWidget {
  const FirstPage({Key? key}) : super(key: key);

  Future<String> _getDeviceIdentifier() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return androidInfo.androidId ?? 'unknown';
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown'; // 使用iOS的唯一ID，处理为空情况
      }
    } catch (e) {
      print('Error getting device identifier: $e');
    }
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小宝专属'),
      ),
      body: Stack(
        children: <Widget>[
          // 背景图片
          Positioned.fill(
            child: Image.asset(
              'assets/blue.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 30.0), // 设置左侧间距
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    String userId = await _getDeviceIdentifier();
                    Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: ChatArguments('jsxh', userId),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/bs.jpeg', // 替换为您的图片路径
                          width: 200,
                          height: 200,
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '精神小伙',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '干我屁事，\n干你屁事，\n干他大爷',
                              style: TextStyle(fontSize: 15),
                              maxLines: null,
                              overflow: TextOverflow.clip, // 超出部分直接截断
                            ),
                            // Text(
                            //   '点击与诗涵聊天', // 添加您的描述文本
                            //   style: TextStyle(fontSize: 14, color: Colors.grey),
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}
