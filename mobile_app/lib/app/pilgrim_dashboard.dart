import 'package:flutter/material.dart';
import 'main.dart' show LoginPage;
import 'housing_page.dart';
import 'meals_page.dart';
import 'transport_page.dart';
import 'medical_page.dart';
import 'culture_page.dart';
import 'chat_page.dart';
import '../services/api_service.dart';

class PilgrimDashboard extends StatelessWidget {
  final String pilgrimId;
  final String section;

  const PilgrimDashboard({
    super.key,
    required this.pilgrimId,
    this.section = 'رجال',
  });

  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);
  static const Color background = Color(0xFFF6FAFA);

  void openDetails(
    BuildContext context,
    String title,
    IconData icon,
    List<String> details,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PilgrimDetailsPage(
          title: title,
          icon: icon,
          details: details,
        ),
      ),
    );
  }

  void openCard(
    BuildContext context,
    String title,
    IconData icon,
    List<String> details,
  ) {
    Widget? page;

    if (title == 'السكن') {
      page = HousingPage(pilgrimId: pilgrimId);
    } else if (title == 'الوجبات') {
      page = const MealsPage();
    } else if (title == 'النقل') {
      page = const TransportPage();
    } else if (title == 'الخدمات الطبية') {
      page = const MedicalPage();
    } else if (title == 'الثقافة والفعاليات') {
      page = const CulturePage();
    } else if (title == 'التواصل') {
      page = ChatPage(
        userRole: section == 'نساء' ? 'حاجة' : 'حاج',
        userId: pilgrimId,
      );
    }
    if (page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page!),
      );
    } else {
      openDetails(context, title, icon, details);
    }
  }

  @override
  Widget build(BuildContext context) {
    // بيانات الحاج تُقرأ من جدول pilgrims عبر api/pilgrims.php?action=get
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.pilgrimProfile(pilgrimId),
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
              title: const Text('رفقة بلاد الحرمين'),
              centerTitle: true,
              backgroundColor: darkGreen,
              foregroundColor: Colors.white,
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'تعذّر تحميل بياناتك من قاعدة البيانات:\n${snap.error}',
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
    String v(String key, [String fallback = 'غير محدد']) {
      final x = me[key];
      if (x == null || x.toString().trim().isEmpty) return fallback;
      return x.toString();
    }

    final items = [
      {
        'title': 'السكن',
        'icon': Icons.hotel_rounded,
        'details': [
          'الاسم: ${v('name')}',
          'رقم الحجز: ${v('booking_number')}',
          'رقم المخيم: ${v('camp_id')}',
          'رقم الخيمة: ${v('tent_number')}',
          'رقم السرير: ${v('bed_number')}',
          'نوع الباقة: ${v('package_type')}',
          'نقطة التجمع: ${v('gathering_point')}',
        ],
      },
      {
        'title': 'الوجبات',
        'icon': Icons.restaurant_rounded,
        'details': [
          'الإفطار: 6:00 صباحاً',
          'الغداء: 12:30 ظهراً',
          'العشاء: 7:00 مساءً',
          'يرجى الالتزام بمواعيد الوجبات',
        ],
      },
      {
        'title': 'النقل',
        'icon': Icons.directions_bus_rounded,
        'details': [
          'الرحلات: مكة المكرمة والمشاعر المقدسة',
          'نقطة التجمع: عند مدخل السكن',
          'رقم الحافلة ووقت التحرك يحددهما المشرف',
        ],
      },
      {
        'title': 'الإرشاد',
        'icon': Icons.menu_book_rounded,
        'details': [
          'إرشادات أداء مناسك الحج',
          'التوعية بالتنقل بين المشاعر المقدسة',
          'يمكنك التواصل مع مشرف الحملة عند الحاجة',
        ],
      },
      {
        'title': 'الخدمات الطبية',
        'icon': Icons.medical_services_rounded,
        'details': [
          'خدمات التوعية الصحية',
          'معلومات التواصل مع الفريق الطبي',
          'في الحالات الطارئة تواصل مع الطوارئ مباشرة',
        ],
      },
      {
        'title': 'الثقافة والفعاليات',
        'icon': Icons.mosque_rounded,
        'details': [
          'فعاليات توعوية عن مناسك الحج',
          'مسابقات ثقافية ودينية',
          'مواعيد الفعاليات تعلن من إدارة الحملة',
        ],
      },
      {
        'title': 'طلب خدمة',
        'icon': Icons.add_task_rounded,
        'details': [
          'يمكنك طلب المساعدة من مشرف الحملة',
          'حدد نوع الخدمة المطلوبة',
          'تابع حالة طلبك مع المشرف',
        ],
      },
      {
        'title': 'التواصل',
        'icon': Icons.chat_rounded,
        'details': [
          'للاستفسارات تواصل مع مشرف المخيم',
          'يمكنك طلب المساعدة عند الحاجة',
        ],
      },
      {
        'title': 'التقييم',
        'icon': Icons.star_rounded,
        'details': [
          'شاركنا رأيك في خدمات الحملة',
          'ساعدنا على تحسين تجربة الحجاج',
        ],
      },
      {
        'title': 'معلومات الحملة',
        'icon': Icons.info_rounded,
        'details': [
          'اسم الحملة: رفقة بلاد الحرمين',
          'خدمات مخصصة لخدمة ضيوف الرحمن',
          'للاستفسارات يرجى التواصل مع إدارة الحملة',
        ],
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
  title: const Text(
    'رفقة بلاد الحرمين',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  centerTitle: true,
  backgroundColor: darkGreen,
  foregroundColor: Colors.white,
  actions: [
    IconButton(
      tooltip: 'تسجيل الخروج',
      icon: const Icon(Icons.logout_rounded),
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('تسجيل الخروج'),
            content: const Text('هل تريدين تسجيل الخروج؟'),
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
      },
    ),
  ],
),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [darkGreen, green],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 27,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person_rounded,
                            size: 34,
                            color: green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مرحباً، ${v('name', 'بك')}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'رقم العضوية: $pilgrimId',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
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
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'رفقة بلاد الحرمين',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'رفيقك في رحلة الحج، لخدمة أسهل وتجربة مطمئنة.',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'خدمات الحاج',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final title = item['title'] as String;
                  final icon = item['icon'] as IconData;
                  final details =
                      item['details'] as List<String>;

                  return Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => openCard(
                        context,
                        title,
                        icon,
                        details,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 38,
                              color: green,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: darkGreen,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'اضغط لعرض التفاصيل',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F4F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: green,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'نسأل الله لك حجاً مبروراً وسعياً مشكوراً.',
                        style: TextStyle(
                          color: darkGreen,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PilgrimDetailsPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> details;

  const PilgrimDetailsPage({
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
          title: Text(title),
          centerTitle: true,
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 15),
            Center(
              child: Icon(
                icon,
                size: 75,
                color: green,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
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