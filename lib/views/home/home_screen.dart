import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../product/add_product_screen.dart';
import '../profile/profile_screen.dart';
import '../../notification_service.dart'; // Bildirim servisi import edildi

class HomeScreen extends StatelessWidget {
  final String bagId;
  const HomeScreen({super.key, required this.bagId});

  Color _categoryColor(String category, ColorScheme cs) {
    switch (category) {
      case 'Food':
      case 'Gıda':
        return const Color(0xFFF59E0B);
      case 'Health':
      case 'Sağlık':
        return const Color(0xFFEF4444);
      case 'Hygiene':
      case 'Hijyen':
        return const Color(0xFF0EA5E9);
      case 'Tools':
      case 'Araç-Gereç':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food':
      case 'Gıda':
        return Icons.fastfood_rounded;
      case 'Health':
      case 'Sağlık':
        return Icons.medication_rounded;
      case 'Hygiene':
      case 'Hijyen':
        return Icons.clean_hands_rounded;
      case 'Tools':
      case 'Araç-Gereç':
        return Icons.handyman_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF6366F1),
            boxShadow: [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            title: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'home_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(bagId)
                        .snapshots(),
                    builder: (context, snap) {
                      final data = snap.data?.data() as Map<String, dynamic>?;
                      return Text(
                        data?['name'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: IconButton(
                    icon: const Icon(Icons.person, color: Colors.white, size: 20),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(bagId: bagId),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddProductScreen(bagId: bagId)),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          'home_add_item'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bags')
                    .doc(bagId)
                    .collection('items')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return _EmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final product = Product.fromMap(data, docs[i].id);

                      final color = _categoryColor(product.category, cs);
                      final icon = _categoryIcon(product.category);

                      return _ProductCard(
                        name: product.name,
                        amount: product.amount,
                        category: product.category,
                        icon: icon,
                        color: color,
                        onDelete: () => _showDelete(
                          context,
                          docs[i].reference,
                          product.name,
                          product.expiryDate, // Son kullanma tarihi eklendi
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDelete(
      BuildContext context,
      DocumentReference ref,
      String name,
      String? expiryDate,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          context.locale.languageCode == 'tr' ? 'Sil' : 'Delete',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          context.locale.languageCode == 'tr'
              ? '$name silinsin mi?'
              : 'Do you want to delete $name?',
          style: const TextStyle(color: Color(0xFF475569), fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: Text(context.locale.languageCode == 'tr' ? 'İptal' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () async {
              // Eğer silinen ürünün bir son kullanma tarihi varsa, onun bildirimini iptal et
              if (expiryDate != null && expiryDate.isNotEmpty) {
                int notificationId = (name + expiryDate).hashCode.abs();
                await NotificationService().cancelNotification(notificationId);
              }

              ref.delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(context.locale.languageCode == 'tr' ? 'Sil' : 'Delete'),
          )
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String name;
  final int amount;
  final String category;
  final IconData icon;
  final Color color;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.name,
    required this.amount,
    required this.category,
    required this.icon,
    required this.color,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.locale.languageCode == 'tr'
                      ? '$category • $amount adet'
                      : '$category • $amount pcs',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFF94A3B8), size: 22),
          )
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.locale.languageCode == 'tr'
                ? 'Henüz ürün eklenmemiş'
                : 'No items yet',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.locale.languageCode == 'tr'
                ? 'Eklemek için aşağıdaki butonu kullanın'
                : 'Use the button below to add items',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}