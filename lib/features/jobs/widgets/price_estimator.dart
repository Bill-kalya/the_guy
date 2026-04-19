import 'package:flutter/material.dart';

class PriceEstimator extends StatefulWidget {
  final Function(double) onPriceChanged;
  final double initialPrice;
  final double minPrice;
  final double maxPrice;

  const PriceEstimator({
    super.key,
    required this.onPriceChanged,
    this.initialPrice = 500,
    this.minPrice = 100,
    this.maxPrice = 10000,
  });

  @override
  State<PriceEstimator> createState() => _PriceEstimatorState();
}

class _PriceEstimatorState extends State<PriceEstimator> {
  late double _currentPrice;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _currentPrice = widget.initialPrice;
    _controller = TextEditingController(text: _currentPrice.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Estimate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'KES ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      final price = double.tryParse(value);
                      if (price != null && price >= widget.minPrice && price <= widget.maxPrice) {
                        setState(() {
                          _currentPrice = price;
                        });
                        widget.onPriceChanged(price);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Min: KES ${widget.minPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  'Max: KES ${widget.maxPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: _currentPrice,
              min: widget.minPrice,
              max: widget.maxPrice,
              divisions: 100,
              label: 'KES ${_currentPrice.toStringAsFixed(0)}',
              onChanged: (value) {
                setState(() {
                  _currentPrice = value;
                  _controller.text = value.toStringAsFixed(0);
                });
                widget.onPriceChanged(value);
              },
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: const Text(
                      'This is an estimate. Final price will be confirmed by the provider.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}