import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/auth_button.dart';
import '../../providers/auth_provider.dart';
import '../../models/auth_state.dart';

class OTPScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OTPScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _timerSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), _updateTimer);
  }

  void _updateTimer() {
    if (_timerSeconds > 0) {
      setState(() {
        _timerSeconds--;
      });
      Future.delayed(const Duration(seconds: 1), _updateTimer);
    } else {
      setState(() {
        _canResend = true;
      });
    }
  }

  String _getOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 1),
            _buildHeader(),
            const SizedBox(height: 32),
            _buildOtpInputs(),
            const SizedBox(height: 16),
            _buildResendButton(),
            const SizedBox(height: 24),
            _buildVerifyButton(authState),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.sms, size: 64, color: Colors.blue),
        const SizedBox(height: 16),
        const Text(
          'Enter Verification Code',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to ${widget.phoneNumber}',
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOtpInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 50,
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildResendButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _canResend
              ? 'Didn\'t receive code? '
              : 'Resend code in $_timerSeconds seconds',
          style: TextStyle(color: _canResend ? Colors.black : Colors.grey),
        ),
        if (_canResend)
          TextButton(
            onPressed: () {
              ref
                  .read(authProvider.notifier)
                  .loginWithPhone(widget.phoneNumber);
              setState(() {
                _timerSeconds = 60;
                _canResend = false;
                _startTimer();
              });
            },
            child: const Text('Resend'),
          ),
      ],
    );
  }

  Widget _buildVerifyButton(AuthState authState) {
    return AuthButton(
      text: 'Verify',
      onPressed: _getOtp().length == 6
          ? () {
              ref
                  .read(authProvider.notifier)
                  .verifyOtp(widget.phoneNumber, _getOtp());
            }
          : null,
      isLoading: authState.isLoading,
    );
  }
}
