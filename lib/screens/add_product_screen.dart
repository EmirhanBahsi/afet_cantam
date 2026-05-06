import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';

class AddProductScreen extends StatefulWidget {
  final String bagId;
  const AddProductScreen({super.key, required this.bagId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedCategory = 'Gıda';

  // Kategori listesi ve ikonları
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Gıda', 'icon': Icons.fastfood_rounded, 'color': Colors.orange},
    {'name': 'Sağlık', 'icon': Icons.medication_rounded, 'color': Colors.redAccent},
    {'name': 'Hijyen', 'icon': Icons.clean_hands_rounded, 'color': Colors.blue},
    {'name': 'Araç-Gereç', 'icon': Icons.handyman_rounded, 'color': Colors.teal},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Yeni Eşya Ekle"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ürün Bilgileri",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Ürün Adı Girişi
            _buildInputField(
              controller: _nameController,
              label: "Eşya Adı",
              hint: "Örn: Konserve, Bandaj...",
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 20),

            // Adet Girişi
            _buildInputField(
              controller: _amountController,
              label: "Adet / Miktar",
              hint: "Örn: 2",
              icon: Icons.numbers_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),

            // Kategori Seçimi
            const Text(
              "Kategori Seçin",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((cat) => _buildCategoryChip(cat)).toList(),
            ),

            const SizedBox(height: 50),

            // Kaydet Butonu
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
              ),
              onPressed: () async {
                if (_nameController.text.isEmpty || _amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lütfen tüm alanları doldurun!")),
                  );
                  return;
                }

                Product newProduct = Product(
                  id: '',
                  name: _nameController.text,
                  category: _selectedCategory,
                  amount: int.parse(_amountController.text),
                );

                await AuthService().addProduct(widget.bagId, newProduct);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text(
                "Çantaya Ekle",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern Input Tasarımı
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: const Color(0xFFD32F2F)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  // Kategori Seçim Kutucuğu
  Widget _buildCategoryChip(Map<String, dynamic> cat) {
    bool isSelected = _selectedCategory == cat['name'];
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? cat['color'] : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected 
            ? [BoxShadow(color: cat['color'].withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
          border: Border.all(color: isSelected ? cat['color'] : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cat['icon'], color: isSelected ? Colors.white : cat['color'], size: 20),
            const SizedBox(width: 8),
            Text(
              cat['name'],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}