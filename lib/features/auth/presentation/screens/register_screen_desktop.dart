import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../home/providers/location_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/themes/colors.dart';

class RegisterScreenDesktop extends ConsumerStatefulWidget {
  const RegisterScreenDesktop({super.key});

  @override
  ConsumerState<RegisterScreenDesktop> createState() => _RegisterScreenDesktopState();
}

class _RegisterScreenDesktopState extends ConsumerState<RegisterScreenDesktop> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _selectedRole = 'customer';
  bool _agreeToTerms = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopNavBar(),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 4, child: _buildBenefitsPanel()),
                Expanded(flex: 5, child: _buildRegistrationWizard()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                      child: Image.asset('assets/icons/icon (2).png', fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 8),
                    Text('The Guy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const Spacer(),
                TextButton(onPressed: () => context.push('/login'), child: const Text('Sign In')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsPanel() {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade600, Colors.green.shade500],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why Join?', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 48),
              _benefitItem(Icons.trending_up, 'Customer Growth', 'Access 5,000+ verified providers ready to serve you'),
              const SizedBox(height: 32),
              _benefitItem(Icons.attach_money, 'Provider Earnings', 'Earn up to KES 45,000/month on your own schedule'),
              const SizedBox(height: 32),
              _benefitItem(Icons.security, 'Trust & Safety', 'Verified profiles, secure payments, and dispute protection'),
              const SizedBox(height: 32),
              _benefitItem(Icons.timer, 'Real-Time Tracking', 'Track your service provider in real-time'),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.format_quote, color: Colors.white.withValues(alpha: 0.6), size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The Guy transformed my business. I went from zero to 50+ regular clients in just 3 months.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _benefitItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationWizard() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step indicator
                Row(
                  children: [
                    _stepDot(0, 'Account'),
                    Expanded(child: Divider(color: _currentStep >= 1 ? Colors.blue : Colors.grey.shade300)),
                    _stepDot(1, 'Details'),
                    Expanded(child: Divider(color: _currentStep >= 2 ? Colors.blue : Colors.grey.shade300)),
                    _stepDot(2, 'Confirm'),
                  ],
                ),
                const SizedBox(height: 40),
                // Step content
                if (_currentStep == 0) _buildStep1ChooseRole(),
                if (_currentStep == 1) _buildStep2Details(),
                if (_currentStep == 2) _buildStep3Confirm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepDot(int index, String label) {
    final isActive = _currentStep >= index;
    final isCurrent = _currentStep == index;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: AppColors.primary, width: 3) : null,
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text('${index + 1}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: isActive ? Colors.blue : Colors.grey.shade500, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }

  Widget _buildStep1ChooseRole() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Account Type', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text('Select how you want to use The Guy', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        _buildRoleCard(
          icon: Icons.person_search,
          title: 'Customer',
          subtitle: 'Hire Professionals',
          value: 'customer',
          features: ['Plumbing', 'Electrical', 'Cleaning', 'Moving', 'Tutoring', 'Pet Care'],
          color: Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          icon: Icons.handyman,
          title: 'Provider',
          subtitle: 'Earn From Your Skills',
          value: 'provider',
          features: ['Flexible Hours', 'Receive Requests Nearby', 'Weekly Earnings', 'Build Your Reputation'],
          color: Colors.green,
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
            ),
            child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> features,
    required MaterialColor color,
  }) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isSelected ? color : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade600, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? color.shade700 : Colors.black87)),
                      const SizedBox(width: 8),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 4,
                    children: features.map((f) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: color.shade600),
                        const SizedBox(width: 4),
                        Text(f, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                      ],
                    )).toList(),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color.shade600, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text('Fill in your information to create an account', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        Text('Full Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController, textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'John Doe', prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true, fillColor: Colors.grey.shade50,
          ),
          validator: (value) => Validators.validateName(value, fieldName: 'Full name'),
        ),
        const SizedBox(height: 20),
        Text('Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'john@example.com', prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true, fillColor: Colors.grey.shade50,
          ),
          validator: (value) => Validators.validateEmail(value),
        ),
        const SizedBox(height: 20),
        Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController, obscureText: true, textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'At least 6 characters', prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true, fillColor: Colors.grey.shade50,
          ),
          validator: (value) => Validators.validatePassword(value),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Back', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.trim().isNotEmpty && _emailController.text.trim().isNotEmpty && _passwordController.text.isNotEmpty) {
                      setState(() => _currentStep = 2);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Confirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Confirm & Register', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text('Review your information before creating your account', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _reviewRow('Account Type', _selectedRole == 'customer' ? 'Customer' : 'Provider'),
              const Divider(height: 24),
              _reviewRow('Full Name', _nameController.text.trim()),
              const Divider(height: 24),
              _reviewRow('Email', _emailController.text.trim()),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController, obscureText: true, textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Re-enter your password', prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true, fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please confirm your password';
            if (value != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(value: _agreeToTerms, onChanged: (v) => setState(() => _agreeToTerms = v ?? false)),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'I agree to the ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  children: [
                    TextSpan(text: 'Terms of Service', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    const TextSpan(text: ' and '),
                    TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Back', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading || !_agreeToTerms ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
      ],
    );
  }

  Future<void> _register() async {
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
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}