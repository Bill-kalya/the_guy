import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../shared/constants/service_categories.dart';
import '../../home/providers/location_provider.dart';

class RequestServiceScreen extends ConsumerStatefulWidget {
  final String? initialCategory;

  const RequestServiceScreen({super.key, this.initialCategory});

  @override
  ConsumerState<RequestServiceScreen> createState() =>
      _RequestServiceScreenState();
}

class _RequestServiceScreenState extends ConsumerState<RequestServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String _urgency = 'INSTANT';
  double _estimatedPrice = 0;
  bool _isLoading = false;

  final List<String> _categories = ServiceCategories.names;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
      _estimatePrice();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Service')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildUrgencySelector(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildPriceEstimator(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Service Category',
        prefixIcon: Icon(Icons.category),
      ),
      initialValue: _selectedCategory,
      items: _categories.map((category) {
        return DropdownMenuItem(value: category, child: Text(category));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
          _estimatePrice();
        });
      },
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Widget _buildUrgencySelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'INSTANT',
          icon: Icon(Icons.flash_on),
          label: Text('Now'),
        ),
        ButtonSegment(
          value: 'SCHEDULED',
          icon: Icon(Icons.schedule),
          label: Text('Later'),
        ),
      ],
      selected: {_urgency},
      onSelectionChanged: (selection) {
        setState(() => _urgency = selection.first);
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Describe the service you need...',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: const Icon(Icons.description),
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => Validators.validateDescription(value),
      onChanged: (_) => _estimatePrice(),
    );
  }

  Widget _buildPriceEstimator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Estimated Price',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'KES ${_estimatedPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Final price will be confirmed by provider',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _estimatePrice() {
    // Get base price from centralized categories
    final basePrice = ServiceCategories.getBasePrice(_selectedCategory ?? '');

    // Adjust based on description length (more details = higher estimate)
    final descriptionLength = _descriptionController.text.length;
    final adjustment = (descriptionLength / 100) * 200;

    setState(() {
      _estimatedPrice = basePrice + adjustment.clamp(0, 2000);
    });
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitRequest,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text('Request Service'),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final locationState = ref.read(locationProvider);
    final position = locationState.currentPosition;
    if (position == null) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Enable location to request a service');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        Endpoints.requestJob,
        data: {
          'category': _selectedCategory,
          'description': _descriptionController.text,
          'urgency': _urgency,
          'budgetMin': (_estimatedPrice - 1000).clamp(0, double.infinity),
          'budgetMax': _estimatedPrice + 1000,
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
        },
      );

      if (response.statusCode == 201) {
        final id = _extractJobId(response.data);
        if (mounted && id != null) {
          context.pushReplacement('/matching/$id');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Failed to submit request');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _extractJobId(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic> && inner['id'] != null) {
        return inner['id'] as String;
      }
      if (data['id'] != null) {
        return data['id'] as String;
      }
    }
    return null;
  }
}
