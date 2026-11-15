import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as web;

Future<String> _compressWebImageDataUri(String dataUrl) async {
  final completer = Completer<String>();
  try {
    final img = web.HTMLImageElement();
    img.onLoad.listen((_) {
      try {
        final rawW = img.naturalWidth > 0 ? img.naturalWidth : img.width;
        final rawH = img.naturalHeight > 0 ? img.naturalHeight : img.height;
        if (rawW <= 0 || rawH <= 0) {
          if (!completer.isCompleted) completer.complete(dataUrl);
          return;
        }
        const maxDim = 1200;
        final scale = math.min(1.0, maxDim / math.max(rawW, rawH));
        final targetW = math.max(1, (rawW * scale).round());
        final targetH = math.max(1, (rawH * scale).round());
        final canvas = web.HTMLCanvasElement()
          ..width = targetW
          ..height = targetH;
        final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
        if (ctx == null) {
          if (!completer.isCompleted) completer.complete(dataUrl);
          return;
        }
        ctx.drawImage(img, 0, 0, targetW, targetH);
        final jpegDataUrl = canvas.toDataURL('image/jpeg', 0.85.toJS);
        if (!completer.isCompleted) {
          completer.complete(jpegDataUrl.isNotEmpty ? jpegDataUrl : dataUrl);
        }
      } catch (_) {
        if (!completer.isCompleted) completer.complete(dataUrl);
      }
    });
    img.onError.listen((_) {
      if (!completer.isCompleted) completer.complete(dataUrl);
    });
    img.src = dataUrl;
  } catch (_) {
    if (!completer.isCompleted) completer.complete(dataUrl);
  }
  return completer.future;
}

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
      reader.onLoadEnd.listen((_) async {
        final rawDataUri = reader.result?.dartify()?.toString();
        if (rawDataUri == null || rawDataUri.isEmpty) {
          if (!completer.isCompleted) completer.complete(null);
          return;
        }
        final optimized = await _compressWebImageDataUri(rawDataUri);
        if (!completer.isCompleted) {
          completer.complete(optimized);
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
