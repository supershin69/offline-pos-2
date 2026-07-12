import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:offline_pos/core/database/database.dart';

class UserService {
  final AppDatabase _db;

  UserService(this._db);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<RegisterResult> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (name.trim().length < 2 || name.trim().length > 100) {
      return RegisterResult(
        success: false,
        errorMessage: "Name must be between 2 to 100 characters long",
      );
    }

    if (password.length < 6) {
      return RegisterResult(
        success: false,
        errorMessage: "Password must be at least 6 characters long",
      );
    }

    if (!email.contains('@')) {
      return RegisterResult(
        success: false,
        errorMessage: "Invalid Email format",
      );
    }

    try {
      final existingUser = await _db.getUserByEmail(email);

      if (existingUser != null) {
        return RegisterResult(
          success: false,
          errorMessage: "Email already in use",
        );
      }

      final hashedPassword = _hashPassword(password);

      await _db
          .into(_db.users)
          .insert(
            UsersCompanion.insert(
              name: name.trim(),
              email: email.trim().toLowerCase(),
              password: hashedPassword,
              role: role,
            ),
          );

      return RegisterResult(success: true);
    } catch (e) {
      return RegisterResult(
        success: false,
        errorMessage: "Unexpected Error Occured: $e",
      );
    }
  }
}

class RegisterResult {
  final bool success;
  final String? errorMessage;

  RegisterResult({required this.success, this.errorMessage});
}
