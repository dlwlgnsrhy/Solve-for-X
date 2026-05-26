import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:origin/core/theme/app_theme.dart';
import 'package:origin/features/origin_stamp/domain/models/qr_verification_data.dart';

import '../../../../core/services/ed25519_key_manager.dart';

/// Screen that scans QR codes and verifies stamp signatures.
class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  MobileScannerController controller = MobileScannerController();
  bool _isLoading = true;
  bool _verificationSuccess = false;
  String _status = '';
  QRVerificationData? _parsedData;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture barcodes) async {
    setState(() => _isLoading = true);
    await controller.stop();

    final barcode = barcodes.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) {
      setState(() {
        _isLoading = false;
        _status = 'No data found in QR code.';
        _verificationSuccess = false;
      });
      return;
    }

    try {
      final rawData = barcode.rawValue!;
      QRVerificationData data;
      try {
        data = QRVerificationData.fromJsonString(rawData);
      } catch (e) {
        setState(() {
          _isLoading = false;
          _status = 'Invalid QR data format.';
          _verificationSuccess = false;
        });
        return;
      }

      if (data.signature.isEmpty || data.contentHash.isEmpty) {
        setState(() {
          _isLoading = false;
          _status = 'QR is missing required fields.';
          _verificationSuccess = false;
        });
        return;
      }

      final isValid = await _verify(data);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _parsedData = data;
          _verificationSuccess = isValid;
          _status = isValid
              ? 'Verified Original by Human'
              : 'Verification Failed';
        });
      }
    } catch (e) {
      debugPrint('[VerifyPage] Scan error: $e');
      setState(() {
        _isLoading = false;
        _verificationSuccess = false;
        _status = 'Scan failed.';
      });
    }
  }

  Future<bool> _verify(QRVerificationData data) async {
    try {
      final signatureBytes = List.generate(
        data.signature.length ~/ 2,
        (i) => int.parse(
              data.signature.substring(i * 2, i * 2 + 2),
              radix: 16,
            ),
      );

      final signedPayload =
          '${data.contentHash}:${data.score}:${data.timestamp}';
      final messageBytes = utf8.encode(signedPayload);

      final result = await globalEd25519KeyManager.verifySignature(
        messageBytes: messageBytes,
        signatureBytes: signatureBytes,
      );

      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Stamp'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColor.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _verificationSuccess || _status.contains('Failed')
                ? _buildResultView(style)
                : _buildScannerView(style),
      ),
    );
  }

  Widget _buildScannerView(ThemeData style) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Point your camera at a stamp QR code',
              textAlign: TextAlign.center,
              style: style.textTheme.headlineMedium!.copyWith(
                color: AppColor.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 250,
              height: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  controller: controller,
                  onDetect: _handleBarcode,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scanning...',
              style: TextStyle(color: AppColor.neonGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(ThemeData style) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_verificationSuccess) ..._buildSuccessView(style) else ..._buildFailView(style),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.cardBg,
                foregroundColor: AppColor.neonGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _resumeScanning,
              child: const Text('Scan Again'),
            ).animate().fadeIn(duration: 300.ms, delay: 600.ms),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSuccessView(ThemeData style) => [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColor.neonGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: AppColor.neonGreen,
          ),
        ).animate().scale(
              duration: 500.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 24),
        Text(
          'Verified Original by Human',
          style: style.textTheme.headlineSmall!.copyWith(
            color: AppColor.neonGreen,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
        const SizedBox(height: 8),
        Text(
          'This stamp was cryptographically verified.',
          style: style.textTheme.bodyMedium!.copyWith(
            color: AppColor.textSecondary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
        if (_parsedData != null) ...[
          const SizedBox(height: 32),
          _buildVerifiedInfo(style),
        ],
      ];

  List<Widget> _buildFailView(ThemeData style) => [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cancel_rounded,
            size: 64,
            color: Colors.red,
          ),
        ).animate().scale(
              duration: 500.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 24),
        Text(
          'Verification Failed',
          style: style.textTheme.headlineSmall!.copyWith(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
      ];

  Widget _buildVerifiedInfo(ThemeData style) {
    final data = _parsedData!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Score', data.score.toStringAsFixed(2), style),
          const SizedBox(height: 8),
          _infoRow('Date Data', data.timestamp, style),
          const SizedBox(height: 8),
          _infoRow('Content Hash', data.contentHash.length > 16
              ? '${data.contentHash.substring(0, 16)}...'
              : data.contentHash, style),
          const SizedBox(height: 8),
          _infoRow('Signer', data.userId.isEmpty ? '\u2013' : data.userId, style),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeData style) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: style.textTheme.bodySmall!.copyWith(
              color: AppColor.textDim,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: style.textTheme.bodyMedium!.copyWith(
              color: AppColor.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _resumeScanning() {
    setState(() {
      _isLoading = true;
      _status = '';
      _verificationSuccess = false;
      _parsedData = null;
    });
    controller.start();
  }
}
