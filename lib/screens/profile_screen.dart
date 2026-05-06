import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'register_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String? bagId;
  const ProfileScreen({super.key, this.bagId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Dijital Künyem", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      // Auth durumunu dinliyoruz
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // 1. Veri henüz geliyorsa bekle
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
          }

          final user = authSnapshot.data;

          // 2. Eğer kullanıcı gerçekten null ise (Oturum yoksa)
          if (user == null) {
            return _buildErrorState(context, "Aktif bir oturum bulunamadı. Lütfen tekrar giriş yapın.");
          }

          // 3. Kullanıcı varsa Firestore verisini çek
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, dbSnapshot) {
              if (dbSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
              }

              // Veri yoksa veya döküman silinmişse
              if (!dbSnapshot.hasData || !dbSnapshot.data!.exists) {
                return _buildErrorState(context, "Kullanıcı detayları veritabanında bulunamadı.");
              }

              var userData = dbSnapshot.data!.data() as Map<String, dynamic>;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    // Profil Başlık Bölümü
                    _buildProfileHeader(userData, user.email),
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

                    // QR Kod Kartı
                    _buildQRCard(bagId ?? user.uid),
                    const SizedBox(height: 30),

                    // Oturumu Kapat Butonu
                    _buildLogoutButton(context),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- YARDIMCI WIDGET'LAR ---

  Widget _buildProfileHeader(Map<String, dynamic> data, String? email) {
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
          Text(email ?? "", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 24), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
          const Divider(height: 30),
          ...items.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key, style: TextStyle(color: Colors.grey[600])), Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold))]),
          )),
        ],
      ),
    );
  }

  Widget _buildQRCard(String data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        children: [
          const Text("Erişim Karekodu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 15),
          QrImageView(
            data: data,
            size: 180.0,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFFD32F2F)),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const RegisterScreen()), (route) => false);
      },
      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
      label: const Text("Oturumu Kapat", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Geri Dön")),
        ],
      ),
    );
  }
}