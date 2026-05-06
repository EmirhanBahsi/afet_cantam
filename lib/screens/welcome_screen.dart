import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'qr_scanner_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Uygulama Logosu veya İkonu
              const Icon(Icons.emergency_outlined, size: 80, color: Color(0xFFD32F2F)),
              const SizedBox(height: 10),
              const Text(
                "Afet Çantam",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 40),

              // 1. KART: YENİ KAYIT
              _buildMenuCard(
                context,
                title: "Yeni Kayıt",
                subtitle: "Yeni bir afet çantası profili oluşturun",
                icon: Icons.person_add_outlined,
                color: const Color(0xFFD32F2F),
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const RegisterScreen())
                ),
              ),

              const SizedBox(height: 20),

              // 2. KART: VAR OLAN KAYIT
              _buildMenuCard(
                context,
                title: "Var Olan Kayıt",
                subtitle: "Çantanızdaki QR kodu tarayarak giriş yapın",
                icon: Icons.qr_code_scanner_outlined,
                color: Colors.blueGrey,
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const QrScannerScreen())
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kart Tasarım Yardımcı Fonksiyonu
  Widget _buildMenuCard(BuildContext context, 
      {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 35, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}