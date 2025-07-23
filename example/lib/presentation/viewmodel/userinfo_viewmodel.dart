import 'package:flutter/material.dart';
import '/presentation/model/user.dart';

class UserInfoViewModel extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  void loadUser(User user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
