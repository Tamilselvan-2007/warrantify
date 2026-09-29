import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_providers.dart';

class ServiceRow {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController yearsController = TextEditingController();
}

class BusinessSignupScreen extends ConsumerStatefulWidget {
  const BusinessSignupScreen({super.key});

  @override
  ConsumerState<BusinessSignupScreen> createState() => _BusinessSignupScreenState();
}

class _BusinessSignupScreenState extends ConsumerState<BusinessSignupScreen> {
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  String? _selectedCategory;
  final List<ServiceRow> _serviceRows = [ServiceRow()];

  bool _otpSent = false;
  bool _loading = false;
  String? _errorMessage;

  void _addServiceRow() {
    setState(() => _serviceRows.add(ServiceRow()));
  }

  void _removeServiceRow(int index) {
    if (_serviceRows.length == 1) return;
    setState(() => _serviceRows.removeAt(index));
  }

  // Stage 1: create the account only, send OTP
  Future<void> _submitSignup() async {
    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Please select a category');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signUp(
        email: _businessEmailController.text.trim(),
        password: _passwordController.text,
        role: 'merchant',
      );
      setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // Stage 2: verify OTP, THEN create businesses + business_services
  Future<void> _verifyAndCreateBusiness() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);

      final response = await authRepo.verifySignupOtp(
        email: _businessEmailController.text.trim(),
        token: _otpController.text.trim(),
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('Verification succeeded but no user ID returned.');
      }

      final businessResponse = await Supabase.instance.client
          .from('businesses')
          .insert({
            'user_id': userId,
            'business_name': _businessNameController.text.trim(),
            'category': _selectedCategory,
            'address': _addressController.text.trim(),
            'contact_number': _contactNumberController.text.trim(),
            'business_email': _businessEmailController.text.trim(),
          })
          .select()
          .single();

      final businessId = businessResponse['id'];

      final serviceInserts = _serviceRows
          .where((row) => row.nameController.text.trim().isNotEmpty)
          .map((row) => {
                'business_id': businessId,
                'service_name': row.nameController.text.trim(),
                'default_warranty_years':
                    double.tryParse(row.yearsController.text.trim()) ?? 0,
              })
          .toList();

      if (serviceInserts.isNotEmpty) {
        await Supabase.instance.client
            .from('business_services')
            .insert(serviceInserts);
      }

      // Next screen is Plan Page — wired in a later step
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _businessNameController,
              decoration: const InputDecoration(labelText: 'Business Name'),
              enabled: !_otpSent,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'dental', child: Text('Dental')),
                DropdownMenuItem(value: 'furniture', child: Text('Furniture')),
              ],
              onChanged: _otpSent
                  ? null
                  : (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              enabled: !_otpSent,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contactNumberController,
              decoration: const InputDecoration(labelText: 'Contact Number'),
              keyboardType: TextInputType.phone,
              enabled: !_otpSent,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _businessEmailController,
              decoration: const InputDecoration(labelText: 'Business Email'),
              keyboardType: TextInputType.emailAddress,
              enabled: !_otpSent,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              enabled: !_otpSent,
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Services You Offer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 8),
            ..._serviceRows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: row.nameController,
                        decoration:
                            const InputDecoration(labelText: 'Service Name'),
                        enabled: !_otpSent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: row.yearsController,
                        decoration: const InputDecoration(labelText: 'Years'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        enabled: !_otpSent,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _otpSent ? null : () => _removeServiceRow(index),
                    ),
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _otpSent ? null : _addServiceRow,
                icon: const Icon(Icons.add),
                label: const Text('Add another service'),
              ),
            ),
            const SizedBox(height: 16),
            if (_otpSent)
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : (_otpSent ? _verifyAndCreateBusiness : _submitSignup),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_loading
                    ? 'Please wait...'
                    : (_otpSent ? 'Verify & Sign Up' : 'Sign Up')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}