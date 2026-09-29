import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  File? _pickedLogo;
  String? _existingLogoUrl;
  Color _selectedColor = AppColors.inkNavy;
  bool _loading = false;
  String? _errorMessage;
  String? _businessId;

  final List<Color> _brandColorOptions = const [
    AppColors.inkNavy,
    AppColors.craftAmber,
    AppColors.clinicalTeal,
    AppColors.sealCrimson,
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  Future<void> _loadBusinessProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final business = await Supabase.instance.client
        .from('businesses')
        .select('id, logo_url, contact_json')
        .eq('user_id', userId)
        .maybeSingle();

    if (business != null && mounted) {
      setState(() {
        _businessId = business['id'];
        _existingLogoUrl = business['logo_url'];
        final brandHex = business['contact_json']?['brand_color'] as String?;
        if (brandHex != null) {
          _selectedColor = Color(int.parse(brandHex, radix: 16));
        }
      });
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _pickedLogo = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (_businessId == null) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      String? logoUrl = _existingLogoUrl;

      if (_pickedLogo != null) {
        final path = '$userId/logo.png';
        await Supabase.instance.client.storage
            .from('business-logos')
            .upload(path, _pickedLogo!, fileOptions: const FileOptions(upsert: true));
        logoUrl = Supabase.instance.client.storage
            .from('business-logos')
            .getPublicUrl(path);
      }

      final colorHex = _selectedColor.toARGB32().toRadixString(16).padLeft(8, '0');

      await Supabase.instance.client.from('businesses').update({
        'logo_url': logoUrl,
        'contact_json': {'brand_color': colorHex},
      }).eq('id', _businessId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business profile updated')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Business Logo', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickLogo,
              child: Container(
                height: 140,
                width: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate.withValues(alpha: 0.3)),
                ),
                child: _pickedLogo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_pickedLogo!, fit: BoxFit.cover),
                      )
                    : (_existingLogoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(_existingLogoUrl!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined, size: 40)),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Brand Color', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: _brandColorOptions.map((color) {
                final isSelected = color.toARGB32() == _selectedColor.toARGB32();
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: _loading ? null : _saveProfile,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_loading ? 'Saving...' : 'Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}