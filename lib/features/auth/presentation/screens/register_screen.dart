import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../home/providers/location_provider.dart';
import '../../../../shared/widgets/password_validator.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import 'register_screen_desktop.dart';

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

  bool _isLoading = false;
  String _selectedRole = 'customer';
  bool _agreeToTerms = false;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _generalError;
  String _password = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _generalError = null;
    });
  }

  void _handleError(dynamic error) {
    if (error is AppException) {
      setState(() {
        if (error.fieldErrors != null && error.fieldErrors!.isNotEmpty) {
          for (final fe in error.fieldErrors!) {
            switch (fe.field) {
              case 'fullName':
              case 'name':
                _nameError = fe.message;
                break;
              case 'email':
                _emailError = fe.message;
                break;
              case 'password':
                _passwordError = fe.message;
                break;
            }
          }
        } else {
          final mapped = ErrorMapper.map(error.code);
          _generalError = '${mapped.title}\n${mapped.message}';
        }
      });
    } else {
      setState(() {
        _generalError = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: Scaffold(
        appBar: AppBar(
          title: const Text('Create Account'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  if (_generalError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _generalError!,
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          if (_generalError!.contains('already exists')) ...[
                            const SizedBox(height: 8),
                            TextButton(
                               onPressed: () => context.go('/login'),
                              child: const Text('Sign In Instead'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  _buildNameField(),
                  const SizedBox(height: 16),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 8),
                  PasswordValidator(password: _password),
                  const SizedBox(height: 16),
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 24),
                  _buildRoleSelector(),
                  const SizedBox(height: 24),
                  _buildTermsCheckbox(),
                  const SizedBox(height: 24),
                  _buildRegisterButton(),
                  const SizedBox(height: 16),
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
        ),
      ),
      desktop: const RegisterScreenDesktop(),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_add, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        const Text(
          'Join The Guy',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Create an account to get started',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: 'John Doe',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: const Icon(Icons.person),
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
        errorText: _nameError,
      ),
      validator: (value) =>
          Validators.validateName(value, fieldName: 'Full name'),
      onChanged: (_) {
        if (_nameError != null) setState(() => _nameError = null);
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'john@example.com',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: const Icon(Icons.email),
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
        errorText: _emailError,
      ),
      validator: (value) => Validators.validateEmail(value),
      onChanged: (_) {
        if (_emailError != null) setState(() => _emailError = null);
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'At least 8 characters',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: const Icon(Icons.lock),
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
        errorText: _passwordError,
      ),
      validator: (value) => Validators.validatePassword(value),
      onChanged: (value) {
        setState(() => _password = value);
        if (_passwordError != null) setState(() => _passwordError = null);
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: true,
      textInputAction: TextInputAction.done,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        hintText: 'Re-enter your password',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: const Icon(Icons.lock_outline),
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
        errorText: _confirmPasswordError,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      onChanged: (_) {
        if (_confirmPasswordError != null) {
          setState(() => _confirmPasswordError = null);
        }
      },
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'I want to:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildRoleCard(
          icon: Icons.person_outline,
          title: 'Customer',
          subtitle: 'Hire service pros',
          value: 'customer',
          isSelected: _selectedRole == 'customer',
        ),
        const SizedBox(height: 12),
        _buildRoleCard(
          icon: Icons.handyman_outlined,
          title: 'Provider',
          subtitle: 'Offer your skills',
          value: 'provider',
          isSelected: _selectedRole == 'provider',
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary.withValues(alpha: 0.7), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() {
              _agreeToTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the ',
              children: [
                TextSpan(
                  text: 'Terms of Service',
                  style: const TextStyle(color: Colors.blue),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading || !_agreeToTerms ? null : _register,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Create Account'),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? '),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Login'),
        ),
      ],
    );
  }

  bool _validatePassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#\$%^&+=]'));
  }

  Future<void> _register() async {
    _clearErrors();

    if (!_validatePassword(_passwordController.text)) {
      setState(() {
        _passwordError =
            'Password must include uppercase, lowercase, number, and special character.';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final locationState = ref.read(locationProvider);
      final location = locationState.currentPosition;

      final response = await apiClient.post(
        Endpoints.register,
        data: {
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'role': _selectedRole.toUpperCase(),
          'latitude': location?.latitude,
          'longitude': location?.longitude,
        },
      );

      if (response.statusCode == 201 && mounted) {
        context.push('/verify-email', extra: _emailController.text.trim());
      }
    } on DioException catch (e) {
      if (e.error is AppException) {
        _handleError(e.error);
      } else {
        _handleError(e);
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
