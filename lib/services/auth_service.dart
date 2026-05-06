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
      // 1. Kullanıcıyı Auth üzerinde oluştur
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // 2. Firestore'a dökümanı UID ile aç
        // ÖNEMLİ: doc(result.user!.uid) kullanımı döküman isminin UID olmasını sağlar.
        await _firestore.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'name': name,
          'email': email.trim(),
          'bloodType': 'Girilmemiş',
          'allergies': 'Yok',
          'chronicIllness': 'Yok',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Yazma işleminin Firebase tarafından onaylanmasını bekle
        await Future.delayed(const Duration(milliseconds: 300));
        return true;
      }
      return false;
    } catch (e) {
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
