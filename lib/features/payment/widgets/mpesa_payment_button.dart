import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/payment_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';

class MpesaPaymentButton extends ConsumerStatefulWidget {
  final String jobId;
  final double amount;
  final VoidCallback onSuccess;
  final VoidCallback? onFailure;

  const MpesaPaymentButton({
    super.key,
    required this.jobId,
    required this.amount,
    required this.onSuccess,
    this.onFailure,
  });

  @override
  ConsumerState<MpesaPaymentButton> createState() => _MpesaPaymentButtonState();
}

class _MpesaPaymentButtonState extends ConsumerState<MpesaPaymentButton> {
  final TextEditingController _phoneController = TextEditingController();
  bool _showPhoneDialog = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    
    return Column(
      children: [
        if (_showPhoneDialog)
          _buildPhoneDialog(),
        
        if (!_showPhoneDialog && !paymentState.isPendingVerification)
          ElevatedButton.icon(
            onPressed: paymentState.isProcessing ? null : () {
              setState(() {
                _showPhoneDialog = true;
              });
            },
            icon: Image.asset(
              'assets/images/mpesa.png',
              height: 24,
              width: 24,
            ),
            label: paymentState.isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Pay KES ${widget.amount.toStringAsFixed(2)}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        
        if (paymentState.isPendingVerification)
          _buildPendingVerification(),
        
        if (paymentState.isCompleted)
          _buildSuccessWidget(),
        
        if (paymentState.isFailed)
          _buildFailureWidget(paymentState.error),
      ],
    );
  }

  Widget _buildPhoneDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mobile_friendly, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Enter M-PESA Phone Number',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You will receive a prompt on your phone to complete payment',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'M-PESA Phone Number',
                hintText: '0712345678',
                prefixIcon: Icon(Icons.phone_android),
                prefixText: '+254 ',
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validators.validatePhoneNumber(value),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showPhoneDialog = false;
                        _phoneController.clear();
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _processPayment,
                    child: const Text('Pay Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment() async {
    final phoneError = Validators.validatePhoneNumber(_phoneController.text);
    if (phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phoneError)),
      );
      return;
    }
    
    setState(() {
      _showPhoneDialog = false;
    });
    
    final paymentNotifier = ref.read(paymentProvider.notifier);
    await paymentNotifier.initiateMpesaPayment(
      widget.jobId,
      widget.amount,
      _phoneController.text,
    );
    
    _phoneController.clear();
  }

  Widget _buildPendingVerification() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 16),
          const Text(
            'Check your phone',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your M-PESA PIN to complete payment',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              ref.read(paymentProvider.notifier).checkPaymentStatus();
            },
            child: const Text('Check Status'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 48, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Payment Successful!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Transaction ID: ${ref.read(paymentProvider).transactionId}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              widget.onSuccess();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureWidget(String? error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Payment Failed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'Please try again',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(paymentProvider.notifier).reset();
              setState(() {});
            },
            child: const Text('Try Again'),
          ),
          if (widget.onFailure != null)
            TextButton(
              onPressed: widget.onFailure,
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }
}