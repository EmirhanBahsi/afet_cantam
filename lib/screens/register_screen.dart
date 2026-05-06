import 'package:afet_cantam/screens/home_screen.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'qr_scanner_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Yeni Profil Oluştur"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Üst Kısım Açıklama
            const Text(
              "Hemen Kaydolun",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Afet çantanızı yönetmek için bilgilerinizi girin.",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),

            // Giriş Alanları
            _buildCustomTextField(
              controller: _nameController,
              label: "Ad Soyad",
              icon: Icons.person_outline,
              hint: "Örn: Mustafa Kemal",
            ),
            const SizedBox(height: 20),
            _buildCustomTextField(
              controller: _emailController,
              label: "E-posta",
              icon: Icons.email_outlined,
              hint: "example@mail.com",
            ),
            const SizedBox(height: 20),
            _buildCustomTextField(
              controller: _passwordController,
              label: "Şifre",
              icon: Icons.lock_outline,
              hint: "En az 6 karakter",
              isPassword: true,
            ),
            const SizedBox(height: 40),

            // Kayıt Butonu (Hoşuna giden kart tarzında)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 5,
                shadowColor: const Color(0xFFD32F2F).withOpacity(0.4),
              ),
              onPressed: () async {
                String email = _emailController.text.trim();
                String password = _passwordController.text.trim();
                String name = _nameController.text.trim();

                // Kayıt işlemini başlatıyoruz
                bool success = await _authService.registerWithEmail(
                  email,
                  password,
                  name,
                );

                if (success && context.mounted) {
                  // 1. Kayıt başarılıysa, Firebase'in o an açtığı oturumu alıyoruz
                  final currentUser = FirebaseAuth.instance.currentUser;

                  if (currentUser != null) {
                    // 2. Artık 'user.uid' yerine 'currentUser.uid' kullanarak geçiş yapabiliriz
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HomeScreen(bagId: currentUser.uid),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kayıt başarısız!")),
                  );
                }
              },
              child: const Text(
                "Profilimi Oluştur",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern TextField Yardımcı Fonksiyonu
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(icon, color: const Color(0xFFD32F2F)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
