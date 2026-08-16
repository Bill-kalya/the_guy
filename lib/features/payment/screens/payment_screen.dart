import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import '../providers/payment_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/themes/colors.dart';
import '../../../core/utils/validators.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String jobId;

  const PaymentScreen({super.key, required this.jobId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final paymentNotifier = ref.read(paymentProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: paymentState.isProcessing
          ? const LoadingWidget(message: 'Processing payment...')
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPaymentSummary(paymentState.amount),
                      const SizedBox(height: 24),
                      _buildMethodSelector(paymentNotifier, paymentState),
                      const SizedBox(height: 24),
                      if (paymentState.selectedMethod == 'MPESA') ...[
                        _buildPhoneInput(),
                        const SizedBox(height: 16),
                        _buildMpesaInfo(),
                        const SizedBox(height: 24),
                        _buildMpesaButton(paymentNotifier),
                      ],
                      if (paymentState.selectedMethod == 'CARD') ...[
                        _buildCardInfo(),
                        const SizedBox(height: 24),
                        _buildCardButton(paymentNotifier),
                      ],
                      if (paymentState.status == 'pending_verification')
                        _buildPendingVerification('Check your phone to complete payment. Waiting for confirmation...'),
                      if (paymentState.status == 'card_processing')
                        _buildPendingVerification('Processing card payment...'),
                      if (paymentState.status == 'completed')
                        _buildSuccessBanner(),
                      if (paymentState.status == 'failed')
                        _buildFailedBanner(paymentState.error),
                      if (paymentState.error != null &&
                          paymentState.status != 'failed')
                        _buildErrorBanner(paymentState.error!),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPaymentSummary(double amount) {
    final displayAmount = amount > 0 ? amount.toStringAsFixed(2) : '0.00';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Service Fee', style: TextStyle(fontSize: 16)),
                Text(
                  'KES $displayAmount',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'KES $displayAmount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelector(PaymentNotifier notifier, PaymentState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MethodOption(
                icon: Icons.phone_android,
                label: 'M-Pesa',
                isSelected: state.selectedMethod == 'MPESA',
                onTap: () => notifier.setSelectedMethod('MPESA'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MethodOption(
                icon: Icons.credit_card,
                label: 'Card (Stripe)',
                isSelected: state.selectedMethod == 'CARD',
                onTap: () => notifier.setSelectedMethod('CARD'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return TextField(
      controller: _phoneController,
      focusNode: _phoneFocusNode,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'M-Pesa Phone Number',
        hintText: '07XXXXXXXX or 2547XXXXXXXX',
        prefixText: '+254 ',
        errorText: _phoneError,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) {
        if (_phoneError != null) {
          setState(() => _phoneError = null);
        }
      },
    );
  }

  Widget _buildMpesaInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'M',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'M-PESA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text('Pay using M-PESA', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.credit_card, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CARD (STRIPE)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text('Pay securely with credit or debit card',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMpesaButton(PaymentNotifier notifier) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          final phone = _phoneController.text.trim();
          final validationError = Validators.validatePhoneNumber(phone);
          if (validationError != null) {
            setState(() => _phoneError = validationError);
            _phoneFocusNode.requestFocus();
            return;
          }
          final normalizedPhone = phone.startsWith('+254')
              ? phone
              : phone.startsWith('254')
                  ? '+$phone'
                  : '+254${phone.substring(1)}';
          notifier.initiateMpesaPayment(widget.jobId,
              phoneNumber: normalizedPhone);
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.green,
        ),
        child: const Text('Pay with M-PESA', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildCardButton(PaymentNotifier notifier) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            await notifier.initiateCardPayment(widget.jobId);
            final newState = ref.read(paymentProvider);

            if (newState.clientSecret != null) {
              await Stripe.instance.initPaymentSheet(
                paymentSheetParameters: SetupPaymentSheetParameters(
                  paymentIntentClientSecret: newState.clientSecret!,
                  merchantDisplayName: 'The Guy',
                ),
              );
              await Stripe.instance.presentPaymentSheet();

              notifier.setCardProcessing();
              notifier.checkPaymentStatus();
            }
          } on StripeException catch (e) {
            if (e.error.code != FailureCode.Canceled) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Card payment failed: ${e.error.message}')),
                );
              }
              notifier.reset();
            }
          } catch (e) {
            if (!e.toString().contains('canceled')) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Card payment failed: $e')),
                );
              }
              notifier.reset();
            }
          }
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.blue.shade700,
        ),
        child: const Text('Pay with Card', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildPendingVerification(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 14)),
          ),
          TextButton(
            onPressed: () {
              ref.read(paymentProvider.notifier).checkPaymentStatus();
            },
            child: const Text('Check'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Payment successful! Funds are held in escrow.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedBanner(String? error) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error ?? 'Payment failed. Please try again.',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.shade50 : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
