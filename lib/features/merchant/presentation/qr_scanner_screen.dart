import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../auth/data/auth_providers.dart';
import '../../../core/theme/app_colors.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final _manualController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  bool _scannerLocked = false;

  @override
  void dispose() {
    _scannerController.stop();
    _scannerController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _verify(String qrHash) async {
    if (_loading || !mounted) return;
    setState(() {
      _loading = true;
      _result = null;
      _scannerLocked = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.verifyWarrantyQr(qrHash);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _result = {'valid': false, 'reason': e.toString()});
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    if (!mounted) return;
    setState(() {
      _result = null;
      _scannerLocked = false;
      _manualController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Warranty'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await _scannerController.stop();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 300,
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                if (_scannerLocked || !mounted) return;
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  _verify(barcodes.first.rawValue!);
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text('Or paste a QR token manually:',
                style: TextStyle(fontSize: 12, color: AppColors.slate)),
          ),
          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24),
  child: Row(
    children: [
      Expanded(
        flex: 3,
        child: TextField(
          controller: _manualController,
          decoration: const InputDecoration(labelText: 'qr_hash'),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 1,
        child: ElevatedButton(
          onPressed: _loading
              ? null
              : () => _verify(_manualController.text.trim()),
          child: const Text('Check'),
        ),
      ),
    ],
  ),
),
          const SizedBox(height: 16),
          if (_loading) const CircularProgressIndicator(),
          if (_result != null) _buildResultCard(),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final valid = _result!['valid'] == true;
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          color: valid ? AppColors.clinicalTeal.withValues(alpha: 0.1) : AppColors.sealCrimson.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(valid ? Icons.check_circle : Icons.cancel,
                        color: valid ? AppColors.clinicalTeal : AppColors.sealCrimson),
                    const SizedBox(width: 8),
                    Text(valid ? 'Valid Warranty' : 'Invalid',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 12),
                if (valid) ...[
                  Text('Title: ${_result!['card']['title']}'),
                  Text('Status: ${_result!['card']['status']}'),
                  Text('Customer: ${_result!['card']['customer_email']}'),
                  Text('Issued: ${_result!['card']['issue_date']}'),
                  Text('Expires: ${_result!['card']['expiry_date']}'),
                  if (_result!['card']['serial_number'] != null)
                    Text('Serial: ${_result!['card']['serial_number']}'),
                ] else
                  Text('Reason: ${_result!['reason']}'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _reset, child: const Text('Scan Another')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}