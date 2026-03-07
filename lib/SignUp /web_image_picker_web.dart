import 'dart:async';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart';

/// Web-only implementation of image picking using the File API.
Future<Map<String, dynamic>?> pickImageWebImpl({int maxBytes = 2 * 1024 * 1024}) async {
  try {
    final uploadInput = HTMLInputElement();
    uploadInput.type = 'file';
    uploadInput.accept = 'image/*';
    uploadInput.multiple = false;
    uploadInput.style.display = 'none';
    document.body?.appendChild(uploadInput);

    final completer = Completer<void>();

    uploadInput.addEventListener(
        'change',
            (Event e) {
          completer.complete();
        }.toJS);

    uploadInput.click();

    await completer.future;

    final files = uploadInput.files;
    if (files == null || files.length == 0) {
      uploadInput.remove();
      return null;
    }

    final file = files.item(0);
    if (file == null) {
      uploadInput.remove();
      return null;
    }

    if (file.size > maxBytes) {
      uploadInput.remove();
      final maxMb = (maxBytes / (1024 * 1024)).toStringAsFixed(1);
      return {'error': 'Selected image exceeds $maxMb MB'};
    }

    final dataUrlCompleter = Completer<String?>();
    final readerDataUrl = FileReader();
    readerDataUrl.addEventListener(
      'load',
          (Event e) {
        final jsResult = readerDataUrl.result as JSString?;
        dataUrlCompleter.complete(jsResult?.toDart);
      }.toJS,
    );
    readerDataUrl.addEventListener(
        'error',
            (Event e) {
          dataUrlCompleter.completeError('Error reading file as DataURL');
        }.toJS);

    readerDataUrl.readAsDataURL(file);
    final dataUrl = await dataUrlCompleter.future;

    final bytesCompleter = Completer<dynamic>();
    final readerBinary = FileReader();

    readerBinary.addEventListener(
        'load',
            (Event e) {
          bytesCompleter.complete(readerBinary.result);
        }.toJS);

    readerBinary.addEventListener(
        'error',
            (Event e) {
          bytesCompleter.completeError('Error reading file as ArrayBuffer');
        }.toJS);

    readerBinary.readAsArrayBuffer(file);
    final resultBuffer = await bytesCompleter.future;

    Uint8List bytes;
    if (resultBuffer is ByteBuffer) {
      bytes = resultBuffer.asUint8List();
    } else {
      uploadInput.remove();
      return {'error': 'Unable to read file bytes (unsupported result type)'};
    }

    uploadInput.remove();

    return {
      'dataUrl': dataUrl,
      'bytes': bytes,
      'fileName': file.name,
      'size': file.size,
    };
  } catch (e) {
    return {'error': 'Image pick failed: $e'};
  }
}
