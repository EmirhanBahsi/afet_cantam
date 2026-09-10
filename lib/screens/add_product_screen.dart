import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';
import '../services/image_processing_service.dart';

class AddProductScreen extends StatefulWidget {
  final String bagId;
  const AddProductScreen({super.key, required this.bagId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String _selectedCategory = 'Gıda';
  bool _isScanning = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Gıda', 'icon': Icons.fastfood_rounded, 'color': Colors.orange},
    {'name': 'Sağlık', 'icon': Icons.medication_rounded, 'color': Colors.redAccent},
    {'name': 'Hijyen', 'icon': Icons.clean_hands_rounded, 'color': Colors.blue},
    {'name': 'Araç-Gereç', 'icon': Icons.handyman_rounded, 'color': Colors.teal},
  ];

  // 🔥 EN AKILLI HİBRİT OCR FONKSİYONU (Optik Karakter Düzeltici Eklendi)
  Future<void> _scanExpiryDate() async {
    setState(() => _isScanning = true);
    try {
      final devices = await availableCameras();
      if (devices.isEmpty) return;

      final firstCamera = devices.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => devices.first,
      );

      final CameraController cameraController = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController.initialize();
      final XFile rawImage = await cameraController.takePicture();
      await cameraController.dispose();

      File rawFile = File(rawImage.path);

      // Filtreyi geri açtık ki noktalar ve silik yazılar belirginleşsin
      File cleanFile = await ImageProcessingService.preprocessForOCR(rawFile);
      final inputImage = InputImage.fromFile(cleanFile);

      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      // 🚀 YENİ: Ayıraç olmasa bile bitişik sayıları (05072025) yakalayan esnek Regex
      RegExp dateRegex = RegExp(r'(\d{2})[./\s,-]*(\d{2})[./\s,-]*(\d{2,4})');
      List<DateTime> parsedDates = [];

      for (TextBlock block in recognizedText.blocks) {
        // 🔥 MÜHENDİSLİK DOKUNUŞU: ML Kit'in harfleri sayılarla karıştırmasını önden düzeltiyoruz!
        String fullText = block.text.toUpperCase()
            .replaceAll('\n', ' ')
            .replaceAll('O', '0') // O harfini Sıfır yap
            .replaceAll('D', '0') // D harfini Sıfır yap (D507025 -> 0507025)
            .replaceAll('?', '7') // ? işaretini 7 yap (050?2025 -> 05072025)
            .replaceAll('S', '5')
            .replaceAll('B', '8')
            .replaceAll('Z', '2');

        Iterable<RegExpMatch> matches = dateRegex.allMatches(fullText);

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
      }

      if (!mounted) return;

      if (parsedDates.isNotEmpty) {
        // Tarihleri sırala ve en ilerideki tarihi (Son Kullanma Tarihini) al
        DateTime expiryDate = parsedDates.reduce((a, b) => a.isAfter(b) ? a : b);

        String day = expiryDate.day.toString().padLeft(2, '0');
        String month = expiryDate.month.toString().padLeft(2, '0');
        String matchedDate = "$day.$month.${expiryDate.year}";

        setState(() {
          _dateController.text = matchedDate;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tarih başarıyla tarandı!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tarih net okunamadı, lütfen tekrar deneyin veya elle girin.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tarama hatası: $e")),
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Yeni Eşya Ekle"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ürün Bilgileri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            _buildInputField(
              controller: _nameController,
              label: "Eşya Adı",
              hint: "Örn: Konserve, Bandaj...",
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 20),

            _buildInputField(
              controller: _amountController,
              label: "Adet / Miktar",
              hint: "Örn: 2",
              icon: Icons.numbers_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Son Kullanma Tarihi", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: TextField(
                          controller: _dateController,
                          decoration: const InputDecoration(
                            hintText: "Örn: 25.12.2026",
                            prefixIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFFD32F2F)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _isScanning ? null : _scanExpiryDate,
                      child: Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: _isScanning
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.camera_alt_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),

            const Text("Kategori Seçin", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((cat) => _buildCategoryChip(cat)).toList(),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
              ),
              onPressed: () async {
                if (_nameController.text.isEmpty || _amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lütfen tüm alanları doldurun!")),
                  );
                  return;
                }

                Product newProduct = Product(
                  id: '',
                  name: _nameController.text,
                  category: _selectedCategory,
                  amount: int.parse(_amountController.text),
                );

                await AuthService().addProduct(widget.bagId, newProduct);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Çantaya Ekle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: const Color(0xFFD32F2F)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(Map<String, dynamic> cat) {
    bool isSelected = _selectedCategory == cat['name'];
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? cat['color'] : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected ? [BoxShadow(color: cat['color'].withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
          border: Border.all(color: isSelected ? cat['color'] : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cat['icon'], color: isSelected ? Colors.white : cat['color'], size: 20),
            const SizedBox(width: 8),
            Text(cat['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}