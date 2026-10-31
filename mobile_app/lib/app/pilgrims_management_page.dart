import 'package:flutter/material.dart';
import '../services/api_service.dart';

const Color pilgrimsGreen = Color(0xFF277D78);
const Color pilgrimsDark = Color(0xFF244C4A);

class PilgrimsManagementPage extends StatelessWidget {
  const PilgrimsManagementPage({super.key});

  static const List<Map<String, String>> pilgrims = [
    {
      'name': 'حاج تجريبي 1',
      'id': '1000000001',
      'camp': 'منى',
      'room': '101',
      'status': 'مكتمل',
    },
    {
      'name': 'حاج تجريبي 2',
      'id': '1000000002',
      'camp': 'مزدلفة',
      'room': '202',
      'status': 'قيد المراجعة',
    },
    {
      'name': 'حاج تجريبي 3',
      'id': '1000000003',
      'camp': 'عرفة',
      'room': '303',
      'status': 'مكتمل',
    },
    {
      'name': 'حاج تجريبي 4',
      'id': '1000000004',
      'camp': 'مكة',
      'room': '404',
      'status': 'مكتمل',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // قائمة الحجاج تُقرأ من جدول pilgrims عبر api/pilgrims.php?action=list
    return FutureBuilder<List<dynamic>>(
      future: ApiService.pilgrims(),
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
            appBar: AppBar(title: const Text('إدارة الحجاج'), centerTitle: true),
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
          title: const Text('إدارة الحجاج'),
          backgroundColor: pilgrimsDark,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'إدارة بيانات الحجاج',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: pilgrimsDark,
              ),
            ),
            const SizedBox(height: 16),
            _section(
              context,
              'توزيع المخيمات والغرف',
              'عرض مواقع منى ومزدلفة وعرفة ومكة',
              Icons.location_on_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CampDistributionPage(),
                ),
              ),
            ),
            _section(
              context,
              'طلبات الحجاج وملاحظاتهم',
              'عرض الطلبات والملاحظات المسجلة',
              Icons.assignment_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PilgrimRequestsPage(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'أسماء الحجاج',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: pilgrimsDark,
              ),
            ),
            const SizedBox(height: 10),
            ...rows.map((row) {
              final r = row as Map;
              final pilgrim = <String, String>{
                'name': (r['name'] ?? '').toString(),
                'id': (r['pilgrim_id'] ?? '').toString(),
                'camp': (r['camp_id'] ?? r['city'] ?? '').toString(),
                'room': (r['tent_number'] ?? '').toString(),
                'status': (r['package_type'] ?? '').toString(),
              };
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2E9),
                    child: Icon(
                      Icons.person_rounded,
                      color: pilgrimsGreen,
                    ),
                  ),
                  title: Text(
                    pilgrim['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'رقم الحاج: ${pilgrim['id']}\n'
                    'الموقع: ${pilgrim['camp']} - الغرفة ${pilgrim['room']}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: pilgrimsGreen,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PilgrimDetailsPage(
                          pilgrim: pilgrim,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  static Widget _section(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0F2E9),
          child: Icon(Icons.folder_open_rounded, color: pilgrimsGreen),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(icon, color: pilgrimsGreen),
        onTap: onTap,
      ),
    );
  }
}

class PilgrimDetailsPage extends StatelessWidget {
  final Map<String, String> pilgrim;

  const PilgrimDetailsPage({
    super.key,
    required this.pilgrim,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بيانات الحاج'),
          backgroundColor: pilgrimsDark,
          foregroundColor: Colors.white,
        ),
        backgroundColor: const Color(0xFFF6FAFA),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Icon(
              Icons.account_circle_rounded,
              size: 85,
              color: pilgrimsGreen,
            ),
            const SizedBox(height: 12),
            Text(
              pilgrim['name']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: pilgrimsDark,
              ),
            ),
            const SizedBox(height: 20),
            _info('رقم الحاج', pilgrim['id']!),
            _info('الموقع', pilgrim['camp']!),
            _info('رقم الغرفة', pilgrim['room']!),
            _info('حالة البيانات', pilgrim['status']!),
            const SizedBox(height: 20),
            const Text(
              'هذه بيانات تجريبية للعرض وليست سجلات حقيقية.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String title, String value) {
    return Card(
      color: Colors.white,
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

class CampDistributionPage extends StatelessWidget {
  const CampDistributionPage({super.key});

  static const List<Map<String, String>> camps = [
    {'name': 'منى', 'description': 'مخيمات الحجاج وأرقام الغرف'},
    {'name': 'مزدلفة', 'description': 'موقع التجمع ومعلومات التنقل'},
    {'name': 'عرفة', 'description': 'بيانات المخيم وموقع الحجاج'},
    {'name': 'مكة', 'description': 'بيانات السكن والغرف'},
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('توزيع المخيمات والغرف'),
          backgroundColor: pilgrimsDark,
          foregroundColor: Colors.white,
        ),
        backgroundColor: const Color(0xFFF6FAFA),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: camps.map((camp) {
            final residents = PilgrimsManagementPage.pilgrims
                .where((p) => p['camp'] == camp['name'])
                .toList();

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: const Icon(
                  Icons.location_city_rounded,
                  color: pilgrimsGreen,
                ),
                title: Text(
                  camp['name']!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(camp['description']!),
                children: [
                  if (residents.isEmpty)
                    const ListTile(
                      title: Text('لا توجد بيانات تجريبية لهذا الموقع'),
                    ),
                  ...residents.map(
                    (p) => ListTile(
                      title: Text(p['name']!),
                      subtitle: Text('الغرفة: ${p['room']}'),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class PilgrimRequestsPage extends StatelessWidget {
  const PilgrimRequestsPage({super.key});

  final List<Map<String, String>> requests = const [
    {
      'title': 'طلب خدمة السكن',
      'name': 'حاج تجريبي 1',
      'status': 'قيد المراجعة',
      'note': 'طلب استفسار عن بيانات الغرفة',
    },
    {
      'title': 'طلب خدمة النقل',
      'name': 'حاج تجريبي 2',
      'status': 'جديد',
      'note': 'استفسار عن موعد الحافلة',
    },
    {
      'title': 'ملاحظة على الخدمة',
      'name': 'حاج تجريبي 3',
      'status': 'تم الاطلاع',
      'note': 'ملاحظة تجريبية على إحدى الخدمات',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('طلبات الحجاج وملاحظاتهم'),
          backgroundColor: pilgrimsDark,
          foregroundColor: Colors.white,
        ),
        backgroundColor: const Color(0xFFF6FAFA),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: requests.map((request) {
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(
                  Icons.assignment_rounded,
                  color: pilgrimsGreen,
                ),
                title: Text(request['title']!),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'اسم الحاج: ${request['name']}\n'
                    'الحالة: ${request['status']}\n'
                    'الملاحظة: ${request['note']}',
                  ),
                ),
                isThreeLine: true,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}