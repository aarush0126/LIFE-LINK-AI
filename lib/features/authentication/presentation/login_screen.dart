import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../shared/models/user_model.dart';
import '../application/auth_controller.dart';
import '../data/auth_api_service.dart';
import 'auth_page_shell.dart';

enum _LoginMode { demo, production }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _LoginMode _mode = _LoginMode.demo;
  UserRole? _selectedRole = UserRole.hospitalAdministrator;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInDemo() async {
    final role = _selectedRole;
    if (role == null) {
      setState(() => _errorMessage = 'Select a demo account role.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authControllerProvider).signInDemo(role);
      if (mounted) context.go(RouteNames.dashboard);
    } on AuthFlowException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInProduction() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await ref
          .read(authApiServiceProvider)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      ref.read(authControllerProvider).setAuthenticatedUser(session.user);
      if (mounted) context.go(RouteNames.dashboard);
    } on DioException catch (error) {
      if (mounted) {
        final apiError = error.error;
        setState(() {
          _errorMessage = apiError is ApiException
              ? apiError.message
              : 'Unable to sign in to the configured API.';
        });
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      _passwordController.clear();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      icon: Icons.health_and_safety_rounded,
      title: 'Welcome back',
      subtitle: 'Sign in to the LIFE-LINK AI healthcare coordination platform.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<_LoginMode>(
            segments: const [
              ButtonSegment(
                value: _LoginMode.demo,
                icon: Icon(Icons.science_outlined),
                label: Text('Demo access'),
              ),
              ButtonSegment(
                value: _LoginMode.production,
                icon: Icon(Icons.lock_outline),
                label: Text('Production'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() {
                _mode = selection.first;
                _errorMessage = null;
              });
            },
          ),
          const SizedBox(height: 20),
          if (_mode == _LoginMode.demo) ...[
            const AuthFeedbackMessage(
              message: 'Demo accounts are fictional and use no password. Demo sign-in is separate from production authentication.',
              isSuccess: true,
            ),
            const SizedBox(height: 18),
            RolePickerField(
              value: _selectedRole,
              onChanged: (role) => setState(() => _selectedRole = role),
              label: 'Choose a fictional demo role',
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null) ...[
              AuthFeedbackMessage(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            AppButton(
              label: 'Continue with Demo Account',
              icon: Icons.login_rounded,
              isFullWidth: true,
              size: AppButtonSize.large,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _signInDemo,
            ),
          ] else ...[
            const AuthFeedbackMessage(
              message: 'Production sign-in sends credentials only to the API URL configured for this environment. Demo accounts never use the production API.',
            ),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    label: 'Institutional email',
                    hint: 'name@hospital.example',
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: Validators.password,
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go(RouteNames.forgotPassword),
                child: const Text('Forgot password?'),
              ),
            ),
            if (_errorMessage != null) ...[
              AuthFeedbackMessage(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            AppButton(
              label: 'Sign in',
              icon: Icons.login_rounded,
              isFullWidth: true,
              size: AppButtonSize.large,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _signInProduction,
            ),
          ],
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'New to the demo?',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              TextButton(
                onPressed: () => context.go(RouteNames.register),
                child: const Text('Create an account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
