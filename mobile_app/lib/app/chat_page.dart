import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatPage extends StatefulWidget {
  final String userRole;
  final String userId;

  const ChatPage({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);

  List<Map<String, dynamic>> conversations = [];
  bool loading = true;
  String? loadError;

  /// الغرف تُقرأ من جدول chat_rooms عبر api/rooms.php?action=rooms
  Future<void> _loadRooms() async {
    try {
      final rows = await ApiService.get('rooms.php', 'rooms') as List;
      if (!mounted) return;
      setState(() {
        conversations = rows.map<Map<String, dynamic>>((e) {
          final r = e as Map;
          final type = (r['message_type'] ?? '').toString();
          return {
            'id': r['room_id'],
            'title': (r['room_name'] ?? 'غرفة').toString(),
            'subtitle': type.isEmpty ? 'محادثة الحملة' : type,
            'icon': type == 'إشراف'
                ? Icons.supervisor_account_rounded
                : Icons.groups_rounded,
            'messages': <Map<String, dynamic>>[],
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

  @override
  void initState() {
    super.initState();

    // قيم أولية تُستبدل بغرف قاعدة البيانات فور تحميلها

    if (widget.userRole == 'حاج' ||
        widget.userRole == 'حاجة') {
      conversations = [
        {
          'title': 'مشرف مجموعتي',
          'subtitle': 'للاستفسارات وطلب المساعدة',
          'icon': Icons.support_agent_rounded,
          'messages': <Map<String, dynamic>>[],
        },
        {
          'title': 'الدعم الفني',
          'subtitle': 'مساعدة في استخدام التطبيق',
          'icon': Icons.headset_mic_rounded,
          'messages': <Map<String, dynamic>>[],
        },
      ];
    } else if (widget.userRole == 'مشرف' ||
        widget.userRole == 'مشرفة') {
      conversations = [
        {
          'title': 'مجموعة الحجاج',
          'subtitle': 'محادثة متابعة المجموعة',
          'icon': Icons.groups_rounded,
          'messages': <Map<String, dynamic>>[],
        },
        {
          'title': 'الدعم الفني',
          'subtitle': 'المساعدة التقنية',
          'icon': Icons.headset_mic_rounded,
          'messages': <Map<String, dynamic>>[],
        },
      ];
    } else {
      conversations = [
        {
          'title': 'المشرفون',
          'subtitle': 'التواصل مع المشرفين',
          'icon': Icons.supervisor_account_rounded,
          'messages': <Map<String, dynamic>>[],
        },
        {
          'title': 'الدعم الفني',
          'subtitle': 'المساعدة التقنية',
          'icon': Icons.headset_mic_rounded,
          'messages': <Map<String, dynamic>>[],
        },
      ];
    }

    _loadRooms();
  }

  void openConversation(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationRoomPage(
          roomId: conversation['id'],
          title: conversation['title'] as String,
          messages:
              conversation['messages'] as List<Map<String, dynamic>>,
          senderName: widget.userRole,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
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
          title: const Text('المحادثات'),
          centerTitle: true,
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'تعذّر تحميل المحادثات من قاعدة البيانات:\n$loadError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAFA),
        appBar: AppBar(
          title: const Text(
            'المحادثات والدعم الفني',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.forum_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'نحن هنا لمساعدتك',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'اختر المحادثة المناسبة للتواصل',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            ...conversations.map((conversation) {
              final messages =
                  conversation['messages'] as List<Map<String, dynamic>>;

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFE3F4F2),
                    child: Icon(
                      conversation['icon'] as IconData,
                      color: green,
                    ),
                  ),
                  title: Text(
                    conversation['title'] as String,
                    style: const TextStyle(
                      color: darkGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      messages.isEmpty
                          ? conversation['subtitle'] as String
                          : messages.last['text'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: green,
                  ),
                  onTap: () => openConversation(conversation),
                ),
              );
            }),
            const SizedBox(height: 12),
            const Text(
              'ملاحظة: هذه نسخة تجريبية؛ الرسائل ليست متصلة بمستخدمين آخرين.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConversationRoomPage extends StatefulWidget {
  /// رقم الغرفة في جدول chat_rooms
  final dynamic roomId;
  final String title;
  final List<Map<String, dynamic>> messages;
  final String senderName;

  const ConversationRoomPage({
    super.key,
    required this.roomId,
    required this.title,
    required this.messages,
    required this.senderName,
  });

  @override
  State<ConversationRoomPage> createState() =>
      _ConversationRoomPageState();
}

class _ConversationRoomPageState extends State<ConversationRoomPage> {
  static const Color green = Color(0xFF277D78);
  static const Color darkGreen = Color(0xFF244C4A);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// الرسائل تُقرأ من جدول messages عبر api/rooms.php?action=messages
  Future<void> _loadMessages() async {
    try {
      final rows = await ApiService.get(
        'rooms.php',
        'messages',
        {'room_id': '${widget.roomId}'},
      ) as List;
      if (!mounted) return;
      setState(() {
        widget.messages
          ..clear()
          ..addAll(rows.map<Map<String, dynamic>>((e) {
            final r = e as Map;
            return {
              'text': (r['message_text'] ?? '').toString(),
              'sender': (r['sender_name'] ?? '').toString(),
              'time': (r['sent_at'] ?? '').toString(),
            };
          }));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || sending) return;

    setState(() => sending = true);

    try {
      // الرسالة تُحفظ في قاعدة البيانات عبر api/rooms.php?action=send
      await ApiService.post('rooms.php', 'send', {
        'room_id': widget.roomId,
        'message': text,
      });
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }

    _controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAFA),
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Expanded(
              child: widget.messages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 60,
                            color: green,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'ابدأ المحادثة بكتابة رسالتك',
                            style: TextStyle(color: darkGreen),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.messages.length,
                      itemBuilder: (context, index) {
                        final message = widget.messages[index];

                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.8,
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F4F2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['sender'] as String,
                                  style: const TextStyle(
                                    color: darkGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(message['text'] as String),
                                const SizedBox(height: 5),
                                Text(
                                  message['time'] as String,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك هنا...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded),
                    tooltip: 'إرسال',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}