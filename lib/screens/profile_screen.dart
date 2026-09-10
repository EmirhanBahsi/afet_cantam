import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'welcome_screen.dart'; // Çıkış yapınca ana karşılama ekranına dönmek için

class ProfileScreen extends StatelessWidget {
  final String? bagId;
  const ProfileScreen({super.key, this.bagId});

  @override
  Widget build(BuildContext context) {
    // 1. Cihazda aktif bir Firebase Auth oturumu var mı kontrol et
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // 2. Sorgulanacak gerçek ID'yi belirle: 
    // Eğer QR ile girildiyse 'bagId' doludur, Auth ile girildiyse 'currentUser.uid' kullanılır.
    final String? targetId = bagId ?? currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Dijital Künyem", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      // Eğer ne QR kodu var ne de aktif oturum varsa hata göster
      body: targetId == null
          ? _buildErrorState(context, "Görüntülenecek çanta veya oturum bilgisi bulunamadı.")
          : StreamBuilder<DocumentSnapshot>(
              // Doğrudan hedef ID'ye ait veritabanı dökümanını dinliyoruz
              stream: FirebaseFirestore.instance.collection('users').doc(targetId).snapshots(),
              builder: (context, dbSnapshot) {
                if (dbSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
                }

                if (!dbSnapshot.hasData || !dbSnapshot.data!.exists) {
                  return _buildErrorState(context, "Kullanıcı detayları veritabanında bulunamadı.");
                }

                var userData = dbSnapshot.data!.data() as Map<String, dynamic>;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      // Profil Başlık Bölümü (E-posta yoksa varsayılan metin basar)
                      _buildProfileHeader(userData, userData['email'] ?? "QR ile Giriş Yapıldı"),
                      const SizedBox(height: 30),

                      // Sağlık Bilgileri Kartı
                      _buildModernInfoCard(
                        title: "Sağlık Bilgileri",
                        icon: Icons.medical_services_rounded,
                        color: const Color(0xFFD32F2F),
                        items: {
                          "Kan Grubu": userData['bloodType'] ?? "Girilmemiş",
                          "Alerjiler": userData['allergies'] ?? "Belirtilmemiş",
                          "Hastalıklar": userData['chronicIllness'] ?? "Belirtilmemiş",
                        },
                      ),
                      const SizedBox(height: 20),

                      // QR Kod Kartı (Veritabanındaki bag_id'yi basar)
                      _buildQRCard(userData['bag_id'] ?? targetId),
                      const SizedBox(height: 30),

                      // Oturumu Kapat / Giriş Ekranına Dön Butonu
                      _buildLogoutButton(context),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // --- YARDIMCI BİLEŞENLER (WIDGETS) ---

  Widget _buildProfileHeader(Map<String, dynamic> data, String email) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD32F2F), width: 2)),
            child: const CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, size: 50, color: Color(0xFFD32F2F)),
            ),
          ),
          const SizedBox(height: 15),
          Text(data['name'] ?? "Kullanıcı", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildModernInfoCard({required String title, required IconData icon, required Color color, required Map<String, String> items}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 24), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
          const Divider(height: 30),
          ...items.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Text(e.key, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)), 
                Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold))
              ]
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildQRCard(String data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2_rounded, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text("Erişim Karekodu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          QrImageView(
            data: data,
            size: 180.0,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFFD32F2F)),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Text(
            "Kod Verisi: $data",
            style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        // Hem Firebase oturumunu kapat hem de en baş karşılama ekranına güvenle dön
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()), 
            (route) => false
          );
        }
      },
      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
      label: const Text("Çıkış Yap", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_accounts_rounded, size: 80, color: Colors.orange),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context), 
            child: const Text("Geri Dön")
          ),
        ],
      ),
    );
  }
}