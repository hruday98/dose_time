import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:logger/logger.dart';
import '../core/models/user_model.dart';
import '../core/constants/app_constants.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email & Password Authentication
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phoneNumber,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(displayName);

        // Create user document in Firestore
        final userModel = UserModel(
          id: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          role: role,
          phoneNumber: phoneNumber,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestoreService.createUser(userModel);
        _logger.i('User created successfully: ${userCredential.user!.uid}');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.e('Sign up error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Unexpected sign up error: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _logger.i('User signed in successfully: ${userCredential.user!.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.e('Sign in error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Unexpected sign in error: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Check if this is a new user and create profile if needed
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        final userModel = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
          displayName: userCredential.user!.displayName ?? 'User',
          role: UserRole.patient, // Default role, user can change later
          profileImageUrl: userCredential.user!.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestoreService.createUser(userModel);
      }

      _logger.i('Google sign in successful: ${userCredential.user!.uid}');
      return userCredential;
    } catch (e) {
      _logger.e('Google sign in error: $e');
      throw 'Failed to sign in with Google. Please try again.';
    }
  }

  // Apple Sign In
  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      
      // Check if this is a new user and create profile if needed
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        final displayName = appleCredential.givenName != null && appleCredential.familyName != null
            ? '${appleCredential.givenName} ${appleCredential.familyName}'
            : 'User';
            
        final userModel = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? appleCredential.email ?? '',
          displayName: displayName,
          role: UserRole.patient, // Default role, user can change later
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestoreService.createUser(userModel);
      }

      _logger.i('Apple sign in successful: ${userCredential.user!.uid}');
      return userCredential;
    } catch (e) {
      _logger.e('Apple sign in error: $e');
      throw 'Failed to sign in with Apple. Please try again.';
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      _logger.e('Password reset error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Unexpected password reset error: $e');
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Sign out error: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestoreService.deleteUser(user.uid);
        
        // Delete Firebase Auth account
        await user.delete();
        _logger.i('Account deleted successfully');
      }
    } on FirebaseAuthException catch (e) {
      _logger.e('Delete account error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Unexpected delete account error: $e');
      throw 'Failed to delete account. Please try again.';
    }
  }

  // Helper method to handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please try again later.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
