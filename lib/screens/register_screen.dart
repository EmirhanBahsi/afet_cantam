
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'qr_scanner_screen.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Afet Çantası Kayıt")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.emergency_share, size: 80, color: Color(0xFFD32F2F)),
              const SizedBox(height: 20),
              const Text("Yeni Hesap Oluştur", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Ad Soyad", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "E-posta", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Şifre", border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 30),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: const Color(0xFFD32F2F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm alanları doldurun!")));
                    return;
                  }

                  // Kayıt işlemini başlat
                  bool success = await _authService.registerWithEmail(
                    _emailController.text, 
                    _passwordController.text, 
                    _nameController.text
                  );

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt Başarılı!")));
                    // QR Tarama ekranına geç
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt başarısız! İnternetinizi veya bilgileri kontrol edin.")));
                  }
                },
                child: const Text("Kayıt Ol ve Çantanı Tara", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScannerScreen())),
                child: const Text("Zaten bir çantam var (QR Tara)"),
              ),
            ], 
          ),
        ),
      ),
    );
  }
}