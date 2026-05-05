import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

class RequestServiceScreen extends ConsumerStatefulWidget {
  const RequestServiceScreen({super.key});

  @override
  ConsumerState<RequestServiceScreen> createState() =>
      _RequestServiceScreenState();
}

class _RequestServiceScreenState extends ConsumerState<RequestServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  double _estimatedPrice = 0;
  bool _isLoading = false;

  final List<String> _categories = [
    'Plumbing',
    'Electrical',
    'Cleaning',
    'Moving',
    'Gardening',
    'Painting',
    'Carpentry',
    'Appliance Repair',
  ];

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

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Describe the service you need...',
        prefixIcon: Icon(Icons.description),
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
    // Simple price estimation logic
    double basePrice = 0;

    switch (_selectedCategory) {
      case 'Plumbing':
        basePrice = 1000;
        break;
      case 'Electrical':
        basePrice = 1200;
        break;
      case 'Cleaning':
        basePrice = 800;
        break;
      default:
        basePrice = 500;
    }

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

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        Endpoints.requestJob,
        data: {
          'category': _selectedCategory,
          'description': _descriptionController.text,
          'estimatedPrice': _estimatedPrice,
        },
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/matching/${response.data['id']}',
          );
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
}
