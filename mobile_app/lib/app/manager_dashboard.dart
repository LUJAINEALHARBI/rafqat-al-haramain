import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'pilgrims_management_page.dart';
import 'manager_supervisors_page.dart';
import 'manager_services_page.dart';
import '../services/api_service.dart';

class ManagerDashboard extends StatelessWidget {
  final String managerId;

  const ManagerDashboard({
    super.key,
    this.managerId = '30089',
  });

  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);
  static const Color background = Color(0xFFF6FAFA);

  static const List<Map<String, dynamic>> items = [
    {
      'title': 'إدارة الحجاج',
      'icon': Icons.groups_rounded,
      'details': [
        'عرض قائمة الحجاج',
        'متابعة بيانات الحجاج',
        'توزيع الحجاج على المخيمات',
        'تحديد المشرف المسؤول عن كل مجموعة',
      ],
    },
    {
      'title': 'إدارة المشرفين',
      'icon': Icons.supervisor_account_rounded,
      'details': [
        'الموظف الصحي',
        'موظف الحشود والتنقل',
        'موظف الإعاشة والأطعمة',
        'موظف السكن وخدمة الحجاج',
        'متابعة مهام المشرفين',
      ],
    },
    {
      'title': 'إدارة الخدمات',
      'icon': Icons.miscellaneous_services_rounded,
      'details': [
        'خدمات السكن',
        'خدمات الوجبات',
        'خدمات النقل',
        'الخدمات الطبية',
        'طلبات الخدمات الإضافية',
      ],
    },
    {
      'title': 'الحشود والنقل',
      'icon': Icons.directions_bus_rounded,
      'details': [
        'تنظيم حركة الحشود',
        'إدارة الحافلات',
        'متابعة الرحلات',
        'جدولة التنقلات',
      ],
    },
    {
      'title': 'المصروفات والفواتير',
      'icon': Icons.receipt_long_rounded,
      'details': [
        'عرض المصروفات',
        'متابعة الفواتير',
        'إدارة الميزانية',
        'ملخص التكاليف',
      ],
    },
    {
      'title': 'التقارير والتقييمات',
      'icon': Icons.analytics_rounded,
      'details': [
        'تقارير الخدمات',
        'تقييمات الحجاج',
        'تقارير أداء المشرفين',
        'متابعة مستوى رضا الحجاج',
      ],
    },
    {
      'title': 'الإعدادات والصلاحيات',
      'icon': Icons.settings_rounded,
      'details': [
        'إدارة صلاحيات المستخدمين',
        'إعدادات الحملة',
        'إدارة الحسابات',
      ],
    },
    {
      'title': 'المحادثات والدعم الفني',
      'icon': Icons.chat_rounded,
      'details': [
        'التواصل مع المشرفين',
        'التواصل مع الدعم الفني',
        'متابعة الاستفسارات',
        'استقبال الملاحظات والبلاغات',
      ],
    },
  ];

  void openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          userRole: 'مدير الحملة',
          userId: managerId,
        ),
      ),
    );
  }

  void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'تسجيل الخروج',
          textDirection: TextDirection.rtl,
        ),
        content: const Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  void openDetails(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    if (item['title'] == 'المحادثات والدعم الفني') {
      openChat(context);
      return;
    }

    Widget? page;
    if (item['title'] == 'إدارة الحجاج') {
      page = const PilgrimsManagementPage();
    } else if (item['title'] == 'إدارة المشرفين') {
      page = const ManagerSupervisorsPage();
    } else if (item['title'] == 'إدارة الخدمات') {
      page = const ManagerServicesPage();
    }
    if (page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page!),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerDetailsPage(
          title: item['title'] as String,
          icon: item['icon'] as IconData,
          details: item['details'] as List<String>,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // بيانات الحملة تُقرأ من جدول campaigns عبر api/campaign.php?action=get
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.campaign(),
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
              title: const Text('لوحة مدير الحملة'),
              centerTitle: true,
              backgroundColor: darkGreen,
              foregroundColor: Colors.white,
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'تعذّر تحميل بيانات الحملة من قاعدة البيانات:\n${snap.error}',
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

  Widget _buildUi(BuildContext context, Map<String, dynamic> camp) {
    final managerName  = (camp['manager_name'] ?? '').toString();
    final campaignName = (camp['campaign_name'] ?? 'رفقة بلاد الحرمين').toString();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'لوحة مدير الحملة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: () => logout(context),
              icon: const Icon(Icons.logout_rounded),
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
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    managerName.isEmpty
                        ? 'مرحباً بك مدير الحملة'
                        : 'مرحباً، $managerName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$campaignName — من هنا تقدر تتابع أعمال الحملة '
                    'وخدمات الحجاج والمشرفين',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لوحة الإدارة',
              style: TextStyle(
                color: darkGreen,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final isChat =
                    item['title'] == 'المحادثات والدعم الفني';

                return Card(
                  color: Colors.white,
                  elevation: 2,
                  shadowColor: green.withOpacity(0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => openDetails(context, item),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F4F2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: green,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['title'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: darkGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (isChat) ...[
                            const SizedBox(height: 5),
                            const Text(
                              'تواصل مباشر',
                              style: TextStyle(
                                color: green,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class ManagerDetailsPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> details;

  const ManagerDetailsPage({
    super.key,
    required this.title,
    required this.icon,
    required this.details,
  });

  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAFA),
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 55, color: green),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                ],
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
                    color: green,
                  ),
                  title: Text(
                    detail,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: darkGreen,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}