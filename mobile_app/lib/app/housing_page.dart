import 'package:flutter/material.dart';

class HousingPage extends StatelessWidget {
  const HousingPage({super.key});

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
    'اسم السكن': Icons.hotel_rounded,
    'الموقع': Icons.location_on_rounded,
    'رقم المخيم': Icons.location_city_rounded,
    'رقم الغرفة': Icons.meeting_room_rounded,
    'موعد الوصول': Icons.login_rounded,
    'موعد المغادرة': Icons.logout_rounded,
  };

  @override
  Widget build(BuildContext context) {
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
            ...housingInfo.entries.map((entry) {
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