import 'dart:convert';
import 'dart:typed_data';

Uint8List decodeImageDataDynamic(String s) {
  try {
    if (s.isEmpty) return Uint8List(0);
    if (s.startsWith('data:')) return UriData.parse(s).contentAsBytes();
    return base64Decode(s);
  } catch (e) {
    return Uint8List(0);
  }
}
