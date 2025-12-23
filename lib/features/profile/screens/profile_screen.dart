import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elderly_button.dart';
import '../../../core/widgets/elderly_text_field.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/error_widget.dart' as custom;
import '../../../core/utils/dialogs.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/user_profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late TextEditingController _displayNameController;
  late TextEditingController _phoneController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = ref.watch(userModelProvider).value;
    final profileState = ref.watch(userProfileProvider);

    // Update controllers when user data changes
    if (user != null && !_isEditing) {
      _displayNameController.text = user.displayName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: AppTextStyles.headlineLarge,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: Text(
                'Edit',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _cancelEditing,
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: profileState.isLoading,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: user != null
              ? _buildProfileContent(user)
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildProfileContent(user) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(user),
          const SizedBox(height: AppSizes.spacingXLarge),
          _buildProfileForm(user),
          const SizedBox(height: AppSizes.spacingXLarge),
          _buildAccountSection(),
          const SizedBox(height: AppSizes.spacingXLarge),
          _buildSettingsSection(),
          const SizedBox(height: AppSizes.spacingXLarge),
          if (_isEditing) _buildEditActions(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(
                      user.displayName?.isNotEmpty == true
                          ? user.displayName![0].toUpperCase()
                          : user.email[0].toUpperCase(),
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSizes.spacingLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'No name set',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingSmall),
                  Text(
                    user.email,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMedium,
                      vertical: AppSizes.paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    ),
                    child: Text(
                      user.role.displayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm(user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            
            // Display Name
            ElderlyTextField(
              label: 'Full Name',
              controller: _displayNameController,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            
            // Email (read-only)
            ElderlyTextField(
              label: 'Email',
              initialValue: user.email,
              enabled: false,
              suffixIcon: const Icon(Icons.lock_outline),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            
            // Phone Number
            ElderlyTextField(
              label: 'Phone Number (Optional)',
              controller: _phoneController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            
            // Account Created
            ElderlyTextField(
              label: 'Member Since',
              initialValue: _formatDate(user.createdAt),
              enabled: false,
              suffixIcon: const Icon(Icons.calendar_today),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            
            ListTile(
              leading: const Icon(Icons.lock_reset, size: AppSizes.iconLarge),
              title: Text(
                'Change Password',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                'Update your account password',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withOpacity(0.7),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changePassword,
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.logout, size: AppSizes.iconLarge, color: AppColors.error),
              title: Text(
                'Sign Out',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
              subtitle: Text(
                'Sign out of your account',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withOpacity(0.7),
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.error),
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            
            ListTile(
              leading: const Icon(Icons.notifications, size: AppSizes.iconLarge),
              title: Text(
                'Notifications',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                'Manage notification preferences',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withOpacity(0.7),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/notifications'),
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.palette, size: AppSizes.iconLarge),
              title: Text(
                'Appearance',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                'Theme and display settings',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withOpacity(0.7),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/appearance'),
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.help_outline, size: AppSizes.iconLarge),
              title: Text(
                'Help & Support',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                'Get help and contact support',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withOpacity(0.7),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/help'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: ElderlyButton(
            label: 'Cancel',
            onPressed: _cancelEditing,
            variant: ElderlyButtonVariant.secondary,
          ),
        ),
        const SizedBox(width: AppSizes.spacingMedium),
        Expanded(
          child: ElderlyButton(
            label: 'Save Changes',
            icon: Icons.save,
            onPressed: _saveProfile,
            variant: ElderlyButtonVariant.primary,
          ),
        ),
      ],
    );
  }

  // Helper methods
  void _cancelEditing() {
    final user = ref.read(userModelProvider).value;
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
    setState(() => _isEditing = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(userProfileProvider.notifier).updateProfile(
        displayName: _displayNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );

      setState(() => _isEditing = false);
      
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          'Profile updated successfully!',
          type: SnackBarType.success,
        );
      }
    } catch (error) {
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          'Failed to update profile: $error',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final result = await AppDialogs.showChangePasswordDialog(context);
    if (result == true && mounted) {
      AppDialogs.showSnackBar(
        context,
        'Password change email sent!',
        type: SnackBarType.success,
      );
    }
  }

  Future<void> _signOut() async {
    final confirmed = await AppDialogs.showConfirmationDialog(
      context,
      title: 'Sign Out',
      content: 'Are you sure you want to sign out of your account?',
      confirmText: 'Sign Out',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await ref.read(authStateProvider.notifier).signOut();
        if (mounted) {
          context.go('/auth/login');
        }
      } catch (error) {
        if (mounted) {
          AppDialogs.showSnackBar(
            context,
            'Failed to sign out: $error',
            type: SnackBarType.error,
          );
        }
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
