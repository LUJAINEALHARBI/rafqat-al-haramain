import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// بطاقة الحاج: بياناته الشخصية ورقم النسك وصلاحية الهوية
///
/// الحقول كلها من جدول pilgrims عبر api/pilgrims.php?action=get
/// ورقم النسك ونوع الهوية وتاريخ انتهائها حقول أُضيفت في الإصدار الثاني،
/// وتعديلها يتم من إدارة الحملة لا من التطبيق.
class IdentityPage extends StatelessWidget {
  final String pilgrimId;

  const IdentityPage({super.key, required this.pilgrimId});

  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAFA),
        appBar: AppBar(
          title: const Text('بطاقتي وبياناتي'),
          centerTitle: true,
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: ApiService.pilgrimProfile(pilgrimId),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'تعذّر تحميل بياناتك:\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, height: 1.6),
                  ),
                ),
              );
            }
            return _buildUi(snap.data ?? const {});
          },
        ),
      ),
    );
  }

  Widget _buildUi(Map<String, dynamic> p) {
    final status = p['id_status'];
    final statusLabel = status is Map ? '${status['label']}' : 'غير مسجّل';
    final statusState = status is Map ? '${status['state']}' : 'unknown';

    final statusColor = statusState == 'expired'
        ? Colors.red
        : statusState == 'soon'
            ? Colors.orange
            : green;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7ECE9)),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFE3F4F2),
                child: Icon(Icons.person_rounded, color: green, size: 32),
              ),
              const SizedBox(height: 10),
              Text(
                '${p['name'] ?? ''}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'رقم العضوية: ${p['pilgrim_id'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _section('بيانات الهوية والنسك', [
          _row(Icons.badge_rounded, 'نوع الهوية', '${p['id_type_ar'] ?? '—'}'),
          _row(Icons.pin_rounded, 'رقم الهوية', '${p['id_or_passport'] ?? '—'}'),
          _row(
            Icons.event_available_rounded,
            'انتهاء صلاحية الهوية',
            '${p['id_expiry'] ?? 'غير مسجّل'}',
            note: statusLabel,
            noteColor: statusColor,
          ),
          _row(Icons.confirmation_number_rounded, 'رقم النسك',
              '${p['nusuk_number'] ?? '—'}'),
        ]),
        const SizedBox(height: 14),
        _section('بيانات الرحلة', [
          _row(Icons.book_online_rounded, 'رقم الحجز', '${p['booking_number'] ?? '—'}'),
          _row(Icons.card_travel_rounded, 'الباقة', '${p['package_type'] ?? '—'}'),
          _row(Icons.holiday_village_rounded, 'المخيم', '${p['camp_id'] ?? '—'}'),
          _row(Icons.bed_rounded, 'الخيمة والسرير',
              '${p['tent_number'] ?? '—'}${p['bed_number'] != null ? ' - سرير ${p['bed_number']}' : ''}'),
          _row(Icons.flag_rounded, 'نقطة التجمع', '${p['gathering_point'] ?? '—'}'),
          _row(Icons.supervisor_account_rounded, 'المشرف المسؤول',
              '${p['supervisor_name'] ?? 'لم يُسنَد بعد'}'),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF0E3C8)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFFA88B4A), size: 19),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'رقم النسك وبيانات الهوية للعرض فقط، وتعديلها يتم عن طريق إدارة الحملة.',
                  style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(
    IconData icon,
    String label,
    String value, {
    String? note,
    Color? noteColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: green),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      note,
                      style: TextStyle(fontSize: 11, color: noteColor ?? Colors.black54),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
