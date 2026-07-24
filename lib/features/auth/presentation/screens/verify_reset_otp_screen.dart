import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/auth_button.dart';
import '../../providers/auth_provider.dart';
import '../../models/auth_state.dart';

class VerifyResetOtpScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyResetOtpScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyResetOtpScreen> createState() =>
      _VerifyResetOtpScreenState();
}

class _VerifyResetOtpScreenState extends ConsumerState<VerifyResetOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _timerSeconds = 60;
  bool _canResend = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _tick();
  }

  void _tick() {
    if (_disposed || !mounted) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (_disposed || !mounted) return;
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
        });
        _tick();
      } else {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _getOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen for OTP verified state → navigate to reset-password
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.resetOtpVerified && previous?.resetOtpVerified == false) {
        context.push('/reset-password', extra: next.resetEmail);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Reset Code')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildOtpInputs(),
                    const SizedBox(height: 16),
                    _buildResendButton(),
                    const SizedBox(height: 24),
                    _buildVerifyButton(authState),
                    if (authState.error != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(authState.error!),
                    ],
                    const SizedBox(height: 24),
                  ],
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
          child: Icon(Icons.pin_outlined,
              size: 40, color: Colors.orange.shade700),
        ),
        const SizedBox(height: 16),
        const Text(
          'Enter Reset Code',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to\n${widget.email}',
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Code expires in 5 minutes',
          style: TextStyle(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOtpInputs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final itemWidth =
            ((constraints.maxWidth - spacing * 5) / 6).clamp(48.0, 72.0);
        final useWrap = constraints.maxWidth < (itemWidth * 6 + spacing * 5);

        final inputs = List.generate(6, (index) {
          return SizedBox(
            width: itemWidth,
            child: TextFormField(
              controller: _otpControllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white,
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
        });

        if (useWrap) {
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.center,
            children: inputs,
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: inputs,
        );
      },
    );
  }

  Widget _buildResendButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _canResend
              ? "Didn't receive code? "
              : 'Resend code in $_timerSeconds seconds',
          style: TextStyle(color: _canResend ? Colors.black : Colors.grey),
        ),
        if (_canResend)
          TextButton(
            onPressed: () {
              ref
                  .read(authProvider.notifier)
                  .resendResetOtp(widget.email);
              setState(() {
                _timerSeconds = 60;
                _canResend = false;
              });
              _startTimer();
            },
            child: const Text('Resend'),
          ),
      ],
    );
  }

  Widget _buildVerifyButton(AuthState authState) {
    return AuthButton(
      text: 'Verify Code',
      onPressed: _getOtp().length == 6
          ? () {
              ref
                  .read(authProvider.notifier)
                  .verifyResetOtp(widget.email, _getOtp());
            }
          : null,
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