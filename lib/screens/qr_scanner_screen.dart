import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class QrScannerScreen extends StatelessWidget {
  const QrScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ekran boyutlarını alalım
    final scanWindow = Rect.fromCenter(
      center: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
      width: 250,
      height: 250,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Çantayı Tara")),
      body: Stack(
        children: [
          // 1. KAMERA KATMANI
          MobileScanner(
            scanWindow: scanWindow, // Sadece bu alanın içini okur
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  String code = barcode.rawValue!;
                  bool isValid = await AuthService().checkBagId(code);

                  if (isValid && context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen(bagId: code)),
                    );
                  }
                }
              }
            },
          ),
          
          // 2. KARARTMA VE ÇERÇEVE KATMANI (Overlay)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5), // Etrafı karart
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                // Ortadaki şeffaf delik (Okuma alanı)
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. GÖRSEL ÇERÇEVE ÇİZGİSİ
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // 4. BİLGİLENDİRME YAZISI
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: const Text(
              "QR Kodu Çerçevenin İçine Hizalayın",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}