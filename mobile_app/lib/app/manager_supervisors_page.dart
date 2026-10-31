import 'package:flutter/material.dart';
import '../services/api_service.dart';
const Color rifqaGreen = Color(0xFF277D78);
const Color rifqaDark = Color(0xFF244C4A);
const Color rifqaBackground = Color(0xFFF6FAFA);

class ManagerSupervisorsPage extends StatelessWidget {
  const ManagerSupervisorsPage({super.key});

  static const List<Map<String, dynamic>> supervisors = [
    {
      'name': 'الموظف الصحي',
      'id': '5000000001',
      'job': 'الرعاية الصحية والإسعافات الأولية',
      'icon': Icons.medical_services_rounded,
      'tasks': [
        'متابعة الحالات الصحية للحجاج',
        'استقبال طلبات الرعاية الطبية',
        'متابعة الحالات الطارئة والإحالات',
        'تحديث حالة الطلبات الصحية',
      ],
    },
    {
      'name': 'موظف الحشود والتنقل',
      'id': '5000000002',
      'job': 'تنظيم الحشود والحافلات والتنقل',
      'icon': Icons.directions_bus_rounded,
      'tasks': [
        'تنظيم حركة الحجاج',
        'متابعة الحافلات والرحلات',
        'تحديد نقاط التجمع',
        'تسجيل ملاحظات الازدحام',
      ],
    },
    {
      'name': 'موظف الإعاشة والأطعمة',
      'id': '5000000003',
      'job': 'الوجبات والتوزيع الغذائي',
      'icon': Icons.restaurant_rounded,
      'tasks': [
        'متابعة الإفطار والغداء والعشاء',
        'تنظيم توزيع الوجبات',
        'تسجيل النواقص والشكاوى',
        'متابعة الاحتياجات الغذائية',
      ],
    },
    {
      'name': 'موظف السكن وخدمة الحجاج',
      'id': '5000000004',
      'job': 'السكن والغرف وطلبات الخدمات',
      'icon': Icons.hotel_rounded,
      'tasks': [
        'متابعة توزيع الحجاج على الغرف',
        'متابعة بيانات السكن',
        'مراجعة طلبات الحجاج',
        'التنسيق بين المخيمات والخدمات',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    // قائمة المشرفين تُقرأ من جدولي supervisors و jobs
    return FutureBuilder<List<dynamic>>(
      future: ApiService.supervisors(),
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
            appBar: AppBar(title: const Text('إدارة المشرفين'), centerTitle: true),
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
        backgroundColor: rifqaBackground,
        appBar: AppBar(
          title: const Text(
            'إدارة المشرفين',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: rifqaDark,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [rifqaGreen, rifqaDark],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'فريق الإشراف',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'اختاري المشرف لعرض بياناته وصلاحياته ومهامه',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ...List.generate(rows.length, (i) {
              final r = rows[i] as Map;
              final base = supervisors[i % supervisors.length];
              final supervisor = <String, dynamic>{
                ...base,
                'name': (r['name'] ?? '').toString(),
                'job': [
                  (r['job_title'] ?? 'مشرف').toString(),
                  'رقم العضوية: ${r['supervisor_id'] ?? ''}',
                  if ((r['phone'] ?? '').toString().isNotEmpty)
                    'جوال: ${r['phone']}',
                ].join(' — '),
              };
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    radius: 27,
                    backgroundColor: const Color(0xFFE0F2EF),
                    child: Icon(
                      supervisor['icon'] as IconData,
                      color: rifqaGreen,
                      size: 29,
                    ),
                  ),
                  title: Text(
                    supervisor['name'] as String,
                    style: const TextStyle(
                      color: rifqaDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(supervisor['job'] as String),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: rifqaGreen,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupervisorDetailsPage(
                          supervisor: supervisor,
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
}

class SupervisorDetailsPage extends StatelessWidget {
  final Map<String, dynamic> supervisor;

  const SupervisorDetailsPage({
    super.key,
    required this.supervisor,
  });

  @override
  Widget build(BuildContext context) {
    final tasks = supervisor['tasks'] as List<String>;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: rifqaBackground,
        appBar: AppBar(
          title: Text(
            supervisor['name'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: rifqaDark,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: const Color(0xFFE0F2EF),
                    child: Icon(
                      supervisor['icon'] as IconData,
                      size: 42,
                      color: rifqaGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    supervisor['name'] as String,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: rifqaDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    supervisor['job'] as String,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'الرقم الوظيفي التجريبي',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    supervisor['id'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: rifqaGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'المهام والصلاحيات',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: rifqaDark,
              ),
            ),
            const SizedBox(height: 10),
            ...tasks.map(
              (task) => Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle_rounded,
                    color: rifqaGreen,
                  ),
                  title: Text(task),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'هذه بيانات تجريبية للواجهة، ولا تمثل صلاحيات فعلية محفوظة في قاعدة بيانات.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}