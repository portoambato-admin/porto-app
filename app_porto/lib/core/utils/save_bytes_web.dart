import 'dart:html' as html;
import 'dart:typed_data';

Future<String?> saveBytes(
  Uint8List bytes,
  String filename, {
  required String mimeType,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final a = html.AnchorElement(href: url)..download = filename;
  a.click();

  html.Url.revokeObjectUrl(url);
  return null; // en web no hay "path"
}
