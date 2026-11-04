import 'dart:convert';
import 'package:http/http.dart' as http;

/// خطأ قادم من الواجهة الخلفية برسالة عربية جاهزة للعرض.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, [this.statusCode = 0]);
  @override
  String toString() => message;
}

/// حلقة الوصل بين التطبيق وقاعدة البيانات.
///
/// التطبيق لا يتصل بـ MySQL مباشرة — يتصل بملفات PHP في مجلد `api/`
/// وهي وحدها التي تفتح قاعدة البيانات، تماماً مثل الموقع.
///
/// ------------------------------------------------------------------
///  غيّري [baseUrl] فقط، ولا شيء غيره:
///
///  • محاكي أندرويد (Android Emulator) مع XAMPP على نفس الجهاز:
///      http://10.0.2.2/website/api
///    (العنوان 10.0.2.2 هو localhost الجهاز من داخل المحاكي)
///
///  • جوال حقيقي على نفس شبكة الواي فاي:
///      http://192.168.1.5/website/api
///    بدّلي الرقم بعنوان IP الخاص بجهازك (ipconfig في ويندوز)،
///    وتأكدي أن Apache يسمح بالاتصال من الشبكة المحلية.
///
///  • محاكي iOS على ماك:
///      http://localhost/website/api
///
///  ملاحظة: الاستضافة المجانية InfinityFree تحجب الطلبات القادمة من
///  خارج المتصفح، فلا تصلح لتشغيل التطبيق. تصلح الاستضافات المدفوعة
///  أو التشغيل المحلي على XAMPP.
/// ------------------------------------------------------------------
class ApiService {
  static String baseUrl = 'http://10.0.2.2/website/api';

  /// كوكي الجلسة (PHPSESSID) — نحفظه بعد تسجيل الدخول ونرسله مع كل طلب،
  /// لأن حزمة http لا تحفظ الكوكيز تلقائياً مثل المتصفح.
  static String? _sessionCookie;

  /// بيانات المستخدم الحالي كما أعادها الخادم من قاعدة البيانات.
  static Map<String, dynamic>? currentUser;

  static bool get isLoggedIn => currentUser != null;

  static Map<String, String> _headers({bool json = false}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json';
    if (_sessionCookie != null) h['Cookie'] = _sessionCookie!;
    return h;
  }

  static void _rememberCookie(http.Response res) {
    final raw = res.headers['set-cookie'];
    if (raw != null && raw.isNotEmpty) {
      _sessionCookie = raw.split(';').first;
    }
  }

  static dynamic _decode(http.Response res) {
    final body = res.body;

    // بعض الاستضافات ترد بصفحة تحقق HTML بدل JSON
    if (body.trimLeft().startsWith('<')) {
      throw ApiException(
        'الخادم رد بصفحة HTML بدل البيانات. تأكدي من عنوان baseUrl '
        'ومن أن الاستضافة تسمح بالاتصال من خارج المتصفح.',
        res.statusCode,
      );
    }

    late final Map<String, dynamic> map;
    try {
      map = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('رد غير مفهوم من الخادم.', res.statusCode);
    }

    if (map['ok'] == false) {
      throw ApiException(
        (map['error'] ?? 'حدث خطأ غير متوقع.').toString(),
        res.statusCode,
      );
    }
    return map['data'];
  }

  static Uri _uri(String file, String action, [Map<String, String>? params]) {
    final q = <String, String>{'action': action, ...?params};
    return Uri.parse('$baseUrl/$file').replace(queryParameters: q);
  }

  /// طلب قراءة
  static Future<dynamic> get(
    String file,
    String action, [
    Map<String, String>? params,
  ]) async {
    try {
      final res = await http
          .get(_uri(file, action, params), headers: _headers())
          .timeout(const Duration(seconds: 20));
      _rememberCookie(res);
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'تعذّر الوصول إلى الخادم. تأكدي أن Apache و MySQL يعملان '
        'وأن الجهاز على نفس الشبكة.',
      );
    }
  }

  /// طلب كتابة
  static Future<dynamic> post(
    String file,
    String action, [
    Map<String, dynamic> data = const {},
  ]) async {
    try {
      final res = await http
          .post(
            _uri(file, action),
            headers: _headers(json: true),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 20));
      _rememberCookie(res);
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'تعذّر الوصول إلى الخادم. تأكدي أن Apache و MySQL يعملان '
        'وأن الجهاز على نفس الشبكة.',
      );
    }
  }

  // ----------------------------------------------------------------
  // الجلسة
  // ----------------------------------------------------------------

  /// تسجيل الدخول — الخادم هو من يتحقق من كلمة المرور في قاعدة البيانات
  /// وهو من يقرر الدور والقسم، لا التطبيق.
  static Future<Map<String, dynamic>> login({
    required String id,
    required String password,
    String? section,
  }) async {
    final data = await post('auth.php', 'login', {
      'id': id,
      'password': password,
      if (section != null) 'section': section,
    });
    currentUser = Map<String, dynamic>.from(data as Map);
    return currentUser!;
  }

  static Future<void> logout() async {
    try {
      await post('auth.php', 'logout');
    } catch (_) {
      // الخروج محلياً حتى لو تعذّر الاتصال
    }
    currentUser = null;
    _sessionCookie = null;
  }

  // ----------------------------------------------------------------
  // اختصارات تقرأ من قاعدة البيانات
  // ----------------------------------------------------------------

  /// ملف الحاج المسجّل دخوله
  static Future<Map<String, dynamic>> pilgrimProfile(String id) async {
    final data = await get('pilgrims.php', 'get', {'id': id});
    return Map<String, dynamic>.from(data as Map);
  }

  /// ملف المشرف المسجّل دخوله (الاسم، الوظيفة، القسم، عدد حجاجه)
  static Future<Map<String, dynamic>> supervisorProfile() async {
    final data = await get('supervisors.php', 'profile');
    return Map<String, dynamic>.from(data as Map);
  }

  /// بيانات الحملة
  static Future<Map<String, dynamic>> campaign() async {
    final data = await get('campaign.php', 'get');
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<dynamic>> pilgrims([Map<String, String>? params]) async =>
      List<dynamic>.from(await get('pilgrims.php', 'list', params) as List);

  static Future<List<dynamic>> supervisors() async =>
      List<dynamic>.from(await get('supervisors.php', 'list') as List);

  static Future<List<dynamic>> tasks() async =>
      List<dynamic>.from(await get('tasks.php', 'list') as List);

  static Future<List<dynamic>> services() async =>
      List<dynamic>.from(await get('services.php', 'list') as List);

  /// خدمات نوع معيّن من جدول services (medical / catering / crowd / housing)
  static Future<List<dynamic>> servicesOfType(String type) async {
    final all = await services();
    return all.where((e) => (e['service_type'] ?? '') == type).toList();
  }

  /// طلبات الخدمة الخاصة بالمستخدم الحالي (service_provisions)
  static Future<List<dynamic>> serviceRequests() async =>
      List<dynamic>.from(await get('services.php', 'requests') as List);

  // ----------------------------------------------------------------
  // الصلاحيات
  // ----------------------------------------------------------------

  /// دور المستخدم: pilgrim / supervisor / campaign
  static String get role => (currentUser?['role'] ?? '').toString();

  /// وظيفة المشرف من جدول jobs: general / medical / crowd / catering / housing
  static String get jobRole => (currentUser?['job_role'] ?? '').toString();

  /// القسم الذي يتابعه حالياً: men / women
  static String get section => (currentUser?['section'] ?? '').toString();

  /// هل هو المشرف العام الذي يتابع القسمين؟
  static bool get isGeneral => currentUser?['is_general'] == true;

  /// صلاحيات وظيفته كما أرسلها الخادم من جدول job_permissions
  static List<String> get permissions {
    final list = currentUser?['permissions'];
    if (list is List) return list.map((e) => e.toString()).toList();
    return const [];
  }

  /// هل يملك المستخدم هذه الصلاحية؟ نفس الفحص الموجود في الموقع.
  static bool can(String permission) => permissions.contains(permission);

  /// تبديل القسم — للمشرف العام فقط
  static Future<String> setSection(String newSection) async {
    final data = await post('auth.php', 'set_section', {'section': newSection});
    final value = (data as Map)['section'].toString();
    currentUser?['section'] = value;
    return value;
  }

  // ----------------------------------------------------------------
  // برنامج المناسك (journey_programs / journey_stations)
  // ----------------------------------------------------------------

  /// برنامج الرحلة ومحطاته ونسبة التقدم
  static Future<Map<String, dynamic>> journeyProgram() async {
    final data = await get('journey.php', 'program');
    return Map<String, dynamic>.from(data as Map);
  }

  /// تحديث حالة محطة: لم تبدأ / جارية / مكتملة
  static Future<void> setStationStatus(int stationId, String status) async {
    await post('journey.php', 'set_status', {
      'station_id': stationId,
      'status': status,
    });
  }

  // ----------------------------------------------------------------
  // المواقع (site_locations / pilgrim_locations)
  // ----------------------------------------------------------------

  /// مواقع المخيمات والمشاعر الخاصة بالحملة
  static Future<List<dynamic>> sites() async =>
      List<dynamic>.from(await get('location.php', 'sites') as List);

  /// آخر موقع شاركه كل حاج — لمن يملك صلاحية view_locations
  static Future<List<dynamic>> pilgrimLocations() async =>
      List<dynamic>.from(await get('location.php', 'pilgrims') as List);

  /// آخر موقع شاركه الحاج نفسه (قد يكون null)
  static Future<Map<String, dynamic>?> myLastLocation() async {
    final data = await get('location.php', 'my_last');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }
}
