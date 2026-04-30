import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart'; // Dosya yolunun doğruluğundan emin ol

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kayıt Ol Fonksiyonu
  Future<bool> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      // 1. Kullanıcıyı oluştur
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // 2. Veritabanına yazma işlemini mutlaka 'await' ile bekle
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'bag_id': user.uid,
          'bloodType':
              'Girilmemiş', // Profil sayfası hata almasın diye başlangıç değerleri
          'allergies': 'Yok',
          'chronicIllness': 'Yok',
          'createdAt':
              FieldValue.serverTimestamp(), // Cihaz saati yerine sunucu saati
        });
        return true; // Her şey başarılı
      }
      return false;
    } catch (e) {
      // Hata neyse buraya düşecek (Örn: email-already-in-use, permission-denied)
      print("🔥 KAYIT HATASI DETAYI: $e");
      return false;
    }
  }
  // auth_service.dart içine ekle

  Future<bool> checkBagId(String scannedId) async {
    try {
      // Firestore'da 'users' koleksiyonunda bu 'bag_id'ye sahip dökümanı ara
      var result = await _firestore
          .collection('users')
          .where('bag_id', isEqualTo: scannedId)
          .get();

      // Eğer sonuç boş değilse, bu geçerli bir çantadır
      return result.docs.isNotEmpty;
    } catch (e) {
      print("QR Sorgu Hatası: $e");
      return false;
    }
  }

  // auth_service.dart veya bag_service.dart içine:
  Future<void> addProduct(String bagId, Product product) async {
    await _firestore
        .collection('bags')
        .doc(bagId)
        .collection('items')
        .add(product.toMap());
  }

  // auth_service.dart içine ekle
  Future<void> updateHealthProfile(
    String uid,
    String bloodType,
    String allergies,
    String illnesses,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'bloodType': bloodType,
        'allergies': allergies,
        'chronicIllness': illnesses,
      });
    } catch (e) {
      print("Profil güncelleme hatası: $e");
    }
  }
}
