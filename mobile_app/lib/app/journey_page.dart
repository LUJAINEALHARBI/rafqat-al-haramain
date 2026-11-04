import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// برنامج المناسك — محطات رحلة الحج
///
/// الحاج يتابع رحلته: ما انتهى منها وما بقي ومتى وبأي وسيلة انتقال.
/// والمشرف الذي يملك صلاحية manage_journey يحدّث حالة كل محطة من هنا،
/// فيظهر التحديث للحاج مباشرة. البيانات كلها من جدولي
/// journey_programs و journey_stations عبر api/journey.php
class JourneyPage extends StatefulWidget {
  const JourneyPage({super.key});

  @override
  State<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);
  static const Color blue = Color(0xFF087FA3);

  bool loading = true;
  String? loadError;

  Map<String, dynamic> program = {};
  Map<String, dynamic> progress = {};
  List<dynamic> stations = [];
  List<String> statusOptions = const ['لم تبدأ', 'جارية', 'مكتملة'];
  bool canManage = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      loadError = null;
    });

    try {
      final data = await ApiService.journeyProgram();

      final options = data['options'];
      final statuses = (options is Map) ? options['statuses'] : null;

      setState(() {
        program = Map<String, dynamic>.from(data['program'] as Map);
        progress = Map<String, dynamic>.from(data['progress'] as Map);
        stations = List<dynamic>.from(data['stations'] as List);
        canManage = data['can_manage'] == true;
        if (statuses is List && statuses.isNotEmpty) {
          statusOptions = statuses.map((e) => e.toString()).toList();
        }
        loading = false;
      });
    } catch (e) {
      setState(() {
        loadError = '$e';
        loading = false;
      });
    }
  }

  Future<void> _changeStatus(Map<String, dynamic> station, String status) async {
    try {
      await ApiService.setStationStatus(
        int.parse('${station['station_id']}'),
        status,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث "${station['station_name']}" إلى $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  // ------------------------------------------------------------------
  // أدوات عرض صغيرة
  // ------------------------------------------------------------------

  Color _statusColor(String status) {
    if (status == 'مكتملة') return green;
    if (status == 'جارية') return blue;
    return Colors.grey;
  }

  IconData _statusIcon(String status) {
    if (status == 'مكتملة') return Icons.check_circle_rounded;
    if (status == 'جارية') return Icons.place_rounded;
    return Icons.radio_button_unchecked;
  }

  IconData _transportIcon(String transport) {
    switch (transport) {
      case 'حافلة':
        return Icons.directions_bus_rounded;
      case 'قطار المشاعر':
        return Icons.train_rounded;
      case 'سيارة':
        return Icons.directions_car_rounded;
      case 'سيراً على القدم':
        return Icons.directions_walk_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  /// 2026-05-22 05:00:00 → 22/05 — 05:00 ص
  String _formatTime(dynamic value) {
    final text = '${value ?? ''}';
    if (text.length < 16) return 'الوقت لم يُحدَّد';

    final day = text.substring(8, 10);
    final month = text.substring(5, 7);
    var hour = int.tryParse(text.substring(11, 13)) ?? 0;
    final minute = text.substring(14, 16);
    final period = hour < 12 ? 'ص' : 'م';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    final hourText = hour.toString().padLeft(2, '0');
    return '$day/$month — $hourText:$minute $period';
  }

  String _sectionLabel(dynamic value) {
    if (value == 'men') return 'الرجال';
    if (value == 'women') return 'النساء';
    return 'القسمان';
  }

  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAFA),
        appBar: AppBar(
          title: const Text('محطات رحلة الحج'),
          centerTitle: true,
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            loadError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, height: 1.6),
          ),
        ),
      );
    }

    final rawPercent = progress['percent'];
    final percent = rawPercent is int ? rawPercent : (int.tryParse('$rawPercent') ?? 0);

    final current = progress['current'];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _progressCard(percent, current),
          const SizedBox(height: 16),
          _summaryRow(),
          const SizedBox(height: 16),
          if (stations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'لم تُضف محطات لهذه الرحلة بعد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ...stations.map((s) => _stationCard(Map<String, dynamic>.from(s as Map))),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------

  Widget _progressCard(int percent, dynamic current) {
    final name = '${program['program_name'] ?? 'برنامج الرحلة'}';
    final year = '${program['hijri_year'] ?? ''}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      year.isEmpty ? name : '$name - $year',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA88B4A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      current == null
                          ? 'تمّت جميع محطات الرحلة بحمد الله'
                          : 'المرحلة الحالية: ${current['station_name']}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFEDF0EE),
              valueColor: const AlwaysStoppedAnimation<Color>(green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow() {
    final total = '${progress['total'] ?? 0}';
    final done = '${progress['done'] ?? 0}';
    final remaining = '${progress['remaining'] ?? 0}';

    return Row(
      children: [
        _summaryBox(total, 'إجمالي المحطات'),
        const SizedBox(width: 10),
        _summaryBox(done, 'منجزة'),
        const SizedBox(width: 10),
        _summaryBox(remaining, 'متبقية'),
        const SizedBox(width: 10),
        _summaryBox(_sectionLabel(program['section']), 'القسم'),
      ],
    );
  }

  Widget _summaryBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7ECE9)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------

  Widget _stationCard(Map<String, dynamic> s) {
    final status = '${s['status'] ?? 'لم تبدأ'}';
    final color = _statusColor(status);
    final transport = '${s['transport_type'] ?? 'لا يوجد'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(_statusIcon(status), size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s['station_order']}. ${s['station_name']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(s['start_datetime']),
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if ('${s['notes'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${s['notes']}',
              style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.5),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if ('${s['place_name'] ?? ''}'.isNotEmpty)
                _chip(Icons.location_on_rounded, '${s['place_name']}'),
              if ('${s['hijri_day'] ?? ''}'.isNotEmpty)
                _chip(Icons.calendar_today_rounded, '${s['hijri_day']}'),
              if (transport != 'لا يوجد') _chip(_transportIcon(transport), transport),
            ],
          ),
          if (canManage) ...[
            const Divider(height: 22),
            Row(
              children: [
                const Text(
                  'حالة المحطة:',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: statusOptions.contains(status) ? status : statusOptions.first,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: statusOptions
                        .map((v) => DropdownMenuItem<String>(
                              value: v,
                              child: Text(v, style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null && value != status) {
                        _changeStatus(s, value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: green),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 11, color: Colors.black87)),
        ],
      ),
    );
  }
}
