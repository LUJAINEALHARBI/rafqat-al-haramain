import 'package:flutter/material.dart';
const Color serviceGreen = Color(0xFF277D78);
const Color serviceDark = Color(0xFF244C4A);
const Color serviceBackground = Color(0xFFF6FAFA);

class ManagerServicesPage extends StatelessWidget {
  const ManagerServicesPage({super.key});

  static const List<Map<String, dynamic>> services = [
    {
      'title': 'السكن والغرف',
      'description': 'بيانات السكن والغرف وتوزيع الحجاج',
      'icon': Icons.hotel_rounded,
      'details': [
        'اسم السكن: سكن حملة رفقة بلاد الحرمين',
        'الموقع: مكة المكرمة',
        'متابعة توزيع الغرف',
        'متابعة احتياجات السكن والصيانة',
      ],
    },
    {
      'title': 'الوجبات والتغذية',
      'description': 'مواعيد الوجبات والتوزيع الغذائي',
      'icon': Icons.restaurant_rounded,
      'details': [
        'الإفطار: 6:00 صباحًا',
        'الغداء: 12:30 ظهرًا',
        'العشاء: 7:00 مساءً',
        'متابعة توزيع الوجبات والنواقص',
      ],
    },
    {
      'title': 'النقل والمواصلات',
      'description': 'الحافلات والرحلات ونقاط التجمع',
      'icon': Icons.directions_bus_rounded,
      'details': [
        'متابعة جدول الرحلات',
        'تحديد نقاط تجمع الحجاج',
        'متابعة الحافلات',
        'تسجيل ملاحظات التأخير والازدحام',
      ],
    },
    {
      'title': 'الرعاية الطبية',
      'description': 'الطلبات الطبية والحالات الصحية',
      'icon': Icons.medical_services_rounded,
      'details': [
        'متابعة طلبات الرعاية الطبية',
        'تسجيل الحالات التي تحتاج متابعة',
        'تحديد نقطة الرعاية الصحية',
        'متابعة الحالات الطارئة',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: serviceBackground,
        appBar: AppBar(
          title: const Text(
            'إدارة الخدمات',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: serviceDark,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [serviceGreen, serviceDark],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.miscellaneous_services_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'خدمات الحملة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'اختاري الخدمة لعرض تفاصيلها ومهام متابعتها',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ...services.map((service) {
              return Card(
                color: Colors.white,
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    radius: 27,
                    backgroundColor: const Color(0xFFE0F2EF),
                    child: Icon(
                      service['icon'] as IconData,
                      color: serviceGreen,
                      size: 29,
                    ),
                  ),
                  title: Text(
                    service['title'] as String,
                    style: const TextStyle(
                      color: serviceDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(service['description'] as String),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: serviceGreen,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManagerServiceDetailsPage(
                          service: service,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'المعلومات المعروضة تجريبية ويمكن تعديلها لاحقًا وربطها بقاعدة بيانات.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManagerServiceDetailsPage extends StatelessWidget {
  final Map<String, dynamic> service;

  const ManagerServiceDetailsPage({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final details = service['details'] as List<String>;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: serviceBackground,
        appBar: AppBar(
          title: Text(
            service['title'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: serviceDark,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      service['icon'] as IconData,
                      color: serviceGreen,
                      size: 52,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      service['description'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: serviceDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'تفاصيل الخدمة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: serviceDark,
              ),
            ),
            const SizedBox(height: 10),
            ...details.map(
              (detail) => Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle_rounded,
                    color: serviceGreen,
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