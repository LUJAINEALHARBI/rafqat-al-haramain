import 'package:flutter/material.dart';

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
            ...meals.map((meal) {
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