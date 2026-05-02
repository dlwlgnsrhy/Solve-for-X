import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:origin/core/theme/app_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Card showing a document stamp with date, title, score ring, and share.
class StampCard extends StatelessWidget {
  final DateTime date;
  final String title;
  final int characters;
  final double score;
  final String sessionId;
  final String userId;

  const StampCard({
    super.key,
    required this.date,
    required this.title,
    required this.characters,
    required this.score,
    this.sessionId = '',
    this.userId = '',
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

          // Share button
          IconButton(
            onPressed: () => _sharePDF(context),
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

  Future<void> _sharePDF(BuildContext context) async {
    try {
      // Generate PDF certificate
      final pdfDoc = pw.Document();

      pdfDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
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
                        pw.Text('$score',
                            style: pw.TextStyle(
                                fontSize: 28,
                                fontWeight: pw.FontWeight.bold,
                                color: const PdfColor.fromInt(0x00FF66))),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Date',
                            style: pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey600)),
                        pw.Text(_formatDateISO(date),
                            style: pw.TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text('Session ID',
                    style: pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600)),
                pw.Text(sessionId.isEmpty ? '—' : sessionId,
                    style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 8),
                pw.Text('User ID',
                    style: pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600)),
                pw.Text(userId.isEmpty ? '—' : userId,
                    style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 8),
                pw.Text('Characters',
                    style: pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600)),
                pw.Text(characters.toString(),
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            );
          },
        ),
      );

      // Generate PDF bytes
      final pdfBytes = await pdfDoc.save();
      final uint8List = pdfBytes.buffer.asUint8List();

      // Share via share_plus
      await Share.shareXFiles(
        [XFile.fromData(
          uint8List,
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
