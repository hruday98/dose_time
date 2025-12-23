import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './django_api_service.dart';

class AuthService {
  final DjangoApiService apiService;
  final Logger logger;
  final SharedPreferences prefs;

  AuthService({
    required this.apiService,
    required this.logger,
    required this.prefs,
  });

  static const String _accessTokenKey = 'django_access_token';
  static const String _refreshTokenKey = 'django_refresh_token';
  static const String _userIdKey = 'django_user_id';
  static const String _userEmailKey = 'django_user_email';
  static const String _userRoleKey = 'django_user_role';

  // ==================== AUTHENTICATION ====================

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    try {
      final response = await apiService.registerUser(
        username: username,
        email: email,
        password: password,
        role: role,
        phoneNumber: phoneNumber,
      );
      logger.i('User registered: $username');
      return response;
    } catch (e) {
      logger.e('Registration failed: $e');
      rethrow;
    }
  }

  /// Login user with email and password
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await apiService.loginUser(
        username: username,
        password: password,
      );

      final accessToken = response['access'] as String?;
      final refreshToken = response['refresh'] as String?;

      if (accessToken != null && refreshToken != null) {
        // Store tokens
        await prefs.setString(_accessTokenKey, accessToken);
        await prefs.setString(_refreshTokenKey, refreshToken);

        // Fetch and store user data
        final user = await apiService.getCurrentUser();
        await _storeUserData(user);

        logger.i('User logged in: $username');
        return true;
      }
      return false;
    } catch (e) {
      logger.e('Login failed: $e');
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userRoleKey);
      logger.i('User logged out');
    } catch (e) {
      logger.e('Logout failed: $e');
      rethrow;
    }
  }

  /// Refresh access token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = getRefreshToken();
      if (refreshToken == null) return false;

      final response = await apiService.refreshToken(refreshToken: refreshToken);
      final newAccessToken = response['access'] as String?;

      if (newAccessToken != null) {
        await prefs.setString(_accessTokenKey, newAccessToken);
        logger.i('Access token refreshed');
        return true;
      }
      return false;
    } catch (e) {
      logger.e('Token refresh failed: $e');
      return false;
    }
  }

  // ==================== TOKEN MANAGEMENT ====================

  /// Get stored access token
  String? getAccessToken() {
    return prefs.getString(_accessTokenKey);
  }

  /// Get stored refresh token
  String? getRefreshToken() {
    return prefs.getString(_refreshTokenKey);
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return getAccessToken() != null;
  }

  // ==================== USER DATA ====================

  /// Get current user ID
  String? getCurrentUserId() {
    return prefs.getString(_userIdKey);
  }

  /// Get current user email
  String? getCurrentUserEmail() {
    return prefs.getString(_userEmailKey);
  }

  /// Get current user role
  String? getCurrentUserRole() {
    return prefs.getString(_userRoleKey);
  }

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = await apiService.getCurrentUser();
      await _storeUserData(user);
      return user;
    } catch (e) {
      logger.e('Failed to get current user: $e');
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? email,
    String? phoneNumber,
    String? profileImage,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      final response = await apiService.updateUserProfile(
        userId: userId,
        email: email,
        phoneNumber: phoneNumber,
        profileImage: profileImage,
      );

      await _storeUserData(response);
      logger.i('User profile updated');
      return true;
    } catch (e) {
      logger.e('Profile update failed: $e');
      return false;
    }
  }

  // ==================== PRIVATE HELPERS ====================

  /// Store user data locally
  Future<void> _storeUserData(Map<String, dynamic> user) async {
    await prefs.setString(_userIdKey, user['id'].toString());
    if (user['email'] != null) {
      await prefs.setString(_userEmailKey, user['email']);
    }
    if (user['role'] != null) {
      await prefs.setString(_userRoleKey, user['role']);
    }
  }
}

/// Provider for SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) async => SharedPreferences.getInstance(),
);

/// Provider for AuthService
final authServiceProvider = FutureProvider<AuthService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final apiService = ref.watch(djangoApiServiceProvider);
  final logger = ref.watch(loggerProvider);

  return AuthService(
    apiService: apiService,
    logger: logger,
    prefs: prefs,
  );
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final authService = await ref.watch(authServiceProvider.future);
  return authService.isAuthenticated();
});

/// Provider for current user data
final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = await ref.watch(authServiceProvider.future);
  return authService.getCurrentUserData();
});

