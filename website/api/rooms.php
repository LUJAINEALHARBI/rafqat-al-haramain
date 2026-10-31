<?php
/**
 * غرف المحادثة والرسائل
 *
 *   GET  rooms.php?action=rooms
 *   GET  rooms.php?action=messages&room_id=..
 *   POST rooms.php?action=send   (room_id, message)
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'rooms');

switch ($action) {
    case 'rooms':    list_rooms();    break;
    case 'messages': list_messages(); break;
    case 'send':     send_message();  break;
    default: fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
function list_rooms(): void
{
    $u = require_user();

    $sql = "SELECT room_id, room_name, section, staff_only, message_type
              FROM chat_rooms
             WHERE campaign_id = ? AND (section = ? OR section = 'all')";
    $args = [$u['campaign_id'], $u['section']];

    // غرفة المشرفين والإدارة لا تظهر للحاج
    if ($u['role'] === 'pilgrim') {
        $sql .= ' AND staff_only = 0';
    }
    $sql .= ' ORDER BY room_id';

    $st = db()->prepare($sql);
    $st->execute($args);
    ok($st->fetchAll());
}

// ------------------------------------------------------------------
function list_messages(): void
{
    $u      = require_user();
    $roomId = require_int('room_id');

    assert_room_access($roomId, $u);

    $st = db()->prepare(
        'SELECT message_id, sender_type, sender_id, sender_name, message_text, sent_at
           FROM messages WHERE room_id = ?
       ORDER BY message_id ASC LIMIT 200'
    );
    $st->execute([$roomId]);
    $rows = $st->fetchAll();

    foreach ($rows as &$r) {
        // هل الرسالة من المستخدم الحالي؟ لعرضها على اليمين
        $r['mine'] = ($r['sender_type'] === $u['role'] && (int) $r['sender_id'] === (int) $u['id']);
    }
    ok($rows);
}

// ------------------------------------------------------------------
function send_message(): void
{
    require_post();
    $u = require_user();

    $roomId = require_int('room_id');
    $text   = require_text('message', 1000);

    assert_room_access($roomId, $u);

    $st = db()->prepare(
        'INSERT INTO messages (room_id, sender_type, sender_id, sender_name, message_text)
         VALUES (?,?,?,?,?)'
    );
    $st->execute([$roomId, $u['role'], $u['id'], $u['name'], $text]);

    ok(['message_id' => (int) db()->lastInsertId()]);
}

// ------------------------------------------------------------------
/** يمنع الدخول لغرفة قسم آخر أو حملة أخرى */
function assert_room_access(int $roomId, array $u): void
{
    $st = db()->prepare('SELECT campaign_id, section, staff_only FROM chat_rooms WHERE room_id = ?');
    $st->execute([$roomId]);
    $room = $st->fetch();

    if (!$room) {
        fail('الغرفة غير موجودة.', 404);
    }
    if ((int) $room['campaign_id'] !== (int) $u['campaign_id']) {
        fail('ليس لديك صلاحية لهذه الغرفة.', 403);
    }
    if ($room['section'] !== 'all' && $room['section'] !== $u['section']) {
        fail('هذه الغرفة مخصصة لقسم آخر.', 403);
    }
    if ((int) $room['staff_only'] === 1 && $u['role'] === 'pilgrim') {
        fail('هذه الغرفة مخصصة للمشرفين وإدارة الحملة.', 403);
    }
}
