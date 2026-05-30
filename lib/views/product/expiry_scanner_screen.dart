import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ExpiryScannerScreen extends StatefulWidget {
  const ExpiryScannerScreen({super.key});

  @override
  State<ExpiryScannerScreen> createState() => _ExpiryScannerScreenState();
}

class _ExpiryScannerScreenState extends State<ExpiryScannerScreen> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isProcessing = false;
  bool _cameraInitialized = false;
  bool _isSuccess = false;
  String _foundDate = "";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCam = cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCam,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _cameraInitialized = true);

    } catch (e) {
      debugPrint("CAMERA INIT ERROR: $e");
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera başlatılamadı")),
        );
      }
    }
  }

  /*
  Aşşağıdaki fonksiyonun loglarını inceleyerek model geliştirilebilir
  incele !!!
  */

  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {

      final XFile photo = await _cameraController!.takePicture();

      final inputImage = InputImage.fromFilePath(photo.path);


      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      final file = File(photo.path);
      if (await file.exists()) {
        await file.delete();
      }

      await _analyzeText(recognizedText.text);

    } catch (e) {
      debugPrint("Tarama Hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Yazı okunurken bir hata oluştu.")),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _analyzeText(String rawText) async {
    debugPrint("OKUNAN METIN:\n$rawText");

    // 🔥 MÜHENDİSLİK DOKUNUŞU: Optik Karakter Düzeltici
    // ML Kit'in harfleri sayılarla karıştırmasını önden düzeltiyoruz.
    String cleanText = rawText.toUpperCase()
        .replaceAll('\n', ' ')
        .replaceAll('O', '0') // O harfini Sıfır yap
        .replaceAll('D', '0') // D harfini Sıfır yap (Peynirdeki D507025 -> 0507025)
        .replaceAll('?', '7') // ? işaretini 7 yap (Peynirdeki 050?2025 -> 05072025)
        .replaceAll('S', '5')
        .replaceAll('B', '8')
        .replaceAll('Z', '2');

    // 🚀 YENİ: Ayıraç (nokta/çizgi) olmasa bile bitişik sayıları yakalayan esnek Regex
    final RegExp dateRegex = RegExp(r'(\d{2})[./\s,-]*(\d{2})[./\s,-]*(\d{2,4})');
    List<DateTime> parsedDates = [];

    final Iterable<RegExpMatch> matches = dateRegex.allMatches(cleanText);

    for (final match in matches) {
      try {
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);

        if (year < 100) year += 2000;

        // Mantıklı bir tarih mi kontrol et (Örn: Ay 13 olamaz)
        if (day > 0 && day <= 31 && month > 0 && month <= 12) {
          parsedDates.add(DateTime(year, month, day));
        }
      } catch (e) {
        // Hata olursa diğerine geç
      }
    }

    if (parsedDates.isNotEmpty) {
      // 🚀 HELVA ÇÖZÜMÜ: Birden fazla tarih varsa, en ilerideki tarihi (Son Kullanma Tarihini) al
      DateTime expiryDate = parsedDates.reduce((a, b) => a.isAfter(b) ? a : b);

      String day = expiryDate.day.toString().padLeft(2, '0');
      String month = expiryDate.month.toString().padLeft(2, '0');
      String detectedDate = "$day.$month.${expiryDate.year}";

      setState(() {
        _isSuccess = true;
        _foundDate = detectedDate;
        _isProcessing = false;
      });

      HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        Navigator.pop(context, detectedDate);
      }
    } else {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("tarih_bulunamadi".tr() == "tarih_bulunamadi" ? "Tarih algılanamadı, lütfen tekrar deneyin." : "tarih_bulunamadi".tr()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 30),
      width: 300,
      height: 160,
    );

    final activeColor = _isSuccess ? const Color(0xFF10B981) : (_isProcessing ? const Color(0xFF6366F1) : const Color(0xFFF59E0B));

    return Scaffold(
      backgroundColor: Colors.black,
      body: !_cameraInitialized
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
        ),
      )
          : Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),

          CustomPaint(
            size: Size.infinite,
            painter: _OCRScannerOverlayPainter(scanRect),
          ),

          Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                width: 300,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: activeColor,
                    width: 2.5,
                  ),
                ),
                child: _isProcessing
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                    : null,
              ),
            ),
          ),

          if (_isSuccess)
            Positioned(
              top: (size.height / 2) + 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'ocr_found_text'.tr(args: [_foundDate]),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.4),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'ocr_scanner_title'.tr() == 'ocr_scanner_title' ? "Tarih Tarayıcı" : 'ocr_scanner_title'.tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                if (!_isSuccess) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'ocr_scanner_guide'.tr() == 'ocr_scanner_guide'
                          ? "Tarihi çerçevenin içine ortalayın ve aşağıdaki butona basın."
                          : 'ocr_scanner_guide'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _isProcessing ? null : _captureAndScan,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: _isProcessing ? Colors.grey : const Color(0xFF6366F1),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OCRScannerOverlayPainter extends CustomPainter {
  final Rect scanRect;
  _OCRScannerOverlayPainter(this.scanRect);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.6);
    final overlayPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutout = Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)));
    final finalPath = Path.combine(PathOperation.difference, overlayPath, cutout);
    canvas.drawPath(finalPath, bgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}