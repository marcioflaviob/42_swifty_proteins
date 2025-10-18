import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

/// Service for sharing images of 3D protein models.
///
/// Usage patterns:
/// - shareImageBytes(bytes): when you already captured a widget to PNG bytes
/// - shareDataUrl(dataUrl): when a WebView returned a data URL (e.g. canvas.toDataURL)
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// Shares a PNG image represented as raw bytes.
  Future<void> shareImageBytes(
    Uint8List pngBytes, {
    String fileName = 'protein.png',
    String? subject,
    String? text,
  }) async {
    try {
      // Write to a temporary file so it behaves like a regular image in the share sheet
      final Directory tmp = await Directory.systemTemp.createTemp(
        'protein_share_',
      );
      final String filePath = '${tmp.path}/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      final xfile = XFile(file.path, mimeType: 'image/png', name: fileName);
      await Share.shareXFiles([xfile], subject: subject, text: text);
    } catch (e) {
      throw Exception('Failed to share image: $e');
    }
  }

  /// Accepts a data URL string like "data:image/png;base64,..." and shares it as an image.
  Future<void> shareDataUrl(
    String dataUrl, {
    String fileName = 'protein.png',
    String? subject,
    String? text,
  }) async {
    try {
      final Uint8List bytes = _decodeDataUrlToBytes(dataUrl);
      await shareImageBytes(
        bytes,
        fileName: fileName,
        subject: subject,
        text: text,
      );
    } catch (e) {
      throw Exception('Failed to share data URL image: $e');
    }
  }

  Uint8List _decodeDataUrlToBytes(String dataUrl) {
    final RegExp regex = RegExp(r'^data:image/[^;]+;base64,(.*)');
    final match = regex.firstMatch(dataUrl);
    final String base64Part = match != null ? match.group(1)! : dataUrl;
    return base64.decode(base64Part);
  }
}
