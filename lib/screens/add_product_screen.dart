import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';

class AddProductScreen extends StatefulWidget {
  final String bagId; // Hangi çantaya ekleneceğini bilmemiz lazım
  const AddProductScreen({super.key, required this.bagId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedCategory = 'Gıda'; // Varsayılan kategori

  final List<String> _categories = [
    'Gıda',
    'Sağlık',
    'Hijyen',
    'Araç-Gereç',
    'Diğer',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Eşya Ekle")),
      // add_product_screen.dart içinde Column yapısını güncelle:
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          // Klavye açılınca ekran taşmasın diye
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Buton tam genişlik olsun
            children: [
              // Tasarım Dokunuşu: Giriş kutularını ikonlu hale getirelim
              const Text(
                "Ürün Bilgileri",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Ürün Adı",
                  prefixIcon: Icon(Icons.shopping_basket_outlined),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: "Adet",
                  prefixIcon: Icon(Icons.add_shopping_cart),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField(
                value: _selectedCategory,
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedCategory = val as String),
                decoration: const InputDecoration(
                  labelText: "Kategori",
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  final newProduct = Product(
                    id: '', // Firestore otomatik ID verecek
                    name: _nameController.text,
                    amount: int.parse(_amountController.text),
                    category: _selectedCategory,
                  );

                  await AuthService().addProduct(widget.bagId, newProduct);
                  Navigator.pop(context); // Ekledikten sonra geri dön
                },
                icon: const Icon(Icons.check),
                label: const Text("Çantaya Ekle"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
