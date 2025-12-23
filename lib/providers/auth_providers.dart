import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/user_model.dart';
import '../core/constants/app_constants.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Firestore Service Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// Current Firebase User Provider
final currentFirebaseUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current User Model Provider
final currentUserProvider = StreamProvider<UserModel?>((ref) async* {
  final firebaseUser = await ref.watch(currentFirebaseUserProvider.future);
  
  if (firebaseUser == null) {
    yield null;
    return;
  }
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  yield* firestoreService.getUserStream(firebaseUser.uid);
});

// Authentication State Provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref);
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthStateNotifier(this._ref) : super(const AuthState.initial());

  AuthService get _authService => _ref.read(authServiceProvider);

  // Sign Up with Email and Password
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phoneNumber,
  }) async {
    state = const AuthState.loading();
    
    try {
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        phoneNumber: phoneNumber,
      );
      state = const AuthState.authenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // Sign In with Email and Password
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AuthState.authenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // Sign In with Google
  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        state = const AuthState.authenticated();
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // Sign In with Apple
  Future<void> signInWithApple() async {
    state = const AuthState.loading();
    
    try {
      await _authService.signInWithApple();
      state = const AuthState.authenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AuthState.loading();
    
    try {
      await _authService.sendPasswordResetEmail(email);
      state = const AuthState.passwordResetSent();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // Sign Out
  Future<void> signOut() async {
    state = const AuthState.loading();
    
    try {
      await _authService.signOut();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    state = const AuthState.loading();
    
    try {
      await _authService.deleteAccount();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // Clear Error State
  void clearError() {
    if (state is AuthStateError) {
      state = const AuthState.unauthenticated();
    }
  }
}

// Auth State Classes
sealed class AuthState {
  const AuthState();

  const factory AuthState.initial() = AuthStateInitial;
  const factory AuthState.loading() = AuthStateLoading;
  const factory AuthState.authenticated() = AuthStateAuthenticated;
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;
  const factory AuthState.error(String message) = AuthStateError;
  const factory AuthState.passwordResetSent() = AuthStatePasswordResetSent;
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated();
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateError extends AuthState {
  final String message;
  
  const AuthStateError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthStateError && other.message == message);

  @override
  int get hashCode => message.hashCode;
}

class AuthStatePasswordResetSent extends AuthState {
  const AuthStatePasswordResetSent();
}

// User Profile Provider (for updating user data)
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  return UserProfileNotifier(ref);
});

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final Ref _ref;

  UserProfileNotifier(this._ref) : super(const UserProfileState.initial());

  FirestoreService get _firestoreService => _ref.read(firestoreServiceProvider);

  // Update User Profile
  Future<void> updateProfile(UserModel user) async {
    state = const UserProfileState.loading();
    
    try {
      await _firestoreService.updateUser(user);
      state = const UserProfileState.success();
    } catch (e) {
      state = UserProfileState.error(e.toString());
    }
  }

  void clearState() {
    state = const UserProfileState.initial();
  }
}

// User Profile State Classes
sealed class UserProfileState {
  const UserProfileState();

  const factory UserProfileState.initial() = UserProfileStateInitial;
  const factory UserProfileState.loading() = UserProfileStateLoading;
  const factory UserProfileState.success() = UserProfileStateSuccess;
  const factory UserProfileState.error(String message) = UserProfileStateError;
}

class UserProfileStateInitial extends UserProfileState {
  const UserProfileStateInitial();
}

class UserProfileStateLoading extends UserProfileState {
  const UserProfileStateLoading();
}

class UserProfileStateSuccess extends UserProfileState {
  const UserProfileStateSuccess();
}

class UserProfileStateError extends UserProfileState {
  final String message;
  
  const UserProfileStateError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileStateError && other.message == message);

  @override
  int get hashCode => message.hashCode;
}
