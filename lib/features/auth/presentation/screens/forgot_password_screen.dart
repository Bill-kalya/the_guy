import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/auth_button.dart';
import '../../providers/auth_provider.dart';
import '../../models/auth_state.dart';
import '../../../../core/utils/validators.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen for OTP sent state → navigate to verify-reset-otp
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.resetOtpSent && previous?.resetOtpSent == false) {
        context.push('/verify-reset-otp', extra: next.resetEmail);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildEmailField(),
                      const SizedBox(height: 24),
                      _buildSendCodeButton(authState),
                      if (authState.error != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorBanner(authState.error!),
                      ],
                      const SizedBox(height: 16),
                      _buildBackToLogin(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            shape: BoxShape.circle,
          ),
          child:
              Icon(Icons.lock_reset, size: 40, color: Colors.orange.shade700),
        ),
        const SizedBox(height: 16),
        const Text(
          'Reset Password',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your email address and we\'ll send you a 6-digit code to reset your password.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'john@example.com',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      validator: (value) => Validators.validateEmail(value),
    );
  }

  Widget _buildSendCodeButton(AuthState authState) {
    return AuthButton(
      text: 'Send Reset Code',
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          ref
              .read(authProvider.notifier)
              .forgotPassword(_emailController.text.trim());
        }
      },
      isLoading: authState.isLoading,
    );
  }

  Widget _buildBackToLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Remember your password? '),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Login'),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}