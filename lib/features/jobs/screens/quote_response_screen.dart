import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/quote_provider.dart';
import '../../../shared/models/quote_model.dart';
import '../../../shared/models/quote_status.dart';

class QuoteResponseScreen extends ConsumerStatefulWidget {
  final String jobId;

  const QuoteResponseScreen({super.key, required this.jobId});

  @override
  ConsumerState<QuoteResponseScreen> createState() => _QuoteResponseScreenState();
}

class _QuoteResponseScreenState extends ConsumerState<QuoteResponseScreen> {
  final _counterController = TextEditingController();
  final _rejectReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(quoteProvider.notifier).fetchQuotesByJob(widget.jobId));
  }

  @override
  void dispose() {
    _counterController.dispose();
    _rejectReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quoteProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quotes')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.quotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_empty, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No quotes yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text('Providers are reviewing your request', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.quotes.length,
                  itemBuilder: (context, index) => _buildQuoteCard(state.quotes[index], state),
                ),
    );
  }

  Widget _buildQuoteCard(QuoteModel quote, QuoteState state) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ', decimalDigits: 2);
    final isExpired = quote.expiresAt != null && quote.expiresAt!.isBefore(DateTime.now()) && quote.isRespondable;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _statusColor(quote.status).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _statusLabel(quote.status, isExpired),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(quote.status),
                    ),
                  ),
                ),
                if (quote.expiresAt != null)
                  Text(
                    'Expires ${DateFormat('MMM d, HH:mm').format(quote.expiresAt!)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(currencyFormat.format(quote.amount),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                    const Spacer(),
                    if (quote.estimatedDurationMinutes > 0)
                      Text('~${quote.estimatedDurationMinutes} min',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
                if (quote.description != null && quote.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(quote.description!, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4)),
                ],
                if (quote.counterAmount != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.replay, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Text('Your counter-offer: ${currencyFormat.format(quote.counterAmount)}',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.amber.shade900, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                if (quote.rejectionReason != null) ...[
                  const SizedBox(height: 12),
                  Text('Reason: ${quote.rejectionReason}',
                      style: TextStyle(fontSize: 13, color: Colors.red.shade600, fontStyle: FontStyle.italic)),
                ],
                if (quote.isRespondable && !isExpired) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _buildActions(quote, state),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(QuoteModel quote, QuoteState state) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);

    if (quote.status == QuoteStatus.countered) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.isSubmitting ? null : () => _acceptQuote(quote.id),
              icon: state.isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle, size: 18),
              label: Text(state.isSubmitting ? 'Accepting...' : 'Accept Counter-Offer at ${currencyFormat.format(quote.counterAmount!)}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: state.isSubmitting ? null : () => _acceptQuote(quote.id),
                  icon: state.isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _showCounterDialog(quote),
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Counter'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: TextButton.icon(
            onPressed: () => _showRejectDialog(quote.id),
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
            label: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Future<void> _acceptQuote(String quoteId) async {
    final success = await ref.read(quoteProvider.notifier).acceptQuote(quoteId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Quote accepted \u2014 price locked!' : 'Failed to accept quote'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) Navigator.pop(context, true);
    }
  }

  void _showCounterDialog(QuoteModel quote) {
    _counterController.text = (quote.amount * 0.9).toStringAsFixed(0);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Counter-Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Suggest a different price:'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _counterController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: 'KES ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(_counterController.text);
              if (amount == null || amount < 50) return;
              Navigator.pop(ctx);
              final success = await ref.read(quoteProvider.notifier).submitCounterOffer(quote.id, amount);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Counter-offer submitted' : 'Failed'), backgroundColor: success ? Colors.green : Colors.red),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String quoteId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Quote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Provide a reason (optional):'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rejectReasonController,
              maxLines: 2,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. Too expensive'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(quoteProvider.notifier).rejectQuote(quoteId, reason: _rejectReasonController.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Quote declined' : 'Failed'), backgroundColor: success ? Colors.green : Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  String _statusLabel(QuoteStatus status, bool isExpired) {
    if (isExpired) return 'Expired';
    switch (status) {
      case QuoteStatus.pending: return 'Awaiting your response';
      case QuoteStatus.accepted: return 'Accepted \u2014 Price Locked';
      case QuoteStatus.rejected: return 'Declined by you';
      case QuoteStatus.countered: return 'Counter-offer from you';
      case QuoteStatus.expired: return 'Expired';
    }
  }

  Color _statusColor(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.pending: return Colors.orange;
      case QuoteStatus.accepted: return Colors.green;
      case QuoteStatus.rejected: return Colors.red;
      case QuoteStatus.countered: return Colors.amber;
      case QuoteStatus.expired: return Colors.grey;
    }
  }
}
