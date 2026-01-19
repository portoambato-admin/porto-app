import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> saveBytes(
  Uint8List bytes,
  String filename, {
  required String mimeType,
}) async {
  // En desktop suele funcionar, en Android puede devolver null
  dynamic dir = await getDownloadsDirectory();
  dir ??= await getApplicationDocumentsDirectory();

  final targetPath = '${dir.path}/$filename';
  final xf = XFile.fromData(bytes, name: filename, mimeType: mimeType);
  await xf.saveTo(targetPath);

  return targetPath;
}
