import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:origin/core/services/ed25519_key_manager.dart';
import 'package:origin/core/theme/app_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Card showing a document stamp with date, title, score ring, and share.
class StampCard extends StatelessWidget {
  final DateTime date;
  final String title;
  final int characters;
  final double score;
  final String sessionId;
  final String userId;
  final double rhythmEntropy;
  final int keystrokeEventCount;
  final String contentHash;

  const StampCard({
    super.key,
    required this.date,
    required this.title,
    required this.characters,
    required this.score,
    this.sessionId = '',
    this.userId = '',
    this.rhythmEntropy = 0.0,
    this.keystrokeEventCount = 0,
    this.contentHash = '',
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.divider),
      ),
      child: Row(
        children: [
          // Score ring
          SizedBox(
            width: 56,
            height: 56,
            child: CustomPaint(
              size: const Size(56, 56),
              painter: _ScoreRingPainter(score),
            ),
          ),

          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: style.textTheme.titleMedium!.copyWith(
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _formatDate(date),
                      style: style.textTheme.bodySmall!.copyWith(
                        color: AppColor.textDim,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatCharacters(characters),
                      style: style.textTheme.bodySmall!.copyWith(
                        color: AppColor.textDim,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Share button (opens share options)
          IconButton(
            onPressed: () => _showShareOptions(context),
            icon: const Icon(
              Icons.share_rounded,
              size: 20,
              color: AppColor.neonGreen,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColor.neonGreen.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColor.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf,
                    color: AppColor.neonGreen),
                title: const Text('Share as PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _sharePDF(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.code, color: AppColor.neonGreen),
                title: const Text('Share as JSON'),
                onTap: () {
                  Navigator.pop(context);
                  _shareJSON(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sharePDF(BuildContext context) async {
    try {
      final signature = await globalEd25519KeyManager.signData(
        '$contentHash:$score:${date.toIso8601String()}',
      );

      Uint8List? qrImageBytes;
      if (signature != null) {
        final qrJson = jsonEncode({
          'signature': signature,
          'contentHash': contentHash,
          'score': score,
          'timestamp': date.toIso8601String(),
          'userId': userId,
        });
        qrImageBytes = await _generateQRCodePNG(qrJson, 150);
      }

      final pdfDoc = pw.Document();

      pdfDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final children = <pw.Widget>[
              // Title
              pw.Text('ORIGIN',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0x00FF66),
                  )),
              pw.SizedBox(height: 8),
              pw.Text(
                  'Cryptographic Proof of Human Originality',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey500,
                  )),
              pw.Divider(),
              pw.SizedBox(height: 24),

              // Certificate info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Authenticity Score',
                          style: pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey600)),
                      pw.Text(
                        '$score',
                        style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0x00FF66)),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date',
                          style: pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey600)),
                      pw.Text(_formatDateISO(date),
                          style: const pw.TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text('Session ID',
                  style: pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600)),
              pw.Text(
                sessionId.isEmpty ? '\u2014' : sessionId,
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 8),
              pw.Text('User ID',
                  style: pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600)),
              pw.Text(
                userId.isEmpty ? '\u2014' : userId,
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Characters',
                  style: pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600)),
              pw.Text(
                characters.toString(),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ];

            if (qrImageBytes != null) {
              children.add(pw.SizedBox(height: 24));
              children.add(
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('Scan to verify',
                        style: pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey500)),
                    pw.SizedBox(height: 8),
                    pw.Image(
                      pw.MemoryImage(qrImageBytes),
                      width: 150,
                      height: 150,
                    ),
                  ],
                ),
              );
            }

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: children,
            );
          },
        ),
      );

      final pdfBytes = await pdfDoc.save();
      final pdfBytesList = pdfBytes.buffer.asUint8List();

      await Share.shareXFiles(
        [XFile.fromData(
          pdfBytesList,
          name: 'origin_stamp_${date.millisecondsSinceEpoch}.pdf',
          mimeType: 'application/pdf',
        )],
        subject: 'Origin Stamp — Authenticity Certificate',
      );
    } catch (e) {
      debugPrint('[StampCard] Error sharing PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 공유 중 오류: $e'),
            backgroundColor: AppColor.cardBg,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<Uint8List?> _generateQRCodePNG(String data, double size) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        dataModuleStyle: const QrDataModuleStyle(
          color: ui.Color(0xFF000000),
        ),
        gapless: true,
      );

      painter.paint(canvas, ui.Size(size, size));

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      picture.dispose();
      image.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[StampCard] QR PNG generation failed: $e');
      return null;
    }
  }

  Future<void> _shareJSON(BuildContext context) async {
    try {
      final signature = await globalEd25519KeyManager.signData(
        '$contentHash:$score:${date.toIso8601String()}',
      );

      final cert = <String, dynamic>{
        'type': 'origin_stamp',
        'app': 'Origin',
        'package': 'com.sfx.origin',
        'version': '1.0.0',
        'session_id': sessionId,
        'user_id': userId,
        'content_hash': 'sha256:$contentHash',
        'content_length': characters,
        'timestamp': date.toIso8601String(),
        'authenticity_score': score,
        'rhythm_entropy': rhythmEntropy,
        'revision_pattern_score': score,
        'keystroke_event_count': keystrokeEventCount,
        if (signature != null) 'signature': signature,
        'public_key': await globalEd25519KeyManager.getPublicKeyBase64(),
      };

      final jsonString =
          const JsonEncoder.withIndent('  ').convert(cert);

      await Share.share(jsonString,
          subject: 'Origin Stamp — Authentication Certificate');
    } catch (e) {
      debugPrint('[StampCard] Error sharing JSON: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('JSON 공유 중 오류: $e'),
            backgroundColor: AppColor.cardBg,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateISO(DateTime date) {
    return date.toIso8601String().substring(0, 10);
  }

  String _formatCharacters(int chars) {
    if (chars >= 1000) return '${(chars / 1000).toStringAsFixed(1)}k chars';
    return '$chars chars';
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double score;

  _ScoreRingPainter(this.score);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;
    final strokeWidth = 4.0;
    final clampedScore = score.clamp(0.0, 100.0);
    final fraction = clampedScore / 100.0;

    // Background
    final bgPaint = Paint()
      ..color = AppColor.divider.withValues(alpha: 0.4)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    // Score arc (partial ring)
    final scorePaint = Paint()
      ..color = AppColor.neonGreen
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.2832 * fraction,
      false,
      scorePaint,
    );

    // Score text in center
    final textPainter = TextPainter(
      text: TextSpan(
        text: clampedScore.toInt().toString(),
        style: const TextStyle(
          color: AppColor.neonGreen,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
