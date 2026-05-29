import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../auth/welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String? bagId;
  const ProfileScreen({super.key, this.bagId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
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
            title: Text(
              'profile_title'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildLanguagePicker(context),
              ),
            ],
          ),
        ),
      ),
      body: user == null
          ? _error(context, 'error_no_session'.tr())
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>? ?? {};

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _hero(context, data, user.email),
                  const SizedBox(height: 20),
                  _infoCard(context, data),
                  const SizedBox(height: 20),
                  _qrCard(context, bagId ?? user.uid),
                  const SizedBox(height: 30),
                  _logout(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguagePicker(BuildContext context) {
    return PopupMenuButton<Locale>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.language, size: 20, color: Colors.white),
      ),
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      onSelected: (l) => context.setLocale(l),
      itemBuilder: (_) => const [
        PopupMenuItem(value: Locale('tr'), child: Text('🇹🇷 Türkçe')),
        PopupMenuItem(value: Locale('en'), child: Text('🇺🇸 English')),
      ],
    );
  }

  Widget _hero(
      BuildContext context, Map<String, dynamic> data, String? email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(.04),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: const Color(0xFFEEF2FF),
            child: const Icon(Icons.person_rounded, size: 48, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 16),
          Text(
            data['name'] ?? 'profile_user_placeholder'.tr(),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email ?? '',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _localizeValue(BuildContext context, String? value, {bool isBloodType = false}) {
    final isTr = context.locale.languageCode == 'tr';

    if (value == null) {
      if (isBloodType) return '-';
      return isTr ? 'Yok' : 'None';
    }

    final cleanVal = value.trim().toLowerCase();
    final emptyPlaceholders = [
      '',
      '-',
      'yok',
      'none',
      'girilmemiş',
      'girilmemis',
      'belirtilmemiş',
      'belirtilmemis',
      'not specified',
      'not_specified'
    ];

    if (emptyPlaceholders.contains(cleanVal)) {
      if (isBloodType) return '-';
      return isTr ? 'Yok' : 'None';
    }

    return value;
  }

  Widget _infoCard(BuildContext context, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(.04),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile_health_info'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          _row(
            context,
            'profile_blood_type'.tr(),
            _localizeValue(context, data['bloodType'], isBloodType: true),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 24, thickness: 1),
          _row(
            context,
            'profile_allergies'.tr(),
            _localizeValue(context, data['allergies']),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 24, thickness: 1),
          _row(
            context,
            'profile_illnesses'.tr(),
            _localizeValue(context, data['chronicIllness']),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          k,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          v,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _qrCard(BuildContext context, String data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(.04),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'QR ID',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: QrImageView(
              data: data,
              size: 160,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logout(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE2E2),
          foregroundColor: const Color(0xFFEF4444),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();

          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const WelcomeScreen(),
              ),
                  (_) => false,
            );
          }
        },
        child: Text(
          'profile_logout'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _error(BuildContext context, String msg) {
    return Center(
      child: Text(
        msg,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}