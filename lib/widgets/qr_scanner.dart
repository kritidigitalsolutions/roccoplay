import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatelessWidget {
  const QrScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Scan QR Code",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // body: MobileScanner(
      //   onDetect:
      //       (barcode, args) {
      //     final String? code = barcode.rawValue;
      //     if (code != null) {
      //       Navigator.pop(context);
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         SnackBar(content: Text("Scanned: $code")),
      //       );
      //     }
      //   },
      // ),
    );
  }
}
