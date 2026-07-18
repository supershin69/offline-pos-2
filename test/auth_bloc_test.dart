import 'package:flutter_test/flutter_test.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/auth/data/auth_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthBloc', () {
    test('starts unauthenticated', () {
      final bloc = AuthBloc();
      expect(bloc.state, isA<Unauthenticated>());
      bloc.close();
    });

    test('transitions to authenticated when logged in', () async {
      final bloc = AuthBloc();
      final user = User(
        id: 'u1',
        name: 'Test User',
        email: 'test@example.com',
        password: '123456',
        role: 'admin',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bloc.add(LoggedIn(user));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(bloc.state, isA<Authenticated>());
      bloc.close();
    });

    test('logs out to unauthenticated state', () async {
      final bloc = AuthBloc();
      final user = User(
        id: 'u1',
        name: 'Test User',
        email: 'test@example.com',
        password: '123456',
        role: 'admin',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bloc.add(LoggedIn(user));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(LoggedOut());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(bloc.state, isA<Unauthenticated>());
      bloc.close();
    });
  });
}
