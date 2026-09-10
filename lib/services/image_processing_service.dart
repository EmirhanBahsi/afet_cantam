import 'dart:io';
import 'package:image/image.dart' as img;

class ImageProcessingService {

  /// Kameradan gelen resmi OCR için optimize eder (Grayscale -> Gaussian Blur -> Contrast -> Binarization)
  static Future<File> preprocessForOCR(File inputImageFile) async {
    final bytes = await inputImageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) return inputImageFile;

    // 1. ADIM: Grayscale (Renk gürültüsünü tamamen yok ediyoruz)
    img.Image grayscale = img.grayscale(image);

    // 2. ADIM: Gaussian Blur (Noktalı/kesikli fontların arasındaki boşlukları kapatmak için hafifçe yumuşatıyoruz)
    img.Image blurred = img.gaussianBlur(grayscale, radius: 1);

    // 3. ADIM: Keskin Kontrast (Yazıları ön plana çıkarıyoruz)
    img.Image contrasted = img.contrast(blurred, contrast: 1.8);

    // 4. ADIM: Binarization / Thresholding (Arka planı saf beyaz, yazıları saf siyah yapar)
    // Piksel değeri 128'in altındakileri siyah, üstündekileri beyaz yapıyoruz
    for (int y = 0; y < contrasted.height; y++) {
      for (int x = 0; x < contrasted.width; x++) {
        img.Pixel pixel = contrasted.getPixel(x, y);
        // Gri tonlamada r, g, b değerleri eşittir. Aydınlığı (luminance) kontrol ediyoruz.
        double luminance = pixel.r / 255.0;

        if (luminance < 0.5) {
          contrasted.setPixelRgb(x, y, 0, 0, 0); // Saf Siyah
        } else {
          contrasted.setPixelRgb(x, y, 255, 255, 255); // Saf Beyaz
        }
      }
    }

    // Filtrelenmiş resmi JPG olarak kaydet
    final processedBytes = img.encodeJpg(contrasted);
    File processedFile = await inputImageFile.writeAsBytes(processedBytes);

    return processedFile;
  }
}