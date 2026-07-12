import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/features/auth/data/auth_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final authBloc = context.read<AuthBloc>();
            authBloc.add(LoggedOut());
          },
          child: Text("Log Out"),
        ),
      ),
    );
  }
}
