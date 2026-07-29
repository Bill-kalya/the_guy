import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/themes/colors.dart';
import '../../../../shared/models/pricing_type.dart';
import '../../../../shared/models/pricing_config_model.dart';

class ProviderPricingScreen extends ConsumerStatefulWidget {
  const ProviderPricingScreen({super.key});

  @override
  ConsumerState<ProviderPricingScreen> createState() => _ProviderPricingScreenState();
}

class _ProviderPricingScreenState extends ConsumerState<ProviderPricingScreen> {
  PricingType _pricingType = PricingType.catalog;
  final _basePriceController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  double _adjustmentPercent = 10;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPricingConfig();
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadPricingConfig() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get(Endpoints.providerPricing);
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null) {
        final config = PricingConfigModel.fromJson(data);
        setState(() {
          _pricingType = config.pricingType;
          _basePriceController.text = config.basePrice.toStringAsFixed(0);
          if (config.minPrice != null) _minPriceController.text = config.minPrice!.toStringAsFixed(0);
          if (config.maxPrice != null) _maxPriceController.text = config.maxPrice!.toStringAsFixed(0);
          _adjustmentPercent = config.adjustmentPercent.toDouble();
        });
      }
    } catch (e) {
      // New provider — no config yet, use defaults
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePricingConfig() async {
    final basePrice = double.tryParse(_basePriceController.text);
    if (basePrice == null || basePrice < 50) {
      setState(() => _error = 'Base price must be at least KES 50');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final body = <String, dynamic>{
        'pricingType': _pricingType.apiValue,
        'basePrice': basePrice,
        'adjustmentPercent': _adjustmentPercent.round(),
      };
      final minPrice = double.tryParse(_minPriceController.text);
      final maxPrice = double.tryParse(_maxPriceController.text);
      if (minPrice != null) body['minPrice'] = minPrice;
      if (maxPrice != null) body['maxPrice'] = maxPrice;

      await api.put(Endpoints.providerPricing, data: body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pricing configuration saved'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to save: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing Setup')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPricingTypeSelector(),
                  const SizedBox(height: 20),
                  _buildBasePriceField(),
                  const SizedBox(height: 20),
                  _buildPriceRangeFields(),
                  const SizedBox(height: 20),
                  _buildAdjustmentSlider(),
                  const SizedBox(height: 20),
                  _buildPricingInfoCard(),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
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
                          Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePricingConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Pricing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPricingTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pricing Model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SegmentedButton<PricingType>(
              segments: PricingType.values.map((type) {
                return ButtonSegment(
                  value: type,
                  label: Text(type.displayName, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              selected: {_pricingType},
              onSelectionChanged: (set) => setState(() => _pricingType = set.first),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: Colors.blue.shade50,
                selectedForegroundColor: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pricingSubtitle(_pricingType),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
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

  Widget _buildBasePriceField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Base Price', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _basePriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'KES ',
                border: const OutlineInputBorder(),
                hintText: 'e.g. 1000',
                helperText: _pricingType == PricingType.platformCalculated
                    ? 'Base price the platform will use as reference'
                    : 'Your standard price for this service',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeFields() {
    if (_pricingType != PricingType.platformCalculated) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Price Range (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Set bounds the platform will suggest to customers', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(prefixText: 'KES ', border: OutlineInputBorder(), labelText: 'Min'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(prefixText: 'KES ', border: OutlineInputBorder(), labelText: 'Max'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentSlider() {
    if (_pricingType != PricingType.platformCalculated) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Adjustment Allowance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_adjustmentPercent.round()}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 4),
            Text('How much you can adjust the platform-calculated price', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Slider(
              value: _adjustmentPercent,
              min: 0,
              max: 25,
              divisions: 10,
              label: '${_adjustmentPercent.round()}%',
              onChanged: (v) => setState(() => _adjustmentPercent = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0% (fixed)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                Text('25% max', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _pricingInfoText(),
              style: TextStyle(fontSize: 12, color: Colors.blue.shade800, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _pricingSubtitle(PricingType type) {
    switch (type) {
      case PricingType.catalog:
        return 'Set a fixed price. Customers see and accept immediately.';
      case PricingType.quoteRequired:
        return 'Customers request a quote. You respond with a price.';
      case PricingType.platformCalculated:
        return 'Platform suggests a price. You can adjust within your allowance.';
    }
  }

  String _pricingInfoText() {
    switch (_pricingType) {
      case PricingType.catalog:
        return 'Customers will see this price and can book instantly. Best for standardized services with predictable pricing.';
      case PricingType.quoteRequired:
        return 'Customers will request a quote. You\'ll receive a notification and can respond with your price. Best for custom or variable services.';
      case PricingType.platformCalculated:
        return 'The platform calculates a fair price based on market data. You can adjust within \$${_adjustmentPercent.round()}%. Best for competitive categories.';
    }
  }
}
