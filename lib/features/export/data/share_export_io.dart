import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Native: write [content] to a temp file named [fileName] and hand it to the
/// OS share sheet so the user can save it or send it wherever they like. The
/// file stays on-device until they choose to share it.
Future<void> shareExport({
  required String content,
  required String fileName,
  required String subject,
  required String text,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, fileName));
  await file.writeAsBytes(utf8.encode(content), flush: true);
  await Share.shareXFiles([XFile(file.path)], subject: subject, text: text);
}
