import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:qr_flutter/qr_flutter.dart';

/// Generates QR code PNG bytes for use in PDF export.
class QRCodeUtils {
  static Future<Uint8List?> generateQRCodePNG({
    required String data,
    required double size,
    ui.Color? color,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        dataModuleStyle: QrDataModuleStyle(
          color: color ?? const ui.Color(0xFF000000),
        ),
        gapless: true,
      );

      painter.paint(canvas, ui.Size(size, size));

      final picture = recorder.endRecording();
      final image =
          await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(
          format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      picture.dispose();
      image.dispose();

      return pngBytes;
    } catch (e) {
      // ignore: avoid_print
      print('[QRCodeUtils] PNG generation failed: $e');
      return null;
    }
  }
}
