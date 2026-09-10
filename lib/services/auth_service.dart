import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Giriş Yap Fonksiyonu
  Future<bool> loginWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Kayıt Ol Fonksiyonu (Arkadaşının tespiti doğrultusunda 'bag_id' eklendi)
  Future<bool> registerWithEmail(
      String email,
      String password,
      String name,
      ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Web sitesinin tarama yaparken aradığı 'bag_id' alanını buraya sabitledik
        await _firestore.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'name': name,
          'email': email.trim(),
          'bag_id': result.user!.uid, // Web sitesi tarayıcısının okuyacağı kritik alan
          'bloodType': 'profile_not_entered',
          'allergies': 'profile_not_specified',
          'chronicIllness': 'profile_not_specified',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await Future.delayed(const Duration(milliseconds: 300));
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  // Çanta ID Geçerliliği Sorgulama
  Future<bool> checkBagId(String scannedId) async {
    try {
      var result = await _firestore
          .collection('users')
          .where('bag_id', isEqualTo: scannedId)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      rethrow;
    }
  }

  // Çantaya Ürün Ekleme
  Future<void> addProduct(String bagId, Product product) async {
    try {
      await _firestore
          .collection('bags')
          .doc(bagId)
          .collection('items')
          .add(product.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Sağlık Profili Güncelleme
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
      rethrow;
    }
  }

  // Oturumu Kapat
  Future<void> signOut() async {
    await _auth.signOut();
  }
}