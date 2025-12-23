import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../../../core/utils/utils.dart';
import '../../../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole? _selectedRole;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
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
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: authState is AuthStateLoading,
          message: 'Creating your account...',
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Message
                  Text(
                    'Join DoseTime',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    'Create your account to start managing your medications',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.paddingXLarge),
                  
                  // Name Field
                  LargeTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    prefixIcon: Icons.person_outlined,
                    validator: (value) => ValidationUtils.validateRequired(value, 'Full name'),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  
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
                  
                  // Phone Field (Optional)
                  LargeTextField(
                    label: 'Phone Number (Optional)',
                    hint: 'Enter your phone number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  // Password Field
                  LargeTextField(
                    label: 'Password',
                    hint: 'Create a password (min 6 characters)',
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
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  // Confirm Password Field
                  LargeTextField(
                    label: 'Confirm Password',
                    hint: 'Confirm your password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    onSuffixIconPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    validator: (value) => ValidationUtils.validateConfirmPassword(
                      value, 
                      _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Role Selection
                  RoleSelector(
                    selectedRole: _selectedRole,
                    onRoleChanged: (role) {
                      setState(() {
                        _selectedRole = role;
                      });
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Role Descriptions
                  if (_selectedRole != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getRoleIcon(_selectedRole!),
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: AppConstants.paddingSmall),
                              Text(
                                'As a ${_selectedRole!.displayName}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.paddingSmall),
                          Text(
                            _getRoleDescription(_selectedRole!),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                  ],
                  
                  // Create Account Button
                  LargeButton(
                    text: 'Create Account',
                    onPressed: _selectedRole != null ? _createAccount : null,
                    isLoading: authState is AuthStateLoading,
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text(
                          'Sign In',
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

  void _createAccount() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedRole == null) {
        DialogUtils.showErrorSnackBar(context, 'Please select your role');
        return;
      }

      ref.read(authStateProvider.notifier).signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        role: _selectedRole!,
        phoneNumber: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
      );
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return Icons.person;
      case UserRole.doctor:
        return Icons.medical_services;
      case UserRole.caretaker:
        return Icons.favorite;
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return 'You can manage your own medications, set reminders, and track your medication history. You can also connect with doctors and caretakers.';
      case UserRole.doctor:
        return 'You can prescribe medications to patients, monitor their adherence, and manage multiple patient profiles.';
      case UserRole.caretaker:
        return 'You can help manage medications for family members or those under your care, ensuring they take their medications on time.';
    }
  }
}

