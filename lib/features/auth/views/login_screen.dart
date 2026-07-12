import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/auth/data/auth_bloc.dart';
import 'package:offline_pos/features/auth/repositories/auth_service.dart';

class TestLogin extends StatefulWidget {
  final AppDatabase db;
  const TestLogin({super.key, required this.db});

  @override
  State<TestLogin> createState() => _TestLoginState();
}

class _TestLoginState extends State<TestLogin> {
  late AuthService _authService;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _authService = AuthService(widget.db);
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  void _showResultSnackBar(
    ScaffoldMessengerState messenger,
    String message,
    bool isSuccess,
  ) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login Screen")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Login", style: TextStyle(fontSize: 20)),
                const SizedBox(height: 10),
                TextField(
                  controller: _loginEmailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _loginPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final authBloc = context.read<AuthBloc>();
                    final result = await _authService.login(
                      _loginEmailController.text,
                      _loginPasswordController.text,
                    );

                    if (!mounted) return;

                    if (result.success && result.user != null) {
                      _showResultSnackBar(
                        messenger,
                        "Login Success! Welcome ${result.user!.name} (${result.user!.role})",
                        true,
                      );
                      authBloc.add(LoggedIn(result.user!));
                    } else {
                      _showResultSnackBar(
                        messenger,
                        result.errorMessage!,
                        false,
                      );
                    }
                  },
                  child: const Text("Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
