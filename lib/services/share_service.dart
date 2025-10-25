import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

/// Service for sharing images of 3D protein models.
///
/// Usage patterns:
/// - shareImageBytes(bytes): when you already captured a widget to PNG bytes
/// - shareDataUrl(dataUrl): when a WebView returned a data URL (e.g. canvas.toDataURL)
/// - saveToGallery(bytes): saves directly to photo gallery (iOS/Android)
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

  /// Saves a PNG image directly to the device's photo gallery.
  /// This is the recommended method for iOS to ensure the image appears in Photos app.
  /// Works on both iOS and Android.
  Future<void> saveToGallery(
    Uint8List pngBytes, {
    String fileName = 'protein.png',
  }) async {
    try {
      // Create a temporary file
      final Directory tmp = await Directory.systemTemp.createTemp(
        'protein_save_',
      );
      final String filePath = '${tmp.path}/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Save to gallery using gal package
      await Gal.putImage(file.path, album: 'Swifty Proteins');
      
      // Clean up temp file
      await file.delete();
      await tmp.delete();
    } catch (e) {
      throw Exception('Failed to save image to gallery: $e');
    }
  }

  /// Saves a data URL image directly to the device's photo gallery.
  Future<void> saveDataUrlToGallery(
    String dataUrl, {
    String fileName = 'protein.png',
  }) async {
    try {
      final Uint8List bytes = _decodeDataUrlToBytes(dataUrl);
      await saveToGallery(bytes, fileName: fileName);
    } catch (e) {
      throw Exception('Failed to save data URL image to gallery: $e');
    }
  }

  /// Provides both share and save options. 
  /// On iOS, this gives users the option to save to Photos via the share sheet,
  /// but for a better UX, consider using saveToGallery() directly.
  Future<void> shareWithSaveOption(
    Uint8List pngBytes, {
    String fileName = 'protein.png',
    String? subject,
    String? text,
    bool alsoSaveToGallery = false,
  }) async {
    try {
      // Optionally save to gallery first
      if (alsoSaveToGallery) {
        await saveToGallery(pngBytes, fileName: fileName);
      }
      
      // Then share
      await shareImageBytes(
        pngBytes,
        fileName: fileName,
        subject: subject,
        text: text,
      );
    } catch (e) {
      throw Exception('Failed to share/save image: $e');
    }
  }
}
