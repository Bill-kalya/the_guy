import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/auth_button.dart';
import '../../providers/auth_provider.dart';
import '../../models/auth_state.dart';
import '../../../../core/utils/validators.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen for password reset completion → navigate to login
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.isLoading &&
          previous?.isLoading == true &&
          next.error == null &&
          !next.isAuthenticated &&
          previous?.isAuthenticated == false) {
        // Password reset completed successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully. Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
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
                      _buildNewPasswordField(),
                      const SizedBox(height: 16),
                      _buildConfirmPasswordField(),
                      const SizedBox(height: 24),
                      _buildResetButton(authState),
                      if (authState.error != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorBanner(authState.error!),
                      ],
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
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child:
              Icon(Icons.lock_outline, size: 40, color: Colors.green.shade700),
        ),
        const SizedBox(height: 16),
        const Text(
          'Create New Password',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your code has been verified. Enter a new password for your account.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNewPasswordField() {
    return TextFormField(
      controller: _newPasswordController,
      obscureText: _obscureNew,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'New Password',
        hintText: 'At least 6 characters',
        prefixIcon: const Icon(Icons.lock),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscureNew = !_obscureNew),
        ),
      ),
      validator: (value) => Validators.validatePassword(value),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Confirm New Password',
        hintText: 'Re-enter your new password',
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your new password';
        }
        if (value != _newPasswordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildResetButton(AuthState authState) {
    return AuthButton(
      text: 'Reset Password',
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          ref.read(authProvider.notifier).resetPassword(
                email: widget.email,
                newPassword: _newPasswordController.text,
                confirmPassword: _confirmPasswordController.text,
              );
        }
      },
      isLoading: authState.isLoading,
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