import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../../../core/utils/utils.dart';
import '../../../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      switch (next) {
        case AuthStateInitial():
          break;
        case AuthStateAuthenticated():
          context.go(AppConstants.dashboardRoute);
        case AuthStateError(:final message):
          DialogUtils.showErrorSnackBar(context, message);
        case AuthStatePasswordResetSent():
          DialogUtils.showSuccessSnackBar(
            context, 
            'Password reset email sent. Please check your inbox.',
          );
          ref.read(authStateProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: authState is AuthStateLoading,
          message: 'Signing you in...',
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  
                  // App Logo and Title
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      Text(
                        'Your medication companion',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Login Form
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      // Email Field
                      LargeTextField(
                        label: 'Email',
                        hint: 'Enter your email address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: ValidationUtils.validateEmail,
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      // Password Field
                      LargeTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outlined,
                        suffixIcon: _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        onSuffixIconPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        validator: ValidationUtils.validatePassword,
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      
                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordDialog(),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      // Sign In Button
                      LargeButton(
                        text: 'Sign In',
                        onPressed: _signInWithEmail,
                        isLoading: authState is AuthStateLoading,
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      // OR Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                            child: Text(
                              'OR',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      // Social Sign In Buttons
                      LargeButton(
                        text: 'Continue with Google',
                        onPressed: _signInWithGoogle,
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
                        icon: Icons.login,
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                        LargeButton(
                          text: 'Continue with Apple',
                          onPressed: _signInWithApple,
                          backgroundColor: Colors.black,
                          textColor: Colors.white,
                          icon: Icons.apple,
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                      ],
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      TextButton(
                        onPressed: () => context.push(AppConstants.registerRoute),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: AppConstants.largeFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _signInWithEmail() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authStateProvider.notifier).signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  void _signInWithGoogle() {
    ref.read(authStateProvider.notifier).signInWithGoogle();
  }

  void _signInWithApple() {
    ref.read(authStateProvider.notifier).signInWithApple();
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Form(
          key: formKey,
          child: LargeTextField(
            label: 'Email',
            hint: 'Enter your email address',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: ValidationUtils.validateEmail,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                ref.read(authStateProvider.notifier).sendPasswordResetEmail(
                  emailController.text.trim(),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
