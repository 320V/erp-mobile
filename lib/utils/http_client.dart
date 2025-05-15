import 'dart:io';
import 'package:http/io_client.dart';

IOClient createSelfSignedClient() {
  final HttpClient httpClient = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) {
      return host == "192.168.1.213" || host == "212.156.147.234"; // Her iki IP için de sertifika kontrolünü devre dışı bırak
    };
  return IOClient(httpClient);
} 