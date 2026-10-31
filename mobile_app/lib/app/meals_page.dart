import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MealsPage extends StatelessWidget {
  const MealsPage({super.key});

  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);

  final List<Map<String, dynamic>> meals = const [
    {
      'title': 'الإفطار',
      'time': 'صباحًا',
      'description': 'تفاصيل وجبة الإفطار يحددها مشرف الإعاشة.',
      'icon': Icons.free_breakfast_rounded,
      'color': Color(0xFFE6A23C),
    },
    {
      'title': 'الغداء',
      'time': 'ظهرًا',
      'description': 'تفاصيل وجبة الغداء يحددها مشرف الإعاشة.',
      'icon': Icons.lunch_dining_rounded,
      'color': Color(0xFF4C9A80),
    },
    {
      'title': 'العشاء',
      'time': 'مساءً',
      'description': 'تفاصيل وجبة العشاء يحددها مشرف الإعاشة.',
      'icon': Icons.dinner_dining_rounded,
      'color': Color(0xFF8B79D9),
    },
  ];

  @override
  Widget build(BuildContext context) {
    // المحتوى يُقرأ من جدول services عبر api/services.php
    return FutureBuilder<List<dynamic>>(
      future: ApiService.servicesOfType('catering'),
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
              title: const Text('جدول الوجبات'),
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
        return _buildUi(context, snap.data ?? const []);
      },
    );
  }

  Widget _buildUi(BuildContext context, List<dynamic> rows) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAFA),
        appBar: AppBar(
          title: const Text('جدول الوجبات'),
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
                    Icons.restaurant_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'وجبات الحملة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 23,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'تابع مواعيد وجباتك اليومية',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            ...List.generate(rows.length, (i) {
              final r = rows[i] as Map;
              final base = meals[i % meals.length];
              final meal = {
                'title': (r['service_name'] ?? '').toString(),
                'time': (r['service_location'] ?? '').toString(),
                'description': (r['description'] ?? '').toString(),
                'icon': base['icon'],
                'color': base['color'],
              };
              final color = meal['color'] as Color;

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      meal['icon'] as IconData,
                      color: color,
                      size: 30,
                    ),
                  ),
                  title: Text(
                    meal['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                      fontSize: 17,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${meal['time']}\n${meal['description']}',
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            }),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'لا توجد وجبات مسجلة في قاعدة البيانات.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'ملاحظة: المواعيد الفعلية وتفاصيل الوجبات تعتمد على جدول الحملة المعتمد.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}