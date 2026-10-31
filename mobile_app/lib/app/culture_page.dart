import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CulturePage extends StatefulWidget {
  const CulturePage({super.key});

  @override
  State<CulturePage> createState() => _CulturePageState();
}

class _CulturePageState extends State<CulturePage> {
  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);

  int questionIndex = 0;
  int score = 0;
  int? selectedAnswer;
  bool answered = false;
  bool finished = false;

  bool loading = true;
  String? loadError;

  /// الأسئلة تُقرأ من جدول cultural_questions عبر api/cultural.php
  /// والتصحيح يتم في الخادم، لا داخل التطبيق.
  List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final rows = await ApiService.get('cultural.php', 'list') as List;
      if (!mounted) return;
      setState(() {
        questions = rows.map<Map<String, dynamic>>((e) {
          final r = e as Map;
          return {
            'id': r['question_id'],
            'question': (r['question_text'] ?? '').toString(),
            'answers': List<String>.from(
              (r['options'] as List).map((o) => o.toString()),
            ),
            'correct': -1, // يُحدَّد من رد الخادم بعد الإجابة
          };
        }).toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadError = e.toString();
        loading = false;
      });
    }
  }

  final List<Map<String, dynamic>> _fallbackQuestions = [
    {
      'question': 'ما الركن الأعظم من أركان الحج؟',
      'answers': ['السعي', 'الوقوف بعرفة', 'طواف الوداع'],
      'correct': 1,
    },
    {
      'question': 'كم عدد أشواط الطواف حول الكعبة؟',
      'answers': ['خمسة', 'ستة', 'سبعة'],
      'correct': 2,
    },
    {
      'question': 'ما اسم البئر المشهورة في المسجد الحرام؟',
      'answers': ['زمزم', 'بدر', 'أريس'],
      'correct': 0,
    },
    {
      'question': 'كم عدد أشواط السعي بين الصفا والمروة؟',
      'answers': ['خمسة', 'سبعة', 'تسعة'],
      'correct': 1,
    },
  ];

  Future<void> selectAnswer(int index) async {
    if (answered || questions.isEmpty) return;

    final q = questions[questionIndex];
    final answers = q['answers'] as List<String>;

    setState(() {
      selectedAnswer = index;
      answered = true;
    });

    try {
      // التصحيح يتم في الخادم ويُسجَّل في جدول cultural_answers
      final res = await ApiService.post('cultural.php', 'answer', {
        'question_id': q['id'],
        'answer': answers[index],
      }) as Map;

      if (!mounted) return;
      setState(() {
        q['correct'] = answers.indexOf((res['correct_answer'] ?? '').toString());
        if (res['is_correct'] == true) score++;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() => answered = false);
    }
  }

  void nextQuestion() {
    setState(() {
      if (questionIndex < questions.length - 1) {
        questionIndex++;
        selectedAnswer = null;
        answered = false;
      } else {
        finished = true;
      }
    });
  }

  void restartQuiz() {
    setState(() {
      questionIndex = 0;
      score = 0;
      selectedAnswer = null;
      answered = false;
      finished = false;
      for (final q in questions) {
        q['correct'] = -1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6FAFA),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6FAFA),
        appBar: AppBar(
          title: const Text('المسابقة الثقافية'),
          centerTitle: true,
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'تعذّر تحميل الأسئلة من قاعدة البيانات:\n$loadError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }
    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6FAFA),
        appBar: AppBar(
          title: const Text('المسابقة الثقافية'),
          centerTitle: true,
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('لا توجد أسئلة منشورة حالياً.'),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAFA),
        appBar: AppBar(
          title: const Text('الثقافة والفعاليات'),
          centerTitle: true,
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
        ),
        body: finished
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFE6A23C),
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'أحسنت! انتهى الاختبار',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'نتيجتك: $score من ${questions.length}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: restartQuiz,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة الاختبار'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [green, darkGreen],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.mosque_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'رحلتك معرفة وأجر',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'اختبر معلوماتك عن مناسك الحج',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'السؤال ${questionIndex + 1} من ${questions.length}',
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    questions[questionIndex]['question'] as String,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...(questions[questionIndex]['answers'] as List<String>)
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final answer = entry.value;
                    final correct =
                        index == questions[questionIndex]['correct'];

                    Color answerColor = Colors.white;
                    if (answered && correct) {
                      answerColor = const Color(0xFFDDF3E5);
                    } else if (answered && index == selectedAnswer) {
                      answerColor = const Color(0xFFFFE1E1);
                    }

                    return Card(
                      color: answerColor,
                      child: ListTile(
                        title: Text(answer),
                        trailing: answered && correct
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : null,
                        onTap: () => selectAnswer(index),
                      ),
                    );
                  }),
                  if (answered) ...[
                    const SizedBox(height: 12),
                    Text(
                      selectedAnswer ==
                              questions[questionIndex]['correct']
                          ? 'إجابة صحيحة، أحسنت!'
                          : 'الإجابة الصحيحة: '
                              '${(questions[questionIndex]['answers']
                                  as List<String>)[questions[questionIndex]['correct']]}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        questionIndex == questions.length - 1
                            ? 'عرض النتيجة'
                            : 'السؤال التالي',
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}