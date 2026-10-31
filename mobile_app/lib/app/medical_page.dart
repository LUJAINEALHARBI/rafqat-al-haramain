import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MedicalPage extends StatelessWidget {
  const MedicalPage({super.key});

  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);

  final List<Map<String, dynamic>> services = const [
    {
      'title': 'طلب مساعدة طبية',
      'description': 'تواصل مع مشرف الرعاية الطبية عند الحاجة',
      'icon': Icons.medical_services_rounded,
    },
    {
      'title': 'موقع نقطة الرعاية',
      'description': 'راجع موقع النقطة الطبية المعتمدة للحملة',
      'icon': Icons.location_on_rounded,
    },
    {
      'title': 'إرشادات صحية',
      'description': 'حافظ على شرب الماء والراحة وتجنب الإجهاد',
      'icon': Icons.health_and_safety_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // المحتوى يُقرأ من جدول services عبر api/services.php
    return FutureBuilder<List<dynamic>>(
      future: ApiService.servicesOfType('medical'),
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
              title: const Text('الرعاية الطبية'),
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
          title: const Text('الرعاية الطبية'),
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [green, darkGreen],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.health_and_safety_rounded,
                    color: Colors.white,
                    size: 55,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'صحتك تهمنا',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'خدمات الرعاية الصحية لحجاج حملة رفقة بلاد الحرمين',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(rows.length, (i) => ((){
              final r = rows[i] as Map;
              final base = services[i % services.length];
              return {
                'title': (r['service_name'] ?? '').toString(),
                'description': [
                  (r['description'] ?? '').toString(),
                  if ((r['service_location'] ?? '').toString().isNotEmpty)
                    'الموقع: ${r['service_location']}',
                ].where((e) => e.isNotEmpty).join('\n'),
                'icon': base['icon'],
              };
            })()).map(
              (service) => Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    backgroundColor: green.withValues(alpha: 0.12),
                    child: Icon(
                      service['icon'] as IconData,
                      color: green,
                    ),
                  ),
                  title: Text(
                    service['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      service['description'] as String,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'في الحالات الطارئة، تواصل مباشرة مع الطوارئ أو أقرب نقطة طبية.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}