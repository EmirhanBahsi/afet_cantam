import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'add_product_screen.dart';
import 'profile_screen.dart'; // Profil sayfası import edildi

class HomeScreen extends StatelessWidget {
  final String bagId;
  const HomeScreen({super.key, required this.bagId});

  // Kategori İkonu Yardımcı Fonksiyonu
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Gıda': return Icons.fastfood;
      case 'Sağlık': return Icons.medical_services;
      case 'Hijyen': return Icons.clean_hands;
      case 'Araç-Gereç': return Icons.build;
      default: return Icons.inventory_2;
    }
  }

  // Kategori Rengi Yardımcı Fonksiyonu
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Gıda': return Colors.orange;
      case 'Sağlık': return Colors.redAccent;
      case 'Hijyen': return Colors.blue;
      case 'Araç-Gereç': return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Afet Çantası İçeriği"),
        elevation: 4,
        automaticallyImplyLeading: false,
        // --- PROFİL İKONU BURAYA EKLENDİ ---
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(bagId: bagId)),
              );
            },
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
          if (snapshot.hasError) return const Center(child: Text("Hata oluştu!"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("Çantada henüz ürün yok. Hemen ekle!"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 80),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              Product product = Product.fromMap(
                docs[index].data() as Map<String, dynamic>, 
                docs[index].id
              );

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: _getCategoryColor(product.category).withOpacity(0.2),
                    child: Icon(
                      _getCategoryIcon(product.category), 
                      color: _getCategoryColor(product.category),
                      size: 28,
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    "Kategori: ${product.category}\nAdet: ${product.amount}",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      // --- SİLME ONAY PENCERESİ ---
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Eşyayı Sil"),
                          content: Text("${product.name} silinecek. Emin misiniz?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("İptal"),
                            ),
                            TextButton(
                              onPressed: () {
                                docs[index].reference.delete();
                                Navigator.pop(context);
                              },
                              child: const Text("Sil", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen(bagId: bagId)),
          );
        },
        label: const Text("Yeni Eşya"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}