import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product_model.dart';
import '../../services/auth_service.dart';
import 'expiry_scanner_screen.dart'; // Import the new OCR scanner
import 'package:afet_cantam/notification_service.dart';

class AddProductScreen extends StatefulWidget {
  final String bagId;
  const AddProductScreen({super.key, required this.bagId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _expiryController = TextEditingController();

  String _selected = 'Gıda';
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _cats() => [
    {
      'key': 'Gıda',
      'label': 'cat_food'.tr(),
      'icon': Icons.fastfood_rounded,
      'color': const Color(0xFFF59E0B),
    },
    {
      'key': 'Sağlık',
      'label': 'cat_health'.tr(),
      'icon': Icons.medication_rounded,
      'color': const Color(0xFFEF4444),
    },
    {
      'key': 'Hijyen',
      'label': 'cat_hygiene'.tr(),
      'icon': Icons.clean_hands_rounded,
      'color': const Color(0xFF0EA5E9),
    },
    {
      'key': 'Araç-Gereç',
      'label': 'cat_tools'.tr(),
      'icon': Icons.handyman_rounded,
      'color': const Color(0xFF10B981),
    },
  ];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final product = Product(
        id: '',
        name: _nameController.text.trim(),
        category: _selected,
        amount: int.parse(_amountController.text.trim()),
        expiryDate: (_selected == 'Gıda' || _selected == 'Sağlık')
            ? _expiryController.text.trim()
            : null,
      );

      // 1. Ürünü veritabanına ekliyoruz
      await AuthService().addProduct(widget.bagId, product);

      // 2. Eğer ürün Gıda ise ve Son Kullanma Tarihi girildiyse BİLDİRİM ZAMANLA
      if (_selected == 'Gıda' && _expiryController.text.isNotEmpty) {
        try {
          // 'dd.MM.yyyy' formatındaki string tarihi DateTime nesnesine çeviriyoruz
          List<String> dateParts = _expiryController.text.split('.');
          if (dateParts.length == 3) {
            int day = int.parse(dateParts[0]);
            int month = int.parse(dateParts[1]);
            int year = int.parse(dateParts[2]);

            // Son kullanma tarihi (Saat sabah 10:00 olarak ayarlıyoruz)
            DateTime expiryDateTime = DateTime(year, month, day, 10, 0);

            // Son kullanma tarihinden kaç gün önce haber versin? (Örn: 7 gün önce)
            // Son kullanma tarihini tamamen boşverip, ürünü eklediğin andan tam 1 dakika sonrasına alarm kurar
            DateTime notificationDateTime = DateTime.now().add(
              const Duration(minutes: 1),
            );

            // Eğer hesaplanan bildirim tarihi bugünden ilerideyse bildirimi kur
            if (notificationDateTime.isAfter(DateTime.now())) {
              // Ürün ismi ve tarih kombinasyonundan benzersiz bir ID üretiyoruz (İptal edebilmek için)
              int notificationId =
                  (_nameController.text.trim() + _expiryController.text)
                      .hashCode
                      .abs();

              // notification_service.dart dosyasını en üste import etmeyi unutma!
              await NotificationService().scheduleNotification(
                id: notificationId,
                title: "Afet Çantası Uyarısı! 🚨",
                body:
                    "${_nameController.text.trim()} ürününün son kullanma tarihine 1 hafta kaldı!",
                scheduledDate: notificationDateTime,
              );
            }
          }
        } catch (e) {
          debugPrint("Bildirim ayarlanırken hata oluştu: $e");
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_something_went_wrong'.tr()),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _expiryController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  Future<void> _startExpiryScanner() async {
    final scannedDate = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ExpiryScannerScreen()),
    );

    if (scannedDate != null && mounted) {
      setState(() {
        _expiryController.text = scannedDate;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'expiry_scanned_success'.tr()}: $scannedDate'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'add_item_title'.tr(),
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
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          physics: const BouncingScrollPhysics(),
          child: _formCard(),
        ),
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 40,
            color: const Color(0xFF0F172A).withOpacity(.04),
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'add_item_info_header'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 20),
            _field(
              controller: _nameController,
              hint: 'hint_item_name'.tr(),
              icon: Icons.inventory_2_outlined,
              validator: (v) =>
                  v == null || v.isEmpty ? 'error_empty_field'.tr() : null,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _amountController,
              hint: 'hint_item_amount'.tr(),
              icon: Icons.numbers_rounded,
              type: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'error_empty_field'.tr();
                if (int.tryParse(v) == null) return 'error_invalid_amount'.tr();
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'add_item_category_header'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryDropdown(),

            if (_selected == 'Gıda' || _selected == 'Sağlık') ...[
              const SizedBox(height: 20),
              Text(
                'add_item_expiry_header'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              _field(
                controller: _expiryController,
                hint: 'hint_expiry_date'.tr(),
                icon: Icons.calendar_today_rounded,
                readOnly: true,
                onTap: _pickDate,
                suffix: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF6366F1),
                      ),
                      tooltip: 'tooltip_scan_skt'.tr(),
                      onPressed: _startExpiryScanner,
                    ),
                  ],
                ),
                validator: (v) {
                  if ((_selected == 'Gıda' || _selected == 'Sağlık') &&
                      (v == null || v.isEmpty)) {
                    return 'error_empty_expiry'.tr();
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 34),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFF94A3B8,
                  ).withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text('btn_add_to_bag'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selected,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
      ),
      items: _cats().map((c) {
        return DropdownMenuItem<String>(
          value: c['key'],
          child: Row(
            children: [
              Icon(c['icon'], color: c['color'], size: 20),
              const SizedBox(width: 12),
              Text(
                c['label'],
                style: const TextStyle(color: Color(0xFF0F172A)),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selected = val;
            // Eğer yeni seçilen kategori hem Gıda hem Sağlık değilse (Hijyen veya Araç-Gereç ise) tarihi temizle:
            if (_selected != 'Gıda' && _selected != 'Sağlık') {
              _expiryController.clear();
            }
          });
        }
      },
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      inputFormatters: formatters,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}
