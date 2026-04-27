import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sfx_imjong_care/core/theme/neon_colors.dart';
import 'package:sfx_imjong_care/core/theme/card_template.dart';
import 'package:sfx_imjong_care/features/will_input/domain/entities/will_card.dart';
import 'package:sfx_imjong_care/features/will_card/presentation/widgets/share_card_content.dart';

class CardShareButton extends StatelessWidget {
  final WillCard card;
  final ScreenshotController screenshotController;
  final CardTemplate template;

  const CardShareButton({
    super.key,
    required this.card,
    required this.screenshotController,
    this.template = CardTemplate.neon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Share button
        Expanded(
          child: _ShareButton(
            card: card,
            template: template,
            screenshotController: screenshotController,
            label: 'SNS 공유',
            icon: Icons.share_outlined,
            color: const Color(0xFF00DDFF),
            borderColor: const Color(0xFF00DDFF).withValues(alpha: 120),
            iconColor: const Color(0xFF00DDFF),
          ),
        ),
        const SizedBox(width: 12),
        // Save to gallery button
        Expanded(
          child: _ShareButton(
            card: card,
            template: template,
            screenshotController: screenshotController,
            label: '갤러리에 저장',
            icon: Icons.image_outlined,
            color: NeonColors.neonPink,
            borderColor: NeonColors.neonPink.withValues(alpha: 120),
            iconColor: NeonColors.neonPink,
            saveOnly: true,
          ),
        ),
      ],
    );
  }
}

class _ShareButton extends StatefulWidget {
  final WillCard card;
  final CardTemplate template;
  final ScreenshotController screenshotController;
  final String label;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final Color iconColor;
  final bool saveOnly;

  const _ShareButton({
    required this.card,
    required this.template,
    required this.screenshotController,
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.iconColor,
    this.saveOnly = false,
  });

  @override
  State<_ShareButton> createState() => __ShareButtonState();
}

class __ShareButtonState extends State<_ShareButton> {
  bool _processing = false;

  String _buildTextShare() {
    return '''${'=' * 35}
  SFX 임종 케어
${'=' * 35}

  ${widget.card.name}

  [MY VALUES]
  ${'▸'} ${widget.card.values[0]}
  ${'▸'} ${widget.card.values[1]}
  ${'▸'} ${widget.card.values[2]}

  [ONE-LINE WILL]
  ${'❝'} ${widget.card.will} ${'❞'}

${'=' * 35}''';
  }

  Future<Uint8List?> _captureCard() async {
    try {
      // Create a new ScreenshotController for capturing the share card
      final controller = ScreenshotController();
      final shareCard = ShareCardContent(card: widget.card, template: widget.template);
      
      final image = await controller.captureFromWidget(
        shareCard,
        pixelRatio: 3.0,
      );
      return image;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToGallery() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final image = await _captureCard();
      if (image != null) {
        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/sfx_will_card_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(image);
        final result = await Share.shareXFiles(
          [XFile(filePath)],
          text: 'SFX 임종 케어 - ${widget.card.name}',
        );
        
        if (mounted && result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '이미지를 저장했습니다.',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
              ),
              backgroundColor: NeonColors.neonPink,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Fallback to text share
        await Share.share(
          _buildTextShare(),
          subject: 'SFX 임종 케어 - ${widget.card.name}',
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '이미지 생성 중 오류가 발생했습니다.',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
            ),
            backgroundColor: const Color(0xFFFF4444),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _shareCard() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final image = await _captureCard();
      if (image != null) {
        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/sfx_will_card_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(image);
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'SFX 임종 케어 - ${widget.card.name}',
        );
      } else {
        // Fallback to text share
        await Share.share(
          _buildTextShare(),
          subject: 'SFX 임종 케어 - ${widget.card.name}',
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '이미지 생성 중 오류가 발생했습니다.',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
            ),
            backgroundColor: const Color(0xFFFF4444),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _processing ? null : (widget.saveOnly ? _saveToGallery : _shareCard),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: _processing
              ? widget.borderColor
              : widget.borderColor,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: _processing
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.color,
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.color,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 16,
                ),
              ],
            ),
    );
  }
}
