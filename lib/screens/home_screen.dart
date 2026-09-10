import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'add_product_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final String bagId;
  const HomeScreen({super.key, required this.bagId});

  // Kategoriye özel stil belirleme
  Map<String, dynamic> _getCategoryStyle(String category) {
    switch (category) {
      case 'Gıda': return {'icon': Icons.fastfood_rounded, 'color': Colors.orange};
      case 'Sağlık': return {'icon': Icons.medication_rounded, 'color': Colors.redAccent};
      case 'Hijyen': return {'icon': Icons.clean_hands_rounded, 'color': Colors.blue};
      case 'Araç-Gereç': return {'icon': Icons.handyman_rounded, 'color': Colors.teal};
      default: return {'icon': Icons.inventory_2_rounded, 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Afet Çantam",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                  // Kendi elindeki bagId bilgisini profil sayfasına pasla!
                  builder: (context) => ProfileScreen(bagId: bagId), 
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Color(0xFFD32F2F), size: 28),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bags')
            .doc(bagId)
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              Product product = Product.fromMap(
                docs[index].data() as Map<String, dynamic>, 
                docs[index].id
              );
              final style = _getCategoryStyle(product.category);

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: style['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(style['icon'], color: style['color'], size: 30),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      children: [
                        _buildBadge(product.category, style['color']),
                        const SizedBox(width: 8),
                        Text("Adet: ${product.amount}", style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () => _showDeleteDialog(context, docs[index].reference, product.name),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddProductScreen(bagId: bagId)),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Yeni Eşya Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Yardımcı UI Fonksiyonları
  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text("Çantanız şu an boş", style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text("Eklemek için aşağıdaki butonu kullanın."),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, DocumentReference ref, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Eşyayı Sil"),
        content: Text("$name çantanızdan çıkarılacak. Emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              ref.delete();
              Navigator.pop(context);
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}