import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

/// الخرائط والمواقع
///
/// مواقع الفندق والمخيمات والمشاعر تُقرأ من جدول site_locations،
/// ولم تعد إحداثيات مكتوبة داخل الشاشة.
///
/// الحاج يرى المواقع فقط. ومتابعة مواقع الحجاج تظهر لمن تسمح وظيفته
/// بذلك (صلاحية view_locations: الموظف الصحي وموظف الحشود والمشرف
/// العام ومدير الحملة)، ولا تظهر لموظف الإعاشة أو السكن.
class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);

  bool loading = true;
  String? loadError;

  List<dynamic> sites = [];
  List<dynamic> pilgrimLocations = [];
  Map<String, dynamic>? myLocation;

  bool get canFollow => ApiService.can('view_locations');
  bool get isPilgrim => ApiService.role == 'pilgrim';

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
      final loaded = await ApiService.sites();

      List<dynamic> locations = const [];
      if (canFollow) {
        try {
          locations = await ApiService.pilgrimLocations();
        } catch (_) {
          locations = const [];
        }
      }

      Map<String, dynamic>? mine;
      if (isPilgrim) {
        try {
          mine = await ApiService.myLastLocation();
        } catch (_) {
          mine = null;
        }
      }

      setState(() {
        sites = loaded;
        pilgrimLocations = locations;
        myLocation = mine;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loadError = '$e';
        loading = false;
      });
    }
  }

  Future<void> _openInMaps(dynamic lat, dynamic lng, String name) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر فتح الخرائط لموقع $name')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح تطبيق الخرائط.')),
      );
    }
  }

  IconData _siteIcon(String type) {
    switch (type) {
      case 'فندق':
        return Icons.apartment_rounded;
      case 'مخيم':
        return Icons.holiday_village_rounded;
      case 'مشعر':
        return Icons.mosque_rounded;
      case 'نقطة تجمع':
        return Icons.groups_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  String _sectionLabel(dynamic value) {
    if (value == 'men') return 'قسم الرجال';
    if (value == 'women') return 'قسم النساء';
    return 'القسمان';
  }

  String _ago(dynamic minutes) {
    final m = int.tryParse('${minutes ?? ''}');
    if (m == null) return '—';
    if (m < 1) return 'الآن';
    if (m < 60) return 'قبل $m دقيقة';
    return 'قبل ${(m / 60).floor()} ساعة';
  }

  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAFA),
        appBar: AppBar(
          title: const Text('الخريطة والمواقع'),
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _noteCard(),
          const SizedBox(height: 16),
          const Text(
            'مواقع الحملة',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 10),
          if (sites.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'لم تُسجَّل مواقع للحملة في قاعدة البيانات بعد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ...sites.map((s) => _siteCard(Map<String, dynamic>.from(s as Map))),
          if (canFollow) ...[
            const SizedBox(height: 18),
            const Text(
              'آخر موقع شاركه الحجاج',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 10),
            if (pilgrimLocations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'لم يشارك أي حاج موقعه بعد. يظهر الحاج هنا بعد أن يشارك موقعه من الموقع.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else
              ...pilgrimLocations
                  .map((p) => _pilgrimCard(Map<String, dynamic>.from(p as Map))),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------

  Widget _noteCard() {
    String text;
    IconData icon;

    if (isPilgrim) {
      final last = myLocation;
      if (last == null) {
        text = 'هذه مواقع مخيمات حملتك والمشاعر. يمكنك فتح أي موقع في تطبيق الخرائط للوصول إليه.';
      } else {
        final nearest = last['nearest'];
        final siteName = nearest is Map ? '${nearest['site_name']}' : 'موقع محفوظ';
        text = 'آخر موقع شاركته قريب من: $siteName — ويظهر لمشرف مجموعتك.';
      }
      icon = Icons.map_rounded;
    } else if (canFollow) {
      text = 'تظهر لك مواقع الحملة وآخر موقع شاركه كل حاج في القسم الذي تتابعه.';
      icon = Icons.my_location_rounded;
    } else {
      text = 'متابعة مواقع الحجاج ليست من مهام وظيفتك، وتظهر لك مواقع الحملة فقط.';
      icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Row(
        children: [
          Icon(icon, color: green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _siteCard(Map<String, dynamic> s) {
    final type = '${s['site_type'] ?? ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: green.withValues(alpha: 0.12),
            child: Icon(_siteIcon(type), color: green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s['site_name']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (type.isNotEmpty) type,
                    if ('${s['period_note'] ?? ''}'.isNotEmpty) '${s['period_note']}',
                    _sectionLabel(s['section']),
                  ].join(' • '),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openInMaps(s['latitude'], s['longitude'], '${s['site_name']}'),
            icon: const Icon(Icons.directions_rounded, color: green),
            tooltip: 'فتح في الخرائط',
          ),
        ],
      ),
    );
  }

  Widget _pilgrimCard(Map<String, dynamic> p) {
    final nearest = p['nearest'];
    final nearestText = nearest is Map
        ? '${nearest['site_name']} (${nearest['distance_km']} كم)'
        : 'غير محدد';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFEAF3F0),
            child: Icon(Icons.person_pin_circle_rounded, color: green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p['name']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'رقم العضوية: ${p['pilgrim_id']} • أقرب موقع: $nearestText',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  _ago(p['minutes_ago']),
                  style: const TextStyle(fontSize: 11, color: green),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openInMaps(p['latitude'], p['longitude'], '${p['name']}'),
            icon: const Icon(Icons.directions_rounded, color: green),
            tooltip: 'فتح الموقع في الخرائط',
          ),
        ],
      ),
    );
  }
}
