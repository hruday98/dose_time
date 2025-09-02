import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'providers/auth_providers.dart';
import 'services/local_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize local database service
  await LocalDatabaseService().initialize();
  
  // Initialize timezone data
  tz.initializeTimeZones();
  
  runApp(const ProviderScope(child: DoseTimeApp()));
}

class DoseTimeApp extends ConsumerWidget {
  const DoseTimeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _createRouter(ref);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  GoRouter _createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: AppConstants.loginRoute,
      redirect: (context, state) {
        final user = ref.watch(currentFirebaseUserProvider).value;
        final isLoggedIn = user != null;
        final isAuthRoute = state.matchedLocation == AppConstants.loginRoute ||
                           state.matchedLocation == AppConstants.registerRoute;

        if (!isLoggedIn && !isAuthRoute) {
          return AppConstants.loginRoute;
        }
        
        if (isLoggedIn && isAuthRoute) {
          return AppConstants.dashboardRoute;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppConstants.loginRoute,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppConstants.registerRoute,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppConstants.dashboardRoute,
          builder: (context, state) => const DashboardPlaceholder(),
        ),
        // Add other routes here as we implement them
      ],
    );
  }
}

// Temporary placeholder for dashboard
class DashboardPlaceholder extends ConsumerWidget {
  const DashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('DoseTime Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.medication,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to DoseTime!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            user.when(
              data: (userData) => userData != null
                  ? Text(
                      'Hello, ${userData.displayName}!',
                      style: Theme.of(context).textTheme.bodyLarge,
                    )
                  : const Text('Loading user data...'),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dashboard coming soon...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
