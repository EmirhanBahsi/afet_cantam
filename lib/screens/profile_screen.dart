import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'register_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String? bagId; // Parametre olarak bagId alıyoruz
  const ProfileScreen({super.key, this.bagId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text("Profilim ve Dijital Künyem")),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // Oturum bilgisi gelene kadar loading göster
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authSnapshot.data;

          // Eğer oturum gerçekten yoksa (Giriş yapılmamışsa)
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.orange),
                  const SizedBox(height: 10),
                  const Text("Oturum bilgisi alınamadı."),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Geri Dön ve Tekrar Dene"),
                  )
                ],
              ),
            );
          }

          // Oturum varsa verileri getir
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, dbSnapshot) {
              if (dbSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!dbSnapshot.hasData || dbSnapshot.data?.data() == null) {
                return const Center(child: Text("Kullanıcı verisi bulunamadı."));
              }

              var userData = dbSnapshot.data!.data() as Map<String, dynamic>;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFFD32F2F),
                      child: Icon(Icons.person, size: 55, color: Colors.white),
                    ),
                    const SizedBox(height: 25),
                    _buildInfoCard("Kişisel Bilgiler", {
                      "Ad Soyad": userData['name'] ?? "Belirtilmemiş",
                      "E-posta": userData['email'] ?? "Belirtilmemiş",
                    }),
                    const SizedBox(height: 15),
                    _buildInfoCard("Sağlık Bilgileri", {
                      "Kan Grubu": userData['bloodType'] ?? "Girilmemiş",
                      "Alerjiler": userData['allergies'] ?? "Yok",
                      "Hastalıklar": userData['chronicIllness'] ?? "Yok",
                    }),
                    const SizedBox(height: 30),
                    const Text("Dijital Erişim Kodunuz", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: QrImageView(
                          data: bagId ?? user.uid, // bagId varsa onu yoksa uid'yi basar
                          version: QrVersions.auto,
                          size: 160.0,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFFD32F2F)),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Oturumu Kapat"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, Map<String, String> details) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(title == "Sağlık Bilgileri" ? Icons.medical_services : Icons.badge, size: 20, color: const Color(0xFFD32F2F)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
            ]),
            const Divider(height: 25),
            ...details.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(e.value, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}