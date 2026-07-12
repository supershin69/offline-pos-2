// Events
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';

abstract class AuthEvent {}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final User user;
  LoggedIn(this.user);
}

class LoggedOut extends AuthEvent {}

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>((event, emit) => emit(Unauthenticated()));
    on<LoggedIn>((event, emit) => emit(Authenticated(event.user)));
    on<LoggedOut>((event, emit) => emit(Unauthenticated()));
  }
}
