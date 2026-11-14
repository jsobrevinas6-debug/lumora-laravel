import 'dart:async';
import 'dart:js_interop';
// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as web;

Future<String?> pickNativeImage({bool fromCamera = false}) async {
  final completer = Completer<String?>();
  try {
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = 'image/*';
    if (fromCamera) {
      input.setAttribute('capture', 'user');
    }

    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.length == 0) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files.item(0);
      if (file == null) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final reader = web.FileReader();
      reader.onLoadEnd.listen((_) {
        final res = reader.result;
        if (!completer.isCompleted) {
          completer.complete(res?.dartify()?.toString());
        }
      });
      reader.readAsDataURL(file);
    });

    input.click();
  } catch (_) {
    if (!completer.isCompleted) completer.complete(null);
  }
  return completer.future;
}
