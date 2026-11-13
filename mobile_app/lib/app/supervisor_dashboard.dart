import 'package:flutter/material.dart';
import 'main.dart' show LoginPage;
import 'chat_page.dart';
import 'journey_page.dart';
import 'locations_page.dart';
import '../services/api_service.dart';
class SupervisorDashboard extends StatelessWidget {
  final String supervisorId;
  final String section;

  const SupervisorDashboard({
    super.key,
    required this.supervisorId,
    this.section = 'رجال',
  });

  // التخصص والمسمى الوظيفي يُقرآن من جدول jobs عبر
  // api/supervisors.php?action=profile ، لا من آخر رقم في العضوية.
  // الدوال أدناه تبقى كقيمة احتياطية فقط إذا تعذّر الاتصال.
  String get roleKey {
    if (supervisorId.startsWith('5000')) return 'general';
    if (supervisorId.endsWith('2')) return 'crowd';
    if (supervisorId.endsWith('3')) return 'catering';
    if (supervisorId.endsWith('4')) return 'housing';
    return 'medical';
  }

  String get jobTitle {
    switch (roleKey) {
      case 'general':
        return 'مشرف عام';
      case 'crowd':
        return 'موظف الحشود والتنقل';
      case 'catering':
        return 'موظف الإعاشة والأطعمة';
      case 'housing':
        return 'موظف السكن وخدمة الحجاج';
      default:
        return 'الموظف الصحي';
    }
  }

  List<Map<String, dynamic>> departmentsFor(String key) {
    if (key == 'general') return departments;
    return departments.where((d) => d['role'] == key).toList();
  }

  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);
  static const Color background = Color(0xFFF6FAFA);

  static final List<Map<String, dynamic>> departments = [
    {
      'title': 'الموظف الصحي',
      'role': 'medical',
      'icon': Icons.medical_services_rounded,
      'description': 'الحالات الصحية والمساعدة الطبية',
      'tasks': [
        {
          'title': 'الحالات الصحية',
          'icon': Icons.health_and_safety_rounded,
          'details': [
            'متابعة الحالات الصحية للحجاج',
            'تسجيل الملاحظات الصحية',
            'متابعة الحالات التي تحتاج إلى رعاية',
            'البيانات الصحية في هذه النسخة تجريبية',
          ],
        },
        {
          'title': 'طلبات المساعدة الطبية',
          'icon': Icons.healing_rounded,
          'details': [
            'عرض طلبات المساعدة الطبية',
            'متابعة حالة كل طلب',
            'التواصل مع الحاج عند الحاجة',
            'لا توجد طلبات محفوظة في النسخة التجريبية',
          ],
        },
        {
          'title': 'الإرشادات الصحية',
          'icon': Icons.health_and_safety,
          'details': [
            'شرب الماء بانتظام',
            'تجنب الإجهاد والتعرض المباشر للشمس',
            'الالتزام بالإرشادات الصحية',
            'طلب المساعدة عند الشعور بالتعب',
          ],
        },
      ],
    },
    {
      'title': 'موظف الحشود والتنقل',
      'role': 'crowd',
      'icon': Icons.directions_bus_rounded,
      'description': 'الحافلات والرحلات وتنظيم الحشود',
      'tasks': [
        {
          'title': 'تنظيم الحشود',
          'icon': Icons.groups_rounded,
          'details': [
            'متابعة تجمع الحجاج',
            'تنظيم حركة المجموعات',
            'متابعة نقاط التجمع',
            'رفع الملاحظات إلى إدارة الحملة',
          ],
        },
        {
          'title': 'الحافلات',
          'icon': Icons.directions_bus_rounded,
          'details': [
            'متابعة الحافلات المخصصة للحملة',
            'تحديد أرقام الحافلات',
            'متابعة نقاط الصعود والنزول',
            'تأكيد مواعيد التحرك مع الإدارة',
          ],
        },
        {
          'title': 'الرحلات والمواعيد',
          'icon': Icons.route_rounded,
          'details': [
            'متابعة الرحلات إلى المشاعر المقدسة',
            'مراجعة مواعيد التحرك',
            'تحديد نقطة التجمع',
            'المواعيد المعروضة تجريبية',
          ],
        },
      ],
    },
    {
      'title': 'موظف الإعاشة والأطعمة',
      'role': 'catering',
      'icon': Icons.restaurant_rounded,
      'description': 'الوجبات ومواعيد تقديم الطعام',
      'tasks': [
        {
          'title': 'الإفطار',
          'icon': Icons.free_breakfast_rounded,
          'details': [
            'متابعة تجهيز وجبة الإفطار',
            'موعد تجريبي: 6:00 صباحًا',
            'متابعة جاهزية الوجبات',
          ],
        },
        {
          'title': 'الغداء',
          'icon': Icons.lunch_dining_rounded,
          'details': [
            'متابعة تجهيز وجبة الغداء',
            'موعد تجريبي: 12:30 ظهرًا',
            'متابعة توزيع الوجبات',
          ],
        },
        {
          'title': 'العشاء',
          'icon': Icons.dinner_dining_rounded,
          'details': [
            'متابعة تجهيز وجبة العشاء',
            'موعد تجريبي: 7:00 مساءً',
            'متابعة ملاحظات التغذية',
          ],
        },
      ],
    },
    {
      'title': 'موظف السكن وخدمة الحجاج',
      'role': 'housing',
      'icon': Icons.hotel_rounded,
      'description': 'السكن والغرف والطلبات والبلاغات',
      'tasks': [
        {
          'title': 'بيانات السكن',
          'icon': Icons.apartment_rounded,
          'details': [
            'اسم السكن: سكن حملة رفقة بلاد الحرمين',
            'الموقع: يحدد من إدارة الحملة',
            'رقم المخيم: يحدد عند التوزيع',
            'بيانات السكن المعروضة تجريبية',
          ],
        },
        {
          'title': 'الغرف والمرافق',
          'icon': Icons.meeting_room_rounded,
          'details': [
            'متابعة جاهزية الغرف',
            'متابعة المرافق',
            'رفع ملاحظات الصيانة',
            'أرقام الغرف تحدد عند توزيع الحجاج',
          ],
        },
        {
          'title': 'الخدمات والطلبات',
          'icon': Icons.room_service_rounded,
          'details': [
            'متابعة طلبات الخدمات',
            'مراجعة ملاحظات الحجاج',
            'متابعة الطلبات التي تحتاج إلى معالجة',
            'الطلبات غير محفوظة في قاعدة بيانات',
          ],
        },
        {
          'title': 'البلاغات',
          'icon': Icons.report_problem_rounded,
          'details': [
            'متابعة البلاغات الواردة',
            'تسجيل الملاحظات',
            'إحالة البلاغات إلى إدارة الحملة',
          ],
        },
      ],
    },
  ];

  void logout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
                (route) => false,
              );
            },
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ملف المشرف يُقرأ من قاعدة البيانات (الاسم، المسمى، القسم، عدد حجاجه)
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.supervisorProfile(),
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
            appBar: AppBar(
              title: const Text('لوحة المشرف'),
              centerTitle: true,
              backgroundColor: darkGreen,
              foregroundColor: Colors.white,
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'تعذّر تحميل بيانات المشرف من قاعدة البيانات:\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 15),
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
    final dbRoleKey   = (me['role_key']  ?? roleKey).toString();
    final dbJobTitle  = (me['job_title'] ?? jobTitle).toString();
    final dbName      = (me['name'] ?? '').toString();
    final sectionText = section == 'نساء' ? 'قسم النساء' : 'قسم الرجال';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text(
            'لوحة المشرف',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => logout(context),
            ),
          ],
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
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 86,
                        height: 56,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'مرحبًا بك',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$dbJobTitle | $sectionText'
                    '${dbName.isEmpty ? '' : ' — $dbName'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'رقم العضوية: $supervisorId',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'اختر القسم والمهمة التي تريد متابعتها',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'أقسام الإشراف',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            ...departmentsFor(dbRoleKey).map((department) {
              return Card(
                color: Colors.white,
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F4F2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      department['icon'] as IconData,
                      color: green,
                      size: 29,
                    ),
                  ),
                  title: Text(
                    department['title'] as String,
                    style: const TextStyle(
                      color: darkGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      department['description'] as String,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: green,
                    size: 19,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupervisorDepartmentPage(
                          department:
                              Map<String, dynamic>.from(department),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            // برنامج المناسك: لمن تسمح وظيفته بإدارته فقط
            // (المشرف العام وموظف الحشود والتنقل وإدارة الحملة)
            if (ApiService.can('manage_journey'))
              _navCard(
                context,
                icon: Icons.route_rounded,
                title: 'برنامج المناسك ورحلة الحجاج',
                subtitle: 'محطات الرحلة وأوقاتها، وتحديد المنجز منها',
                page: const JourneyPage(),
              ),

            // الخريطة: متاحة للجميع، ومتابعة مواقع الحجاج داخلها
            // تظهر لمن يملك صلاحية view_locations فقط
            _navCard(
              context,
              icon: Icons.map_rounded,
              title: 'الخريطة والمواقع',
              subtitle: ApiService.can('view_locations')
                  ? 'مواقع المخيمات والمشاعر وآخر موقع شاركه الحجاج'
                  : 'مواقع المخيمات والمشاعر الخاصة بالحملة',
              page: const LocationsPage(),
            ),

            Card(
  color: Colors.white,
  elevation: 2,
  margin: const EdgeInsets.only(bottom: 14),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
  ),
  child: ListTile(
    contentPadding: const EdgeInsets.all(14),
    leading: Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F4F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.chat_rounded,
        color: Color(0xFF277D78),
        size: 29,
      ),
    ),
    title: const Text(
      'المحادثات والدعم الفني',
      style: TextStyle(
        color: Color(0xFF244C4A),
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
    subtitle: const Text('التواصل مع مجموعة المشرفين والدعم الفني'),
    trailing: const Icon(
      Icons.arrow_forward_ios_rounded,
      color: Color(0xFF277D78),
      size: 19,
    ),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            userRole: section == 'نساء' ? 'مشرفة' : 'مشرف',
            userId: supervisorId,
          ),
        ),
      );
    },
  ),
),
          ],
        ),
      ),
    );
  }
}

/// بطاقة تفتح صفحة — تُستخدم للصفحات المشتركة في لوحة المشرف
Widget _navCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Widget page,
}) {
  return Card(
    color: Colors.white,
    elevation: 2,
    margin: const EdgeInsets.only(bottom: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFE3F4F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: const Color(0xFF277D78), size: 29),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF244C4A),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(subtitle),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Color(0xFF277D78),
        size: 19,
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    ),
  );
}

class SupervisorDepartmentPage extends StatelessWidget {
  final Map<String, dynamic> department;

  const SupervisorDepartmentPage({
    super.key,
    required this.department,
  });

  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);

  @override
  Widget build(BuildContext context) {
    final tasks = department['tasks'] as List<dynamic>;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAFA),
        appBar: AppBar(
          title: Text(department['title'] as String),
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [green, darkGreen],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    department['icon'] as IconData,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    department['title'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    department['description'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'المهام المتاحة',
              style: TextStyle(
                color: darkGreen,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...tasks.map((task) {
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE3F4F2),
                    child: Icon(
                      task['icon'] as IconData,
                      color: green,
                    ),
                  ),
                  title: Text(
                    task['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Text('اضغط لعرض التفاصيل'),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: green,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupervisorTaskDetailsPage(
                          title: task['title'] as String,
                          icon: task['icon'] as IconData,
                          details: List<String>.from(
                            task['details'] as List<dynamic>,
                          ),
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

class SupervisorTaskDetailsPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> details;

  const SupervisorTaskDetailsPage({
    super.key,
    required this.title,
    required this.icon,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAFA),
        appBar: AppBar(
          title: Text(title),
          backgroundColor: const Color(0xFF244C4A),
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Icon(
                icon,
                size: 68,
                color: const Color(0xFF277D78),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF244C4A),
              ),
            ),
            const SizedBox(height: 18),
            ...details.map(
              (detail) => Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF277D78),
                  ),
                  title: Text(detail),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}