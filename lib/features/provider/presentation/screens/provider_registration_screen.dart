import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
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

  // Step 0 — Basic Info
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  // Step 1 — Category
  String? _selectedCategory;

  // Step 2 — Profile Photo
  Uint8List? _profilePhotoBytes;
  String? _profilePhotoName;
  String? _profilePhotoUrl;
  String? _profilePhotoPublicId;

  // Step 3 — Portfolio Photos
  final List<Uint8List> _portfolioPhotoBytes = [];
  final List<Map<String, String>> _portfolioData = [];

  // Step 4 — Verification Documents
  final List<_VerificationDoc> _verificationDocs = [];

  // Step 5 — Location
  double? _latitude;
  double? _longitude;
  String? _locationError;
  bool _locationBlocked = false;
  bool _locationLoading = false;

  bool _initialized = false;

  static const int _minPortfolioPhotos = 3;
  static const int _maxPortfolioPhotos = 10;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = ref.read(authProvider).user;
      _nameController = TextEditingController(text: user?.name ?? '');
      _emailController = TextEditingController(text: user?.email ?? '');
      _phoneController = TextEditingController(text: user?.phone ?? '');
      _bioController = TextEditingController();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ── Image Upload ──────────────────────────────────────
  Future<Map<String, String>?> _uploadImage(Uint8List bytes, String filename, String folder) async {
    try {
      final api = ref.read(apiClientProvider);
      final dio = api.dio;

      final ext = filename.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(mime),
        ),
        'folder': folder,
      });

      final response = await dio.post(
        '${Endpoints.baseUrl}${Endpoints.fileUpload}',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final payload = data is Map<String, dynamic> ? data['data'] : data;
        if (payload is Map<String, dynamic>) {
          return {
            'url': payload['url']?.toString() ?? '',
            'publicId': payload['publicId']?.toString() ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Upload failed: $e');
      return null;
    }
  }

  // ── Pick Images ──────────────────────────────────────
  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _profilePhotoBytes = bytes;
        _profilePhotoName = picked.name;
      });
    }
  }

  Future<void> _pickPortfolioPhoto() async {
    if (_portfolioPhotoBytes.length >= _maxPortfolioPhotos) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _portfolioPhotoBytes.add(bytes));
    }
  }

  Future<void> _pickVerificationDoc(String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 2048, maxHeight: 2048, imageQuality: 90);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _verificationDocs.add(_VerificationDoc(type: type, bytes: bytes, name: picked.name));
      });
    }
  }

  // ── Location ──────────────────────────────────────────
  Future<void> _captureLocation() async {
    setState(() { _locationLoading = true; _locationBlocked = false; });
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
        setState(() { _locationError = 'Location access is blocked. Enable it in your device settings'; _locationBlocked = true; _locationLoading = false; });
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        ),
      ).timeout(const Duration(seconds: 20));
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

  Future<void> _openLocationSettings() async {
    if (kIsWeb) {
      // Browsers can't be deep-linked; retry so the browser prompt appears.
      setState(() { _locationBlocked = false; _locationError = null; });
      await _captureLocation();
      return;
    }
    await Geolocator.openAppSettings();
    setState(() { _locationBlocked = false; _locationError = null; });
    await _captureLocation();
  }

  // ── Submit ────────────────────────────────────────────
  Future<void> _submit() async {
    if (_selectedCategory == null) {
      _showError('Please select the service you offer');
      return;
    }
    if (_portfolioPhotoBytes.length < _minPortfolioPhotos) {
      _showError('Upload at least $_minPortfolioPhotos portfolio photos so customers can see your work');
      return;
    }
    if (_verificationDocs.isEmpty) {
      _showError('Please upload a photo of your National ID so we can verify your identity');
      return;
    }
    if (_bioController.text.trim().isEmpty) {
      _showError('Tell customers a little about yourself');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      _portfolioData.clear();
      _profilePhotoUrl = null;
      _profilePhotoPublicId = null;

      // Upload profile photo
      if (_profilePhotoBytes != null) {
        final result = await _uploadImage(_profilePhotoBytes!, _profilePhotoName ?? 'profile.jpg', 'profile');
        if (result != null) {
          _profilePhotoUrl = result['url'];
          _profilePhotoPublicId = result['publicId'];
        }
      }

      // Upload portfolio photos
      for (var i = 0; i < _portfolioPhotoBytes.length; i++) {
        final result = await _uploadImage(_portfolioPhotoBytes[i], 'portfolio_${i + 1}.jpg', 'portfolio');
        if (result != null) {
          _portfolioData.add({'imageUrl': result['url']!, 'publicId': result['publicId']!});
        }
      }

      // Upload verification docs
      final verificationData = <Map<String, String>>[];
      for (final doc in _verificationDocs) {
        final result = await _uploadImage(doc.bytes, doc.name, 'documents');
        if (result != null) {
          verificationData.add({
            'documentType': doc.type,
            'imageUrl': result['url']!,
            'publicId': result['publicId']!,
          });
        }
      }

      // Submit registration
      final api = ref.read(apiClientProvider);
      final response = await api.post(
        Endpoints.providerRegister,
        data: {
          'bio': _bioController.text.trim(),
          'categoryId': _selectedCategory,
          'profileImageUrl': _profilePhotoUrl,
          'profileImagePublicId': _profilePhotoPublicId,
          'portfolioImages': _portfolioData,
          'verificationDocuments': verificationData,
          'latitude': _latitude,
          'longitude': _longitude,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          final currentUser = ref.read(authProvider).user;
          if (currentUser != null) {
            ref.read(authProvider.notifier).updateUser(currentUser.copyWith(
              avatar: _profilePhotoUrl ?? currentUser.avatar,
              providerRegistered: true,
            ));
          }
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Become a Provider'),
        leading: _isSubmitting
            ? const SizedBox.shrink()
            : _currentStep > 0
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
          _buildProgressBar(),
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
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final steps = ['Category', 'Photo', 'Portfolio', 'Verify', 'Location'];
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
                    if (i > 0) Expanded(child: Container(height: 2, color: isDone ? AppColors.primary : Colors.grey.shade300)),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone || isActive ? AppColors.primary : Colors.grey.shade300,
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
      case 0: return _buildStepCategory();
      case 1: return _buildStepProfilePhoto();
      case 2: return _buildStepPortfolio();
      case 3: return _buildStepVerification();
      case 4: return _buildStepLocation();
      default: return const SizedBox();
    }
  }

  // ── Step 0: Select Category ──────────────────────────
  Widget _buildStepCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What service do you offer?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        Text('Choose one category. One provider = one service.', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ServiceCategories.all.map((cat) {
            final selected = _selectedCategory == cat.name;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? cat.color.withValues(alpha: 0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? cat.color.shade600 : Colors.grey.shade300,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 22, color: selected ? cat.color.shade700 : Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(cat.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? cat.color.shade800 : Colors.grey.shade700)),
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

  // ── Step 1: Profile Photo ────────────────────────────
  Widget _buildStepProfilePhoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile Photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        Text('This appears on your profile, search results, and booking pages.', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 32),
        Center(
          child: GestureDetector(
            onTap: _pickProfilePhoto,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: _profilePhotoBytes != null
                  ? ClipOval(child: Image.memory(_profilePhotoBytes!, fit: BoxFit.cover))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('Add Photo', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text('JPG or PNG, max 5 MB', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ),
        if (_profilePhotoBytes != null) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _pickProfilePhoto,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Change Photo'),
            ),
          ),
        ],
      ],
    );
  }

  // ── Step 2: Portfolio Photos ─────────────────────────
  Widget _buildStepPortfolio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Work Portfolio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        Text('Show your best work. Customers trust photos.', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        Text('$_minPortfolioPhotos minimum, $_maxPortfolioPhotos maximum',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        const SizedBox(height: 16),
        // Example photos showing before/during/after
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Example: Show the transformation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade800)),
              const SizedBox(height: 4),
              Text('Upload photos of your completed work — before, during, and after', style: TextStyle(fontSize: 12, color: Colors.blue.shade600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _examplePhoto('assets/images/before.png', 'Before'),
                  const SizedBox(width: 8),
                  _examplePhoto('assets/images/during.png', 'During'),
                  const SizedBox(width: 8),
                  _examplePhoto('assets/images/after.png', 'After'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: _portfolioPhotoBytes.length + 1,
          itemBuilder: (context, index) {
            if (index == _portfolioPhotoBytes.length) {
              if (_portfolioPhotoBytes.length >= _maxPortfolioPhotos) return const SizedBox();
              return GestureDetector(
                onTap: _pickPortfolioPhoto,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey.shade400),
                      const SizedBox(height: 4),
                      Text('Add', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              );
            }
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_portfolioPhotoBytes[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _portfolioPhotoBytes.removeAt(index)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (_portfolioPhotoBytes.isNotEmpty && _portfolioPhotoBytes.length < _minPortfolioPhotos) ...[
          const SizedBox(height: 12),
          Text('${_minPortfolioPhotos - _portfolioPhotoBytes.length} more photos needed',
              style: TextStyle(fontSize: 13, color: Colors.orange.shade700, fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }

  Widget _examplePhoto(String asset, String label) {
    return Expanded(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(asset, height: 80, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  // ── Step 3: Verification Documents ───────────────────
  Widget _buildStepVerification() {
    final nationalIdDoc = _verificationDocs.cast<_VerificationDoc?>().firstWhere((d) => d?.type == 'National ID', orElse: () => null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verify Your Identity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        Text('We need a clear photo of your National ID to verify you as a real provider.', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 20),
        if (nationalIdDoc == null) ...[
          // Show placeholder example of what a National ID looks like
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Text('Example: What to upload', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade800)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/n_id.png', height: 160, fit: BoxFit.contain),
                ),
                const SizedBox(height: 10),
                Text('Front of your Kenyan National ID card', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tips for a good photo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tips for a clear photo:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                const SizedBox(height: 8),
                _tipRow('Place your ID on a dark, flat surface'),
                _tipRow('Make sure all text is readable and not cut off'),
                _tipRow('Avoid glare — no flash needed'),
                _tipRow('Both the photo and ID number must be visible'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Upload button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickVerificationDoc('National ID'),
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text('Take Photo or Choose from Gallery'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ] else ...[
          // Uploaded — show preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(nationalIdDoc.bytes, fit: BoxFit.contain, width: double.infinity, height: 200),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('National ID uploaded successfully', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green.shade800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () => _pickVerificationDoc('National ID'),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retake Photo'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _tipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 14, color: Colors.green.shade600),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
        ],
      ),
    );
  }

  // ── Step 4: Location ────────────────────────────────
  Widget _buildStepLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your service location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        Text('This helps customers find you nearby', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        // Bio
        TextField(
          controller: _bioController,
          maxLines: 3,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Tell customers about yourself...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 24),
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
          if (_locationBlocked) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _openLocationSettings,
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Open settings'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  // ── Bottom Button ────────────────────────────────────
  Widget _buildBottomButton() {
    final isLastStep = _currentStep == 4;
    bool canProceed = false;
    switch (_currentStep) {
      case 0: canProceed = _selectedCategory != null;
      case 1: canProceed = true;
      case 2: canProceed = true;
      case 3: canProceed = _verificationDocs.isNotEmpty;
      case 4: canProceed = true;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_isSubmitting || !canProceed) ? null : (isLastStep ? _submit : () => setState(() => _currentStep++)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(
                  isLastStep ? 'Submit Registration' : 'Continue',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}

class _VerificationDoc {
  final String type;
  final Uint8List bytes;
  final String name;
  const _VerificationDoc({required this.type, required this.bytes, required this.name});
}
