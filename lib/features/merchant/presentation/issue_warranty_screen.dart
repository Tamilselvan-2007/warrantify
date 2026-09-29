import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_providers.dart';

class IssueWarrantyScreen extends ConsumerStatefulWidget {
  const IssueWarrantyScreen({super.key});

  @override
  ConsumerState<IssueWarrantyScreen> createState() => _IssueWarrantyScreenState();
}

class _IssueWarrantyScreenState extends ConsumerState<IssueWarrantyScreen> {
  int _currentStep = 0;
  bool _loading = false;
  String? _errorMessage;

  final _customerEmailController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _yearsController = TextEditingController();

  String? _businessId;
  String? _businessCategory;
  List<Map<String, dynamic>> _services = [];
  Map<String, dynamic>? _selectedService;

  @override
  void initState() {
    super.initState();
    _loadBusinessAndServices();
  }

  Future<void> _loadBusinessAndServices() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final business = await Supabase.instance.client
        .from('businesses')
        .select('id, category')
        .eq('user_id', userId)
        .maybeSingle();

    if (business == null || !mounted) return;

    setState(() {
      _businessId = business['id'];
      _businessCategory = business['category'];
    });

    final services = await Supabase.instance.client
        .from('business_services')
        .select('id, service_name, default_warranty_years')
        .eq('business_id', _businessId!);

    if (mounted) {
      setState(() => _services = List<Map<String, dynamic>>.from(services));
    }
  }

  void _onServiceSelected(Map<String, dynamic>? service) {
    setState(() {
      _selectedService = service;
      if (service != null) {
        _yearsController.text = service['default_warranty_years'].toString();
      }
    });
  }

  Future<bool> _confirmPermanentUpdateIfChanged() async {
    if (_selectedService == null) return true;

    final enteredYears = double.tryParse(_yearsController.text.trim());
    final defaultYears = (_selectedService!['default_warranty_years'] as num).toDouble();

    if (enteredYears == null || enteredYears == defaultYears) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update default warranty period?'),
        content: Text(
          'Update the default warranty period for "${_selectedService!['service_name']}" '
          'to $enteredYears years for all future warranties?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, just this one'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, update default'),
          ),
        ],
      ),
    );

    if (result == true) {
      await Supabase.instance.client
          .from('business_services')
          .update({'default_warranty_years': enteredYears})
          .eq('id', _selectedService!['id']);
    }

    return true; // proceed with issuance regardless of their popup answer
  }

  Future<void> _submitWarranty() async {
    if (_selectedService == null || _businessId == null) {
      setState(() => _errorMessage = 'Please select a service');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _confirmPermanentUpdateIfChanged();

      final years = double.tryParse(_yearsController.text.trim()) ?? 0;
      final issueDate = DateTime.now();
      final expiryDate = issueDate.add(Duration(days: (years * 365).round()));

      // Try to find an existing customer account by email
      final customerEmail = _customerEmailController.text.trim();
      final existingCustomer = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('email', customerEmail)
          .maybeSingle();

      // Step 1: insert with a temporary unique placeholder (satisfies NOT NULL UNIQUE)
      final tempQrHash = 'pending-${DateTime.now().microsecondsSinceEpoch}';

      final inserted = await Supabase.instance.client
          .from('warranty_cards')
          .insert({
              'business_id': _businessId,
              'customer_user_id': existingCustomer?['id'],
              'customer_email': customerEmail,
              'service_id': _selectedService!['id'],
              'title': _selectedService!['service_name'],
              'category': _businessCategory,
              'serial_number': _serialNumberController.text.trim().isEmpty
                  ? null
                  : _serialNumberController.text.trim(),
              'issue_date': issueDate.toIso8601String().split('T')[0],
              'expiry_date': expiryDate.toIso8601String().split('T')[0],
              'qr_hash': tempQrHash,
              'status': 'active',
          })
          .select('id')
          .single();

      final cardId = inserted['id'] as String;

      // Step 2: call the Edge Function to sign and overwrite qr_hash with the real token
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signWarrantyQr(cardId);// Placeholder qr_hash — real HMAC signing comes in the next stage
      

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Warranty issued successfully')),
        );
        Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Issue Warranty')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _submitWarranty();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                    onPressed: _loading ? null : details.onStepContinue,
                    child: Text(_currentStep == 2
                        ? (_loading ? 'Issuing...' : 'Submit')
                        : 'Next'),
                  ),
              ),
              if (_currentStep > 0) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Back'),
                ),
              ],
            ],
          ),
        );
      },
        steps: [
          Step(
            title: const Text('Customer Details'),
            isActive: _currentStep >= 0,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _customerEmailController,
                  decoration: const InputDecoration(labelText: 'Customer Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _serialNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Serial Number (optional)',
                  ),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Service & Coverage'),
            isActive: _currentStep >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<Map<String, dynamic>>(
                  initialValue: _selectedService,
                  decoration: const InputDecoration(labelText: 'Service'),
                  items: _services.map((service) {
                    return DropdownMenuItem(
                      value: service,
                      child: Text(service['service_name']),
                    );
                  }).toList(),
                  onChanged: _onServiceSelected,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _yearsController,
                  decoration: const InputDecoration(
                    labelText: 'Warranty Period (years)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Review & Submit'),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Customer: ${_customerEmailController.text}'),
                Text('Service: ${_selectedService?['service_name'] ?? '-'}'),
                Text('Coverage: ${_yearsController.text} years'),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}