import 'package:flutter/material.dart';

class TransportPage extends StatelessWidget {
  const TransportPage({super.key});

  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);

  final List<Map<String, dynamic>> trips = const [
    {
      'title': 'رحلات الحافلات',
      'description': 'تابع موعد الرحلة مع مشرف النقل',
      'icon': Icons.directions_bus_rounded,
      'color': Color(0xFF5C9DED),
    },
    {
      'title': 'نقطة التجمع',
      'description': 'تأكد من موقع التجمع قبل التحرك',
      'icon': Icons.location_on_rounded,
      'color': Color(0xFFE6A23C),
    },
    {
      'title': 'جدول التنقل',
      'description': 'راجع مواعيد التنقل المعتمدة للحملة',
      'icon': Icons.schedule_rounded,
      'color': Color(0xFF8B79D9),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAFA),
        appBar: AppBar(
          title: const Text('النقل والتنقل'),
          centerTitle: true,
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              width: double.infinity,
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
                    Icons.directions_bus_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'تنقلات الحملة',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'معلومات الرحلات ونقاط التجمع',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            ...trips.map((trip) {
              final color = trip['color'] as Color;

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      trip['icon'] as IconData,
                      color: color,
                      size: 29,
                    ),
                  ),
                  title: Text(
                    trip['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      trip['description'] as String,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            const Text(
              'ملاحظة: مواعيد الرحلات ومواقع التجمع الفعلية يضيفها مشرف النقل.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}