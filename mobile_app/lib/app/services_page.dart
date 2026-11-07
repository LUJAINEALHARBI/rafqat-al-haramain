import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// صفحة «خدمات الحملة» للحاج:
/// تعرض كل الخدمات المتاحة مجمّعة حسب التخصص، كما يضيفها ويعدّلها
/// مشرف كل تخصص من لوحته — المصدر جدول services عبر api/services.php
class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);
  static const Color background = Color(0xFFF6FAFA);

  static const List<String> typeOrder = [
    'medical',
    'crowd',
    'catering',
    'housing',
    'general',
  ];

  static const Map<String, String> typeLabels = {
    'medical': 'الرعاية الطبية',
    'crowd': 'التفويج والتنقل',
    'catering': 'الإعاشة والوجبات',
    'housing': 'السكن وخدمة الحجاج',
    'general': 'خدمات عامة',
  };

  static const Map<String, IconData> typeIcons = {
    'medical': Icons.medical_services_rounded,
    'crowd': Icons.directions_bus_rounded,
    'catering': Icons.restaurant_rounded,
    'housing': Icons.hotel_rounded,
    'general': Icons.widgets_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.services(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            backgroundColor: background,
            appBar: _bar(),
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

  AppBar _bar() => AppBar(
        title: const Text('خدمات الحملة'),
        centerTitle: true,
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
      );

  Widget _buildUi(BuildContext context, List<dynamic> all) {
    final rows = all
        .whereType<Map>()
        .where((r) => (r['status'] ?? '').toString() == 'متاحة')
        .toList();

    final Map<String, List<Map>> groups = {};
    for (final r in rows) {
      var t = (r['service_type'] ?? 'general').toString();
      if (!typeLabels.containsKey(t)) t = 'general';
      groups.putIfAbsent(t, () => <Map>[]).add(r);
    }

    final sections = typeOrder.where(groups.containsKey).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: _bar(),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [darkGreen, green]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  Icon(Icons.room_service_rounded,
                      color: Colors.white, size: 46),
                  SizedBox(height: 12),
                  Text(
                    'خدمات الحملة المتاحة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'يحدّثها مشرف كل تخصص فتظهر لك مباشرة',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (sections.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'لا توجد خدمات متاحة حالياً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            for (final t in sections) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                child: Row(
                  children: [
                    Icon(typeIcons[t], color: green, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      typeLabels[t] ?? 'خدمات',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: darkGreen,
                      ),
                    ),
                  ],
                ),
              ),
              ...groups[t]!.map((r) => _tile(r)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(Map r) {
    final name = (r['service_name'] ?? '').toString();
    final desc = (r['description'] ?? '').toString();
    final place = (r['service_location'] ?? '').toString();
    final dt = (r['service_datetime'] ?? '').toString();
    final time = dt.length >= 16 ? dt.substring(11, 16) : '';

    final meta = <String>[
      if (time.isNotEmpty) 'الموعد: $time',
      if (place.isNotEmpty) 'المكان: $place',
    ].join('   •   ');

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: darkGreen,
              ),
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(desc, style: const TextStyle(color: Colors.black87)),
            ],
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                meta,
                style: const TextStyle(color: Colors.black54, fontSize: 12.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
