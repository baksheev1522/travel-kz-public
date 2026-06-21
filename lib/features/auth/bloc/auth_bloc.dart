import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/entities.dart';

// ─── Events ───────────────────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckStatusEvent extends AuthEvent {}

class AuthSignInEvent extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInEvent({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String phone;
  const AuthSignUpEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
  });
  @override
  List<Object?> get props => [name, email, password, phone];
}

class AuthSignOutEvent extends AuthEvent {}

// ─── States ───────────────────────────────────────────────────────
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}
class AuthLoadingState extends AuthState {}

class AuthAuthenticatedState extends AuthState {
  final AppUser user;
  const AuthAuthenticatedState(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticatedState extends AuthState {}

class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ─────────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthBloc() : super(AuthInitialState()) {
    on<AuthCheckStatusEvent>(_onCheck);
    on<AuthSignInEvent>(_onSignIn);
    on<AuthSignUpEvent>(_onSignUp);
    on<AuthSignOutEvent>(_onSignOut);
  }

  Future<void> _onCheck(
    AuthCheckStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    await Future.delayed(const Duration(seconds: 1));
    final user = _auth.currentUser;
    if (user == null) {
      emit(AuthUnauthenticatedState());
      return;
    }
    try {
      final appUser = await _getUser(user.uid);
      emit(AuthAuthenticatedState(appUser));
    } catch (_) {
      emit(AuthUnauthenticatedState());
    }
  }

  Future<void> _onSignIn(
    AuthSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );
      final appUser = await _getUser(cred.user!.uid);
      emit(AuthAuthenticatedState(appUser));
    } on FirebaseAuthException catch (e) {
      emit(AuthErrorState(_mapError(e.code)));
    } catch (_) {
      emit(const AuthErrorState('Ошибка входа'));
    }
  }

  Future<void> _onSignUp(
    AuthSignUpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );
      final uid = cred.user!.uid;
      final user = AppUser(
        id: uid,
        name: event.name,
        email: event.email,
        phone: event.phone,
        avatarUrl: '',
        bonusPoints: 10000,
        wishlistIds: const [],
      );
      await _db.collection('users').doc(uid).set({
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'avatarUrl': '',
        'bonusPoints': 10000,
        'wishlistIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      emit(AuthAuthenticatedState(user));
    } on FirebaseAuthException catch (e) {
      emit(AuthErrorState(_mapError(e.code)));
    } catch (_) {
      emit(const AuthErrorState('Ошибка регистрации'));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _auth.signOut();
    emit(AuthUnauthenticatedState());
  }

  Future<AppUser> _getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User not found');
    final data = doc.data()!;
    return AppUser(
      id: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      bonusPoints: data['bonusPoints'] ?? 0,
      wishlistIds: List<String>.from(data['wishlistIds'] ?? []),
    );
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'weak-password':
        return 'Слабый пароль — минимум 6 символов';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'invalid-credential':
        return 'Неверный email или пароль';
      case 'network-request-failed':
        return 'Нет подключения к интернету';
      default:
        return 'Ошибка авторизации';
    }
  }
}