import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_provider.dart';

class RegisterPage extends StatefulWidget {
  RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  void _register(BuildContext context) async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    const String registerUrl =
        "http://116.205.182.116:3000/register"; // 替换为你的 MongoDB 后端 API URL
    const String username_author = "gfs";
    const String password_author = "gfs202407";
    String basicAuth = 'Basic ' +
        base64Encode(
            utf8.encode('$username_author:$password_author')); // 替换为实际的用户名和密码

    var response = await http.post(
      Uri.parse(registerUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': basicAuth, // 添加授权信息到请求头
      },
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      Navigator.pushReplacementNamed(context, '/select');
      Provider.of<UserProvider>(context, listen: false).setUserId(username);
    } else {
      setState(() {
        _errorMessage = json.decode(response.body)['message'];
      });
    }
  }

  void _login(BuildContext context) async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    const String loginUrl =
        "http://116.205.182.116:3000/login"; // 替换为你的 MongoDB 后端 API URL
    const String username_author = "gfs";
    const String password_author = "gfs202407";
    String basicAuth = 'Basic ' +
        base64Encode(
            utf8.encode('$username_author:$password_author')); // 替换为实际的用户名和密码

    var response = await http.post(
      Uri.parse(loginUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': basicAuth, // 添加授权信息到请求头
      },
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      Navigator.pushReplacementNamed(context, '/select');
      Provider.of<UserProvider>(context, listen: false).setUserId(username);
    } else {
      setState(() {
        _errorMessage = json.decode(response.body)['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: '用户名'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: '密码'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () => _register(context),
                  child: Text('注册'),
                ),
                ElevatedButton(
                  onPressed: () => _login(context),
                  child: Text('登录'),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
