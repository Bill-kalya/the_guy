import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/constants/service_categories.dart';
import '../../../../core/themes/colors.dart';

class ProviderRegistrationScreen extends ConsumerStatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  ConsumerState<ProviderRegistrationScreen> createState() => _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState extends ConsumerState<ProviderRegistrationScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1 — Basic Info (pre-filled)
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  // Step 2 — Business Info
  late TextEditingController _bioController;
  late TextEditingController _businessNameController;
  int _yearsExperience = 0;
  double _serviceRadius = 10;

  // Step 3 — Service categories
  final Set<String> _selectedCategories = {};

  // Step 4 — Service offerings per category
  final Map<String, List<_ServiceOffering>> _offerings = {};

  // Step 5 — Location
  double? _latitude;
  double? _longitude;
  String? _locationError;
  bool _locationLoading = false;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = ref.read(authProvider).user;
      _nameController = TextEditingController(text: user?.name ?? '');
      _emailController = TextEditingController(text: user?.email ?? '');
      _phoneController = TextEditingController(text: user?.phone ?? '');
      _bioController = TextEditingController();
      _businessNameController = TextEditingController();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  // ── Location ──────────────────────────────────────────
  Future<void> _captureLocation() async {
    setState(() => _locationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _locationError = 'Location services are disabled'; _locationLoading = false; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _locationError = 'Location permission denied'; _locationLoading = false; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _locationError = 'Location permission permanently denied'; _locationLoading = false; });
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _locationError = null;
        _locationLoading = false;
      });
    } catch (e) {
      setState(() { _locationError = 'Failed to get location: $e'; _locationLoading = false; });
    }
  }

  // ── Submit ────────────────────────────────────────────
  Future<void> _submit() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one service category')),
      );
      return;
    }
    if (_bioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a bio')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(apiClientProvider);
      final services = <Map<String, dynamic>>[];

      for (final cat in _selectedCategories) {
        final catOfferings = _offerings[cat];
        if (catOfferings != null && catOfferings.isNotEmpty) {
          for (final o in catOfferings) {
            services.add({
              'category': cat,
              'title': o.titleController.text.trim(),
              'description': o.descriptionController.text.trim(),
              'pricingType': o.pricingType,
              'basePrice': o.price,
            });
          }
        } else {
          services.add({
            'category': cat,
            'title': cat,
            'description': '',
            'pricingType': 'NEGOTIABLE',
            'basePrice': 0,
          });
        }
      }

      final response = await api.post(
        '/api/providers/register',
        data: {
          'bio': _bioController.text.trim(),
          'services': services,
          'latitude': _latitude,
          'longitude': _longitude,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Provider registration successful!')),
          );
          context.go('/provider/home');
        }
      } else {
        final msg = response.data?['message'] ?? 'Registration failed';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Become a Provider'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep--),
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressBar(),
          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ),
          // Bottom button
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final steps = ['Basic Info', 'Business', 'Services', 'Pricing', 'Location'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length, (i) {
              final isActive = i == _currentStep;
              final isDone = i < _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    if (i > 0) Expanded(child: Container(height: 2, color: isDone ? Colors.blue : Colors.grey.shade300)),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? AppColors.primary : isActive ? AppColors.primary : Colors.grey.shade300,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.grey.shade600)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(steps[_currentStep], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStep1BasicInfo();
      case 1: return _buildStep2BusinessInfo();
      case 2: return _buildStep3Categories();
      case 3: return _buildStep4Pricing();
      case 4: return _buildStep5Location();
      default: return const SizedBox();
    }
  }

  // ── Step 1: Basic Info ──────────────────────────────
  Widget _buildStep1BasicInfo() {
    final user = ref.watch(authProvider).user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                child: user?.avatar == null
                    ? Text(_initials(user?.name ?? ''), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary))
                    : null,
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildField(label: 'Full Name', controller: _nameController, icon: Icons.person_outline),
        const SizedBox(height: 16),
        _buildField(label: 'Email', controller: _emailController, icon: Icons.email_outlined, readOnly: true),
        const SizedBox(height: 16),
        _buildField(label: 'Phone Number', controller: _phoneController, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
      ],
    );
  }

  // ── Step 2: Business Info ───────────────────────────
  Widget _buildStep2BusinessInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField(label: 'Business Name (optional)', controller: _businessNameController, icon: Icons.business_outlined),
        const SizedBox(height: 16),
        _buildField(label: 'Bio / Description', controller: _bioController, icon: Icons.description_outlined, maxLines: 4),
        const SizedBox(height: 20),
        // Years of experience
        Text('Years of Experience', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(11, (i) {
            final selected = _yearsExperience == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _yearsExperience = i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      i == 10 ? '10+' : '$i',
                      style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.grey.shade700),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        // Service radius
        Text('Service Radius: ${_serviceRadius.toInt()} km', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        Slider(
          value: _serviceRadius,
          min: 5,
          max: 50,
          divisions: 9,
          label: '${_serviceRadius.toInt()} km',
          activeColor: AppColors.primary,
          onChanged: (v) => setState(() => _serviceRadius = v),
        ),
      ],
    );
  }

  // ── Step 3: Select Categories ───────────────────────
  Widget _buildStep3Categories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What services do you offer?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        Text('Select all that apply', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ServiceCategories.all.map((cat) {
            final selected = _selectedCategories.contains(cat.name);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedCategories.remove(cat.name);
                    _offerings.remove(cat.name);
                  } else {
                    _selectedCategories.add(cat.name);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? cat.color.withValues(alpha: 0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? cat.color.shade600 : Colors.grey.shade300, width: selected ? 2 : 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 20, color: selected ? cat.color.shade700 : Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(cat.name, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? cat.color.shade800 : Colors.grey.shade700)),
                    if (selected) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle, size: 18, color: cat.color.shade600),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 4: Pricing per category ────────────────────
  Widget _buildStep4Pricing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set your prices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        Text('Add at least one service per category', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 20),
        ..._selectedCategories.map((catName) {
          final cat = ServiceCategories.getByName(catName);
          final offerings = _offerings.putIfAbsent(catName, () => [_ServiceOffering()]);
          return _buildCategoryPricing(catName, cat, offerings);
        }),
      ],
    );
  }

  Widget _buildCategoryPricing(String catName, ServiceCategory? cat, List<_ServiceOffering> offerings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cat?.icon ?? Icons.handyman, size: 22, color: cat?.color.shade600 ?? Colors.blue),
              const SizedBox(width: 10),
              Text(catName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...offerings.asMap().entries.map((entry) {
            final i = entry.key;
            final o = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  _buildField(label: 'Service Name', controller: o.titleController, icon: Icons.build_outlined),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: o.pricingType,
                          decoration: InputDecoration(
                            labelText: 'Pricing',
                            labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'FIXED', child: Text('Fixed Price')),
                            DropdownMenuItem(value: 'HOURLY', child: Text('Per Hour')),
                            DropdownMenuItem(value: 'NEGOTIABLE', child: Text('Negotiable')),
                          ],
                          onChanged: (v) => setState(() => o.pricingType = v ?? 'NEGOTIABLE'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: o.priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Price (KES)',
                            labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (offerings.length > 1)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => offerings.removeAt(i)),
                        child: Text('Remove', style: TextStyle(color: Colors.red.shade600, fontSize: 12)),
                      ),
                    ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => offerings.add(_ServiceOffering())),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add another service'),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Location ────────────────────────────────
  Widget _buildStep5Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your service location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        Text('This helps customers find you nearby', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        // GPS capture button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _locationLoading ? null : _captureLocation,
            icon: _locationLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location, size: 20),
            label: Text(_latitude != null ? 'Location Captured' : 'Capture Current Location'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: _latitude != null ? Colors.green.shade400 : Colors.grey.shade300),
              foregroundColor: _latitude != null ? Colors.green.shade700 : AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (_latitude != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GPS Coordinates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green.shade800)),
                      Text('${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_locationError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_locationError!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Shared widgets ──────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildBottomButton() {
    final isLastStep = _currentStep == 4;
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : (isLastStep ? _submit : () => setState(() => _currentStep++)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isLastStep ? 'Submit Registration' : 'Continue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _ServiceOffering {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String pricingType = 'NEGOTIABLE';

  double get price {
    final v = double.tryParse(priceController.text) ?? 0;
    return v;
  }
}
