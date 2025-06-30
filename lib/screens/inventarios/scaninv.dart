import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class ScanInv extends StatelessWidget {
  final void Function(String codigo) onCodigoEscaneado;

  const ScanInv({super.key, required this.onCodigoEscaneado});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        var res = await Navigator.push(
          context,
          MaterialPageRoute(
            // ignore: deprecated_member_use
            builder: (context) => const SimpleBarcodeScannerPage(),
          ),
        );

        if (res != null && res != '-1') {
          onCodigoEscaneado(res);
        }
      },
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const CircleBorder(),
      child: const Icon(Icons.qr_code_scanner, color: Colors.black87, size: 30),
    );
  }
}
