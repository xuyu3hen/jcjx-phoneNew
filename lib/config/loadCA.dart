import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

Future<SecurityContext> loadCertificate(String certPath) async {
  final ByteData data = await rootBundle.load(certPath);
  final Uint8List certBytes = data.buffer.asUint8List();

  final SecurityContext context = SecurityContext(withTrustedRoots: false);
  context.setTrustedCertificatesBytes(certBytes);
  return context;
}