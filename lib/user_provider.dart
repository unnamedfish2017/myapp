// user_provider.dart
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _userId;

  String? get userId => _userId;

  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }
}
