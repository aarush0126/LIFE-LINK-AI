import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../shared/models/user_model.dart';
import '../application/auth_controller.dart';
import 'auth_page_shell.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authControllerProvider)
          .registerDemo(
            fullName: _nameController.text,
            email: _emailController.text,
          );
      if (mounted) context.go(RouteNames.emailVerification);
    } on AuthFlowException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      icon: Icons.person_add_alt_1_rounded,
      title: 'Create a demo account',
      subtitle: 'Start a fictional account for exploring the platform.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthFeedbackMessage(
            message: 'Demo registration is local only. Passwords are checked in this form, then discarded—not stored or sent.',
            isSuccess: true,
          ),
          const SizedBox(height: 18),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: 'Full name',
                  hint: 'Your name',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  validator: (value) =>
                      Validators.requiredField(value, 'Enter your name'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email address',
                  hint: 'name@hospital.example',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Create password',
                  hint: 'At least 8 characters',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            AuthFeedbackMessage(message: _errorMessage!),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: 'Create demo account',
            icon: Icons.arrow_forward_rounded,
            isFullWidth: true,
            size: AppButtonSize.large,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _register,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => context.go(RouteNames.login),
              child: const Text('Already have access? Sign in'),
            ),
          ),
        ],
      ),
    );
  }
}

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isLoading = false;
  String? _feedback;
  bool _isSuccess = false;

  Future<void> _verify() async {
    setState(() {
      _isLoading = true;
      _feedback = null;
    });
    try {
      await ref.read(authControllerProvider).verifyEmailDemo();
      if (mounted) context.go(RouteNames.profileSetup);
    } on AuthFlowException catch (error) {
      if (mounted) {
        setState(() {
          _feedback = error.message;
          _isSuccess = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isLoading = true;
      _feedback = null;
    });
    try {
      await ref.read(authControllerProvider).resendVerificationDemo();
      if (mounted) {
        setState(() {
          _feedback = 'Demo verification is simulated; no email was sent. A production backend must deliver and validate a one-time link or code.';
          _isSuccess = true;
        });
      }
    } on AuthFlowException catch (error) {
      if (mounted) {
        setState(() {
          _feedback = error.message;
          _isSuccess = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingUser = ref.watch(authControllerProvider).pendingRegistration;
    if (pendingUser == null) {
      return AuthPageShell(
        icon: Icons.mark_email_read_outlined,
        title: 'Email verification',
        subtitle: 'There is no pending demo registration.',
        child: AppButton(
          label: 'Back to registration',
          onPressed: () => context.go(RouteNames.register),
          isFullWidth: true,
        ),
      );
    }

    return AuthPageShell(
      icon: Icons.mark_email_read_outlined,
      title: 'Verify your email',
      subtitle: 'Confirm the demo address associated with this registration.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFeedbackMessage(
            message: 'Demo address: ${pendingUser.email}',
            isSuccess: true,
          ),
          const SizedBox(height: 16),
          const Text(
            'No verification email is sent in demo mode. Continue to simulate verification. Production verification must be completed by the authentication backend.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 16),
            AuthFeedbackMessage(message: _feedback!, isSuccess: _isSuccess),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: 'Verify demo email',
            icon: Icons.verified_user_outlined,
            isFullWidth: true,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _verify,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading ? null : _resend,
            child: const Text('Resend verification instructions'),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _successMessage = null;
      _errorMessage = null;
    });
    try {
      await ref
          .read(authControllerProvider)
          .requestPasswordResetDemo(_emailController.text);
      if (mounted) {
        setState(
          () => _successMessage = 'If an account exists for this address, reset instructions would be sent. Demo mode does not send email or reveal account status.',
        );
      }
    } on AuthFlowException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      icon: Icons.lock_reset_rounded,
      title: 'Reset your password',
      subtitle: 'Enter the email address associated with your account.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Form(
            key: _formKey,
            child: AppTextField(
              label: 'Email address',
              hint: 'name@hospital.example',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
          ),
          if (_successMessage != null) ...[
            const SizedBox(height: 16),
            AuthFeedbackMessage(message: _successMessage!, isSuccess: true),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            AuthFeedbackMessage(message: _errorMessage!),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: 'Request reset instructions',
            icon: Icons.outgoing_mail,
            isFullWidth: true,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _requestReset,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go(RouteNames.login),
            child: const Text('Return to sign in'),
          ),
        ],
      ),
    );
  }
}

class UserProfileSetupScreen extends ConsumerStatefulWidget {
  const UserProfileSetupScreen({super.key});

  @override
  ConsumerState<UserProfileSetupScreen> createState() =>
      _UserProfileSetupScreenState();
}

class _UserProfileSetupScreenState
    extends ConsumerState<UserProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hospitalController = TextEditingController();
  final _departmentController = TextEditingController();
  final _hprController = TextEditingController();
  UserRole? _selectedRole = UserRole.hospitalAdministrator;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _hospitalController.dispose();
    _departmentController.dispose();
    _hprController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final role = _selectedRole;
    if (role == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(authControllerProvider)
          .completeDemoProfile(
            role: role,
            hospitalName: _hospitalController.text,
            department: _departmentController.text,
            hprId: _hprController.text,
          );
      if (mounted) context.go(RouteNames.dashboard);
    } on AuthFlowException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).currentUser;
    if (user == null) {
      return AuthPageShell(
        icon: Icons.badge_outlined,
        title: 'Complete your profile',
        subtitle: 'Sign in or verify your demo email to continue.',
        child: AppButton(
          label: 'Return to sign in',
          onPressed: () => context.go(RouteNames.login),
          isFullWidth: true,
        ),
      );
    }

    return AuthPageShell(
      icon: Icons.badge_outlined,
      title: 'Set up your profile',
      subtitle: 'Add your demo role and institutional profile details.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFeedbackMessage(
            message: 'Signed in as ${user.email}',
            isSuccess: true,
          ),
          const SizedBox(height: 18),
          Form(
            key: _formKey,
            child: Column(
              children: [
                RolePickerField(
                  value: _selectedRole,
                  onChanged: (role) => setState(() => _selectedRole = role),
                  allowedRoles: UserRole.values
                      .where(
                        (role) =>
                            role != UserRole.networkAdministrator &&
                            role != UserRole.auditorComplianceOfficer,
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Hospital or institution',
                  hint: 'Institution name',
                  controller: _hospitalController,
                  prefixIcon: Icons.local_hospital_outlined,
                  validator: (value) =>
                      Validators.requiredField(value, 'Enter an institution'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Department',
                  hint: 'Department or service',
                  controller: _departmentController,
                  prefixIcon: Icons.business_outlined,
                  validator: (value) =>
                      Validators.requiredField(value, 'Enter a department'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'HPR identifier',
                  hint: 'Demo HPR ID',
                  controller: _hprController,
                  prefixIcon: Icons.badge_outlined,
                  validator: Validators.hprId,
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            AuthFeedbackMessage(message: _errorMessage!),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: 'Save demo profile',
            icon: Icons.check_rounded,
            isFullWidth: true,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _completeSetup,
          ),
        ],
      ),
    );
  }
}
