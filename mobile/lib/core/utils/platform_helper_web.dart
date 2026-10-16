// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'dart:typed_data';

void openUrl(String url) {
  try {
    html.window.open(url, '_blank');
  } catch (_) {}
}

void downloadTextOrPdf(String filename, String content, {Uint8List? bytes, String mimeType = 'application/pdf'}) {
  try {
    final payload = bytes ?? content.codeUnits;
    final blob = html.Blob([payload], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  } catch (_) {}
}

void printHtmlContent(String title, String htmlContent) {
  try {
    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
  } catch (_) {}
}
