import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

const MethodChannel _platformChannel = MethodChannel('com.example.retiva/widget');

void openUrl(String url) async {
  try {
    await _platformChannel.invokeMethod('openUrl', {'url': url});
  } catch (e) {
    // Graceful fallback
  }
}

void downloadTextOrPdf(String filename, String content, {Uint8List? bytes, String mimeType = 'application/pdf'}) async {
  try {
    await _platformChannel.invokeMethod('saveDownloadedFile', {
      'filename': filename,
      'content': content,
      if (bytes != null) 'bytes': bytes,
    });
  } catch (_) {
    try {
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) {
        final f = File('${dir.path}/$filename');
        if (bytes != null) {
          await f.writeAsBytes(bytes);
        } else {
          await f.writeAsString(content);
        }
      }
    } catch (_) {}
  }
}

void printHtmlContent(String title, String htmlContent) {
  // Mobile platform print fallback
}
