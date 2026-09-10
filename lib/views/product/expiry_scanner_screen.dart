import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img; // Sadece bu kütüphane yeterli
import 'dart:io';

class ExpiryScannerScreen extends StatefulWidget {
  const ExpiryScannerScreen({super.key});

  @override
  State<ExpiryScannerScreen> createState() => _ExpiryScannerScreenState();
}

class _ExpiryScannerScreenState extends State<ExpiryScannerScreen> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Camera başlatılamadı")));
      }
    }
  }

  // YENİ YAKLAŞIM: Dosyasız, Doğrudan Hafıza (RAM) Üzerinden Kırpma ve Tarama
  /*Future<void> _captureAndScan() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing)
      return;

    setState(() => _isProcessing = true);

    try {
      // 1. Fotoğrafı çek ve anlık önizlemeyi dondur
      final XFile photo = await _cameraController!.takePicture();
      await _cameraController?.pausePreview();

      // 2. Android cihazlardaki YUV/0x21 format hatasını aşmak için resmi dosya patikasından okuyoruz
      // Dosyanın gerçekten var olduğunu kontrol ederek işi garantiye alalım
      final File imageFile = File(photo.path);
      if (!await imageFile.exists()) {
        throw Exception("Fotoğraf dosyası oluşturulamadı.");
      }

      // 3. ML Kit'e en kararlı formatta resmi veriyoruz
      final inputImage = InputImage.fromFile(imageFile);

      // 4. Metin tanıma işlemini başlat
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      // Dosya şişmesin diye işimiz bitince hemen siliyoruz
      try {
        await imageFile.delete();
      } catch (e) {
        debugPrint("Geçici dosya silinemedi: $e");
      }

      // 5. Analiz fonksiyonunu çağır
      await _analyzeText(recognizedText.text);
    } catch (e) {
      debugPrint("Tarama Hatası: $e");
      await _cameraController
          ?.resumePreview(); // Hata durumunda kamerayı canlandır
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Yazı okunurken bir hata oluştu.")),
        );
      }
      setState(() => _isProcessing = false);
    }
  }*/

  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Zoom yapmadan, normal açıyla fotoğrafı çek ve önizlemeyi dondur
      final XFile photo = await _cameraController!.takePicture();
      await _cameraController?.pausePreview();

      // 2. Dosyayı kararlı formatta oku
      final File imageFile = File(photo.path);
      if (!await imageFile.exists()) {
        throw Exception("Fotoğraf dosyası oluşturulamadı.");
      }

      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      // Geçici dosyayı hemen sil
      try {
        await imageFile.delete();
      } catch (e) {
        debugPrint("Geçici dosya silinemedi: $e");
      }

      // 3. Metni analize gönder
      await _analyzeText(recognizedText.text);

    } catch (e) {
      debugPrint("Tarama Hatası: $e");
      await _cameraController?.resumePreview();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Yazı okunurken bir hata oluştu.")),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _analyzeText(String rawText) async {
    debugPrint("KAMERADAN OKUNAN HAM METIN:\n$rawText");

    // 1. Önce tüm boşlukları, çift noktaları ve gereksiz karakterleri temizleyerek normalize ediyoruz.
    // 'S. K. T.: 09/2027' verisi artık 'S.K.T.09/2027' veya benzeri temiz bir stringe dönüşüyor.
    String cleanText = rawText.toUpperCase().replaceAll(RegExp(r'\s+'), '');

    // 2. Kural: Standart Tam Tarih (GG.AA.YYYY veya GG/AA/YY vb.)
    final RegExp standardDateRegex = RegExp(
      r'(0[1-9]|[12]\d|3[01])[./-]?(0[1-9]|1[0-2])[./-]?(\d{4}|\d{2})',
    );

    // 3. Kural: Sadece Ay ve Yıl Olan Tarih (AA/YYYY veya AA.YYYY veya AA/YY vb.)
    // İlaç kutularındaki '09/2027' veya '092027' gibi durumları yakalar.
    final RegExp monthYearRegex = RegExp(r'(0[1-9]|1[0-2])[./-]?(\d{4}|\d{2})');

    // Önce tam tarih var mı diye bakıyoruz
    final Match? match = standardDateRegex.firstMatch(cleanText);

    if (match != null) {
      String day = match.group(1)!;
      String month = match.group(2)!;
      String year = match.group(3)!;

      if (year.length == 2) year = "20$year";
      String detectedDate = "$day.$month.$year";

      _onSuccessFound(detectedDate);
    } else {
      // Eğer tam tarih yoksa, SADECE AY VE YIL VAR MI diye bakıyoruz (İlaçlar için kritik adım)
      final Match? myMatch = monthYearRegex.firstMatch(cleanText);

      if (myMatch != null) {
        String month = myMatch.group(1)!;
        String year = myMatch.group(2)!;
        if (year.length == 2) year = "20$year";

        // MVP yaklaşımı: Gün belirtilmediği için bu gıdanın/ilacın o ayın sonuna kadar
        // güvenle kullanılabileceğini varsayarak günü '01' kabul ediyoruz.
        String fallbackDate = "01.$month.$year";

        _onSuccessFound(fallbackDate);
      } else {
        // Hiçbir format uymazsa kamerayı canlandır ve hata ver
        await _cameraController?.resumePreview();
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "tarih_bulunamadi".tr() == "tarih_bulunamadi"
                    ? "Tarih algılanamadı, lütfen tekrar deneyin."
                    : "tarih_bulunamadi".tr(),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // Kod tekrarını önlemek için başarı anını tek bir metoda topladık
  void _onSuccessFound(String date) async {
    setState(() {
      _isSuccess = true;
      _foundDate = date;
      _isProcessing = false;
    });

    HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      Navigator.pop(context, date);
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

    final activeColor = _isSuccess
        ? const Color(0xFF10B981)
        : (_isProcessing ? const Color(0xFF6366F1) : const Color(0xFFF59E0B));

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
                Positioned.fill(child: CameraPreview(_cameraController!)),

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
                        border: Border.all(color: activeColor, width: 2.5),
                      ),
                      child: _isProcessing
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF6366F1),
                              ),
                            )
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.4),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'ocr_scanner_title'.tr() == 'ocr_scanner_title'
                              ? "Tarih Tarayıcı"
                              : 'ocr_scanner_title'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'ocr_scanner_guide'.tr() == 'ocr_scanner_guide'
                                ? "Tarihi çerçevenin içine ortalayın ve aşağıdaki butona basın."
                                : 'ocr_scanner_guide'.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.3,
                            ),
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
                              backgroundColor: _isProcessing
                                  ? Colors.grey
                                  : const Color(0xFF6366F1),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
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
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutout = Path()
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)));
    final finalPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      cutout,
    );
    canvas.drawPath(finalPath, bgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
