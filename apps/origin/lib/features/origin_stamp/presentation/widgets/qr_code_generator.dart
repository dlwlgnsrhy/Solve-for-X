import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:origin/core/theme/app_theme.dart';
import 'package:origin/features/origin_stamp/domain/models/qr_verification_data.dart';

/// QR code widget with "Scan to verify" label beneath it.
class QRCodeGenerator extends StatelessWidget {
  final QRVerificationData data;
  final double size;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const QRCodeGenerator({
    super.key,
    required this.data,
    this.size = 180,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QrImageView(
          data: data.toJsonString(),
          version: QrVersions.auto,
          size: size,
          backgroundColor: backgroundColor ?? Colors.white,
          foregroundColor:
              foregroundColor ?? AppColor.neonGreen,
        ),
        const SizedBox(height: 8),
        Text(
          'Scan to verify',
          style: TextStyle(
            fontSize: 12,
            color: AppColor.textDim,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
