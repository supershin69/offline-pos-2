import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:offline_pos/core/database/database.dart';

class AuthService {
  final AppDatabase _db;

  AuthService(this._db);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<LoginResult> login(String email, String password) async {
    final user = await _db.getUserByEmail(email);

    if (user == null) {
      return LoginResult(
        success: false,
        errorMessage: "Invalid Email or Password",
      );
    }

    final hashedPassword = _hashPassword(password);

    if (user.password != hashedPassword) {
      return LoginResult(
        success: false,
        errorMessage: "Invalid Email or Password",
      );
    }

    return LoginResult(success: true, user: user);
  }
}

class LoginResult {
  final bool success;
  final User? user;
  final String? errorMessage;

  LoginResult({required this.success, this.user, this.errorMessage});
}
