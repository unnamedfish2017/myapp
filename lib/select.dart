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
        title: const Text('GFs'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                String userId = await _getDeviceIdentifier();
                Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: ChatArguments('shihan', userId),
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
              onTap: () async {
                String userId = await _getDeviceIdentifier();
                Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: ChatArguments('xiaoxia', userId), // 示例用户信息
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
