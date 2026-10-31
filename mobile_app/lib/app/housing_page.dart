import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HousingPage extends StatelessWidget {
  /// رقم عضوية الحاج — تُقرأ بياناته من جدول pilgrims
  final String pilgrimId;

  const HousingPage({super.key, required this.pilgrimId});

  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);

  final Map<String, String> housingInfo = const {
    'اسم السكن': 'سكن حملة رفقة بلاد الحرمين',
    'الموقع': 'يحدد من إدارة الحملة',
    'رقم المخيم': 'يحدد عند توزيع الحجاج',
    'رقم الغرفة': 'يحدد عند تسجيل بيانات الحاج',
    'موعد الوصول': 'حسب جدول الرحلة',
    'موعد المغادرة': 'حسب جدول الرحلة',
  };

  final Map<String, IconData> housingIcons = const {
    'اسم الحاج': Icons.person_rounded,
    'رقم الحجز': Icons.confirmation_number_rounded,
    'رقم المخيم': Icons.location_city_rounded,
    'رقم الخيمة': Icons.hotel_rounded,
    'رقم السرير': Icons.bed_rounded,
    'نوع الباقة': Icons.card_membership_rounded,
    'نقطة التجمع': Icons.location_on_rounded,
    'المشرف المسؤول': Icons.supervisor_account_rounded,
  };

  @override
  Widget build(BuildContext context) {
    // بيانات السكن تُقرأ من جدول pilgrims عبر api/pilgrims.php?action=get
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.pilgrimProfile(pilgrimId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFFF6FAFA),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF6FAFA),
            appBar: AppBar(
              title: const Text('بيانات السكن'),
              centerTitle: true,
              backgroundColor: darkGreen,
              foregroundColor: Colors.white,
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'تعذّر التحميل من قاعدة البيانات:\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }
        return _buildUi(context, snap.data ?? const {});
      },
    );
  }

  Widget _buildUi(BuildContext context, Map<String, dynamic> me) {
    String v(String k) {
      final x = me[k];
      if (x == null || x.toString().trim().isEmpty) return 'غير محدد';
      return x.toString();
    }

    final info = <String, String>{
      'اسم الحاج': v('name'),
      'رقم الحجز': v('booking_number'),
      'رقم المخيم': v('camp_id'),
      'رقم الخيمة': v('tent_number'),
      'رقم السرير': v('bed_number'),
      'نوع الباقة': v('package_type'),
      'نقطة التجمع': v('gathering_point'),
      'المشرف المسؤول': v('supervisor_name'),
    };

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAFA),
        appBar: AppBar(
          title: const Text(
            'بيانات السكن',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [darkGreen, green],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.hotel_rounded,
                    color: Colors.white,
                    size: 54,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'سكن الحاج',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'جميع معلومات السكن في مكان واحد',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            ...info.entries.map((entry) {
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4F4F2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      housingIcons[entry.key],
                      color: green,
                      size: 27,
                    ),
                  ),
                  title: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(entry.value),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}