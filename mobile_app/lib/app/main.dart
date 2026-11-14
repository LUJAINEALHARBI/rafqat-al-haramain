import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pilgrim_dashboard.dart';
import 'supervisor_dashboard.dart';
import 'manager_dashboard.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedSection;
  bool _hidePassword = true;
  bool _loading = false;
  bool _serverReady = true;

  static const Color teal = Color(0xFF277D78);
  static const Color darkTeal = Color(0xFF245B58);

  @override
  void initState() {
    super.initState();
    _prepareConnection();
  }

  /// عند فتح التطبيق: نستعيد آخر عنوان نجح، ثم نبحث تلقائياً عن الخادم.
  /// هكذا يعمل التطبيق على المحاكي وعلى الجوال الحقيقي بدون تعديل الكود.
  Future<void> _prepareConnection() async {
    await ApiService.loadSaved();
    final found = await ApiService.autoDetect();
    if (!mounted) return;
    setState(() => _serverReady = found != null);
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// نافذة إعدادات الخادم — لتغيير العنوان بدون إعادة بناء التطبيق.
  Future<void> _openServerSettings() async {
    final controller = TextEditingController(text: ApiService.baseUrl);
    String status = '';
    bool busy = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إعدادات الخادم'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'المحاكي على نفس اللاب:  10.0.2.2\n'
                    'جوال حقيقي على نفس الواي فاي: اكتبي IP اللاب\n'
                    '(افتحي cmd واكتبي ipconfig)',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الخادم',
                      hintText: '192.168.1.5',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (status.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6FAFA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(status, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                  if (busy) ...[
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        setLocal(() {
                          busy = true;
                          status = 'جارٍ البحث عن الخادم…';
                        });
                        final found = await ApiService.autoDetect();
                        final db = found == null
                            ? null
                            : await ApiService.databaseStatus();
                        setLocal(() {
                          busy = false;
                          controller.text = ApiService.baseUrl;
                          if (found == null) {
                            status = 'لم يُعثر على خادم. تأكدي أن Apache يعمل، '
                                'وأن مجلد website داخل htdocs، '
                                'أو اكتبي العنوان يدوياً.';
                          } else if (db != null) {
                            status = 'تم العثور على الخادم:\n$found\n\n$db';
                          } else {
                            status = 'تم العثور على الخادم ✓\n$found';
                          }
                        });
                      },
                child: const Text('بحث تلقائي'),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        setLocal(() {
                          busy = true;
                          status = 'جارٍ الاختبار…';
                        });
                        await ApiService.setBaseUrl(controller.text);
                        final err = await ApiService.probe(ApiService.baseUrl);
                        final db = err == null
                            ? await ApiService.databaseStatus()
                            : null;
                        setLocal(() {
                          busy = false;
                          if (err != null) {
                            status = err;
                          } else if (db != null) {
                            status = 'الخادم يعمل ✓\n${ApiService.baseUrl}\n\n$db';
                          } else {
                            status = 'الاتصال ناجح ✓\n${ApiService.baseUrl}';
                          }
                        });
                      },
                child: const Text('اختبار'),
              ),
              ElevatedButton(
                onPressed: busy
                    ? null
                    : () async {
                        await ApiService.setBaseUrl(controller.text);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );

    if (mounted) {
      final ok = await ApiService.probe(ApiService.baseUrl, seconds: 4);
      if (mounted) setState(() => _serverReady = ok == null);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// تسجيل الدخول صار من قاعدة البيانات عبر api/auth.php
  /// الخادم يتحقق من كلمة المرور ويحدد الدور والقسم، لا التطبيق.
  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final id = _idController.text.trim();
    final password = _passwordController.text;

    if (_selectedSection == null && !id.startsWith('300')) {
      _showMessage('اختاري القسم: رجال أو نساء');
      return;
    }
    if (password.isEmpty) {
      _showMessage('أدخلي كلمة المرور');
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await ApiService.login(
        id: id,
        password: password,
        section: _selectedSection == null
            ? null
            : (_selectedSection == 'نساء' ? 'women' : 'men'),
      );

      if (!mounted) return;

      final role = (user['role'] ?? '').toString();
      final section = (user['section'] ?? 'men') == 'women' ? 'نساء' : 'رجال';

      Widget page;
      if (role == 'pilgrim') {
        page = PilgrimDashboard(
          pilgrimId: user['id'].toString(),
          section: section,
        );
      } else if (role == 'supervisor') {
        page = SupervisorDashboard(
          supervisorId: user['id'].toString(),
          section: section,
        );
      } else if (role == 'campaign') {
        page = ManagerDashboard(managerId: user['id'].toString());
      } else {
        _showMessage('نوع حساب غير معروف.');
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final isNetwork = e.message.contains('تعذّر الوصول') ||
          e.message.contains('لا يوجد خادم') ||
          e.message.contains('لم يرد');
      if (isNetwork) {
        setState(() => _serverReady = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'إعدادات الخادم',
              textColor: Colors.white,
              onPressed: _openServerSettings,
            ),
          ),
        );
      } else {
        _showMessage(e.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'إعدادات الخادم',
                      icon: Icon(
                        _serverReady
                            ? Icons.settings_outlined
                            : Icons.wifi_off_rounded,
                        color: _serverReady ? teal : Colors.redAccent,
                      ),
                      onPressed: _openServerSettings,
                    ),
                  ),
                  // الشعار صورة عريضة فيها اسم الشركة تحت الرسم،
                  // فقصّه في دائرة كان يقطع الاسم من الجانبين.
                  Center(
                    child: Container(
                      width: 230,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: teal.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'منصة إدارة الحملة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: darkTeal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'رفقة بلاد الحرمين',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: teal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // رقم الإصدار — لمعرفة أن الجهاز يشغّل آخر نسخة من الملفات
                  const Text(
                    'الإصدار 2.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'مرحبًا بك',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: darkTeal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'سجلي دخولك للوصول إلى حسابك',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 28),

                          const Text(
                            'القسم',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedSection,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'اختاري رجال أو نساء',
                              prefixIcon: const Icon(
                                Icons.groups_outlined,
                                color: teal,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'رجال',
                                child: Text('رجال'),
                              ),
                              DropdownMenuItem(
                                value: 'نساء',
                                child: Text('نساء'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedSection = value;
                              });
                            },
                          ),

                          const SizedBox(height: 20),
                          const Text(
                            'رقم العضوية (ID)',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _idController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(12),
                            ],
                            decoration: InputDecoration(
                              hintText: 'مثال: 100101 أو 500101 أو 30089',
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                color: teal,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  !RegExp(r'^[0-9]{4,12}$')
                                      .hasMatch(value)) {
                                return 'رقم العضوية يجب أن يكون أرقاماً فقط (4 إلى 12 رقماً)';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),
                          const Text(
                            'كلمة المرور',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _hidePassword,
                            decoration: InputDecoration(
                              hintText: 'أدخلي كلمة المرور',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: teal,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _hidePassword = !_hidePassword;
                                  });
                                },
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'أدخلي كلمة المرور';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 28),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                _loading ? 'جاري التحقق...' : 'دخول إلى حسابي',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6FAFA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'قواعد أرقام العضوية',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text('100xxx: حاج أو حاجة'),
                                Text('500xxx: مشرف أو مشرفة متخصص'),
                                Text('5000: المشرف العام'),
                                Text('300xxx: مدير الحملة'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
