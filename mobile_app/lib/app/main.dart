import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pilgrim_dashboard.dart';
import 'supervisor_dashboard.dart';
import 'manager_dashboard.dart';

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

  static const Color teal = Color(0xFF277D78);
  static const Color darkTeal = Color(0xFF245B58);

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _login() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final id = _idController.text.trim();
    final password = _passwordController.text;

    if (_selectedSection == null && !id.startsWith('300')) {
      _showMessage('اختاري القسم: رجال أو نساء');
      return;
    }

    late String role;

    if (id.startsWith('100')) {
      role = _selectedSection == 'نساء' ? 'حاجة' : 'حاج';
    } else if (id.startsWith('500')) {
      role = _selectedSection == 'نساء' ? 'مشرفة' : 'مشرف';
    } else if (id.startsWith('300')) {
      role = 'مدير الحملة';
    } else {
      _showMessage(
        'رقم العضوية يجب أن يبدأ بـ 100 أو 500 أو 300',
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage('أدخلي كلمة المرور');
      return;
    }
if (id.startsWith('100')) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => PilgrimDashboard(
        pilgrimId: id,
        section: _selectedSection ?? 'رجال',
      ),
    ),
  );
} else if (id.startsWith('500')) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => SupervisorDashboard(
        supervisorId: id,
        section: _selectedSection ?? 'رجال',
      ),
    ),
  );
} else if (id.startsWith('300')) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ManagerDashboard(managerId: id),
    ),
  );
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
                  const SizedBox(height: 20),
                  Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: teal.withOpacity(0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
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
                  const SizedBox(height: 28),
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
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'دخول إلى حسابي',
                                style: TextStyle(
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
