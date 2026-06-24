import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../i18n/strings.dart';

/// Ouvre la caméra pour scanner un code-barres (EAN-13/Code-128/GS1-128) et
/// retourne la valeur brute décodée, ou `null` si l'utilisateur annule.
/// Sert de complément au scan douchette (qui fonctionne déjà via la saisie
/// clavier émulée dans les champs texte existants) quand aucune douchette
/// n'est disponible.
Future<String?> showBarcodeScannerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _BarcodeScannerSheet(),
  );
}

class _BarcodeScannerSheet extends StatefulWidget {
  const _BarcodeScannerSheet();

  @override
  State<_BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<_BarcodeScannerSheet> {
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.code128,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          AppBar(
            title: Text(Strings.of(context).scanABarcode),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Expanded(
            child: MobileScanner(controller: _controller, onDetect: _onDetect),
          ),
        ],
      ),
    );
  }
}
