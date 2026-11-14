import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  /// عنوان الخادم المستخدم حالياً.
  /// يُضبط تلقائياً عند فتح التطبيق عبر [autoDetect]، ويمكن تغييره
  /// يدوياً من شاشة الدخول (أيقونة الإعدادات) بدون إعادة بناء التطبيق.
  static String baseUrl = 'http://10.0.2.2/website/api';

  /// المضيفون الذين يجرّبهم التطبيق.
  ///   10.0.2.2  = جهاز اللاب نفسه من داخل محاكي أندرويد
  ///   127.0.0.1 = نفس الجهاز (محاكي iOS أو تشغيل على ويندوز)
  ///   المنفذ 8080 لأن XAMPP ينتقل إليه حين يكون المنفذ 80 مشغولاً
  static const List<String> hosts = [
    'http://10.0.2.2',
    'http://10.0.2.2:8080',
    'http://127.0.0.1',
    'http://127.0.0.1:8080',
    'http://localhost',
  ];

  /// المسارات المحتملة لمجلد المشروع داخل htdocs.
  /// نجرّبها كلها لأن اسم المجلد يختلف حسب طريقة فك الضغط.
  static const List<String> paths = [
    '/website/api',
    '/api',
    '/rafqat-al-haramain/website/api',
    '/rafqat-al-haramain-main/website/api',
    '/rafqa_haramain/website/api',
    '/rafqa/website/api',
  ];

  static List<String> get candidates => [
        for (final h in hosts)
          for (final p in paths) '$h$p',
      ];

  /// آخر عنوان نجح، محفوظ في ملف صغير حتى لا تعيدي إدخاله كل مرة.
  static File? _memoFile;

  static File? _memo() {
    if (_memoFile != null) return _memoFile;
    try {
      _memoFile = File('${Directory.systemTemp.path}/rafqa_server.txt');
    } catch (_) {
      return null;
    }
    return _memoFile;
  }

  static Future<void> _remember(String url) async {
    try {
      await _memo()?.writeAsString(url);
    } catch (_) {}
  }

  /// يُستدعى مرة عند فتح التطبيق.
  static Future<String?> loadSaved() async {
    try {
      final f = _memo();
      if (f != null && await f.exists()) {
        final v = (await f.readAsString()).trim();
        if (v.startsWith('http')) {
          baseUrl = v;
          return v;
        }
      }
    } catch (_) {}
    return null;
  }

  /// يضبط العنوان يدوياً. يقبل الصيغ المختصرة مثل 192.168.1.5
  static Future<void> setBaseUrl(String input) async {
    var v = input.trim();
    if (v.isEmpty) return;
    if (!v.startsWith('http://') && !v.startsWith('https://')) {
      v = 'http://$v';
    }
    v = v.replaceAll(RegExp(r'/+$'), '');
    if (!v.endsWith('/api')) {
      v = v.endsWith('/website') ? '$v/api' : '$v/website/api';
    }
    baseUrl = v;
    await _remember(v);
  }

  /// يجرّب عنواناً واحداً ويعيد رسالة عربية تشرح النتيجة بدقة.
  /// يعيد null إذا نجح الاتصال.
  static Future<String?> probe(String url, {int seconds = 5}) async {
    try {
      final res = await http
          .get(Uri.parse('$url/ping.php'), headers: {'Accept': 'application/json'})
          .timeout(Duration(seconds: seconds));

      final body = res.body.trimLeft();
      if (body.startsWith('<')) {
        return res.statusCode == 404
            ? 'الخادم يعمل لكن المسار غير صحيح (404). تأكدي أن مجلد website داخل htdocs.'
            : 'الخادم رد بصفحة HTML بدل البيانات (رمز ${res.statusCode}).';
      }

      final map = jsonDecode(body) as Map<String, dynamic>;
      if (map['ok'] == false) {
        return (map['error'] ?? 'رد الخادم بخطأ.').toString();
      }
      // الخادم موجود. حتى لو كانت قاعدة البيانات متوقفة فالعنوان صحيح،
      // ونريد تثبيته حتى تظهر رسالة الخطأ الحقيقية بدل «تعذّر الوصول».
      return null;
    } on TimeoutException {
      return 'الخادم لم يرد خلال $seconds ثوانٍ. غالباً جدار الحماية يحجب الاتصال.';
    } on SocketException catch (e) {
      final msg = e.osError?.message.toLowerCase() ?? '';
      if (msg.contains('refused')) {
        return 'الجهاز موجود لكن لا يوجد خادم على هذا المنفذ. شغّلي Apache من XAMPP، '
            'وإذا كان Apache يعمل على المنفذ 8080 أضيفي 8080: إلى العنوان.';
      }
      if (msg.contains('unreachable') || msg.contains('not known') ||
          msg.contains('no address')) {
        return 'لم يُعثر على الجهاز على الشبكة. تأكدي أن الجوال واللاب على نفس الواي فاي.';
      }
      return 'تعذّر فتح الاتصال بالخادم (${e.osError?.message ?? 'خطأ في الشبكة'}).';
    } on FormatException {
      return 'رد الخادم غير مفهوم (ليس JSON).';
    } catch (_) {
      return 'تعذّر الوصول إلى الخادم.';
    }
  }

  /// يفحص حالة قاعدة البيانات على العنوان الحالي، ويعيد null إن كانت سليمة.
  static Future<String?> databaseStatus() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/ping.php'),
              headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final data = map['data'];
      if (data is Map && data['database'] == false) {
        return (data['message'] ?? 'قاعدة البيانات متوقفة.').toString();
      }
      return null;
    } catch (_) {
      return 'تعذّر قراءة حالة قاعدة البيانات.';
    }
  }

  /// يبحث تلقائياً عن العنوان الصحيح بين [candidates] (والعنوان المحفوظ).
  /// يعيد العنوان الذي نجح، أو null إذا لم ينجح أي عنوان.
  static Future<String?> autoDetect() async {
    final list = <String>[
      baseUrl,
      ...candidates.where((c) => c != baseUrl),
    ];

    // نفحص كل العناوين معاً لا واحداً بعد واحد، وإلا احتاج البحث دقيقة كاملة.
    final results = await Future.wait(
      list.map((url) async => (await probe(url, seconds: 6)) == null),
    );

    for (var i = 0; i < list.length; i++) {
      if (results[i]) {
        baseUrl = list[i];
        await _remember(list[i]);
        return list[i];
      }
    }
    return null;
  }

  /// رسالة خطأ مفصّلة تُستخدم حين يفشل أي طلب عادي.
  static Future<String> diagnose() async {
    final err = await probe(baseUrl, seconds: 6);
    if (err == null) return 'الاتصال بالخادم سليم، أعيدي المحاولة.';
    return '$err\n\nالعنوان الحالي: $baseUrl';
  }

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

  /// يلتقط كعكة الجلسة PHPSESSID من رد الخادم.
  /// الخادم قد يرسل أكثر من ترويسة Set-Cookie (عند تجديد رقم الجلسة
  /// بعد تسجيل الدخول)، وحزمة http تدمجها في نص واحد، لذلك نفصلها
  /// ونأخذ آخر قيمة غير فارغة لـ PHPSESSID تحديداً.
  static void _rememberCookie(http.Response res) {
    final parts = <String>[];
    try {
      parts.addAll(res.headersSplitValues['set-cookie'] ?? const []);
    } catch (_) {}
    if (parts.isEmpty) {
      final raw = res.headers['set-cookie'];
      if (raw != null && raw.isNotEmpty) {
        // نفصل عند الفاصلة التي تسبق اسم كعكة جديدة فقط
        parts.addAll(raw.split(RegExp(r',(?=\s*[A-Za-z0-9_\-]+=)')));
      }
    }

    for (final part in parts) {
      final pair = part.split(';').first.trim();
      final eq = pair.indexOf('=');
      if (eq <= 0) continue;
      final name = pair.substring(0, eq).trim();
      final value = pair.substring(eq + 1).trim();
      if (name != 'PHPSESSID') continue;
      if (value.isEmpty || value == 'deleted') continue;
      _sessionCookie = '$name=$value';
    }
  }

  static dynamic _decode(http.Response res) {
    final body = res.body;

    // بعض الاستضافات ترد بصفحة تحقق HTML بدل JSON
    if (body.trimLeft().startsWith('<')) {
      throw ApiException(
        res.statusCode == 404
            ? 'المسار غير صحيح على الخادم (404). افتحي إعدادات الخادم '
              'من شاشة الدخول واضغطي «بحث تلقائي».'
            : 'الخادم رد بصفحة بدل البيانات (رمز ${res.statusCode}). '
              'غالباً خطأ في ملف الإعدادات config.php — افتحي '
              'ping.php من متصفح اللاب لمعرفة السبب.',
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
      var msg = (map['error'] ?? 'حدث خطأ غير متوقع.').toString();
      // 401 بعد تسجيل دخول ناجح = الجلسة ضاعت على الخادم
      if (res.statusCode == 401) {
        msg += _sessionCookie == null
            ? '\n\nالتطبيق لم يستلم كعكة الجلسة من الخادم.'
            : '\n\nالجلسة ضاعت على الخادم. افتحي ping.php من متصفح اللاب '
              'وانظري حقل session — غالباً مجلد الجلسات غير قابل للكتابة.';
      }
      throw ApiException(msg, res.statusCode);
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
    } on TimeoutException {
      throw ApiException(
        'الخادم لم يرد في الوقت المحدد. تأكدي أن Apache يعمل، '
        'وأن جدار الحماية لا يحجب الاتصال.',
      );
    } on SocketException catch (e) {
      final m = e.osError?.message.toLowerCase() ?? '';
      throw ApiException(
        m.contains('refused')
            ? 'لا يوجد خادم على العنوان $baseUrl — شغّلي Apache من XAMPP، '
              'أو غيّري عنوان الخادم من أيقونة الإعدادات في شاشة الدخول.'
            : 'تعذّر الوصول إلى $baseUrl. تأكدي أن الجهاز واللاب على نفس الشبكة، '
              'أو غيّري العنوان من أيقونة الإعدادات في شاشة الدخول.',
      );
    } catch (_) {
      throw ApiException(
        'تعذّر الوصول إلى الخادم ($baseUrl). افتحي إعدادات الخادم '
        'من شاشة الدخول واضغطي «بحث تلقائي».',
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
    } on TimeoutException {
      throw ApiException(
        'الخادم لم يرد في الوقت المحدد. تأكدي أن Apache يعمل، '
        'وأن جدار الحماية لا يحجب الاتصال.',
      );
    } on SocketException catch (e) {
      final m = e.osError?.message.toLowerCase() ?? '';
      throw ApiException(
        m.contains('refused')
            ? 'لا يوجد خادم على العنوان $baseUrl — شغّلي Apache من XAMPP، '
              'أو غيّري عنوان الخادم من أيقونة الإعدادات في شاشة الدخول.'
            : 'تعذّر الوصول إلى $baseUrl. تأكدي أن الجهاز واللاب على نفس الشبكة، '
              'أو غيّري العنوان من أيقونة الإعدادات في شاشة الدخول.',
      );
    } catch (_) {
      throw ApiException(
        'تعذّر الوصول إلى الخادم ($baseUrl). افتحي إعدادات الخادم '
        'من شاشة الدخول واضغطي «بحث تلقائي».',
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
