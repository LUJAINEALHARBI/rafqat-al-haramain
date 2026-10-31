<?php
/**
 * التنبيهات
 *
 *   GET  notifications.php?action=list
 *   POST notifications.php?action=mark_read      (id)
 *   POST notifications.php?action=mark_all_read
 *   POST notifications.php?action=send           (title, content, target_role, target_section)
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'list');

switch ($action) {
    case 'list':          list_notifications(); break;
    case 'mark_read':     mark_read();          break;
    case 'mark_all_read': mark_all_read();      break;
    case 'send':          send_notification();  break;
    default: fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
function list_notifications(): void
{
    $u = require_user();

    // يرى التنبيهات الموجّهة لدوره أو لقسمه أو للجميع،
    // بالإضافة إلى التنبيهات الموجّهة له شخصياً.
    $sql = "SELECT n.notification_id, n.title, n.content, n.type, n.icon,
                   n.is_read, n.sent_at, s.name AS sender_name
              FROM notifications n
         LEFT JOIN supervisors s ON s.supervisor_id = n.supervisor_id
             WHERE n.campaign_id = ?
               AND (n.target_role = ? OR n.target_role = 'all')
               AND (n.target_section = ? OR n.target_section = 'all')";
    $args = [$u['campaign_id'], $u['role'], $u['section']];

    if ($u['role'] === 'pilgrim') {
        $sql .= ' AND (n.pilgrim_id IS NULL OR n.pilgrim_id = ?)';
        $args[] = $u['id'];
    }

    $sql .= ' ORDER BY n.sent_at DESC, n.notification_id DESC';

    $st = db()->prepare($sql);
    $st->execute($args);
    $rows = $st->fetchAll();

    foreach ($rows as &$r) {
        $r['is_read'] = (bool) $r['is_read'];
        $r['time_ago'] = time_ago($r['sent_at']);
    }
    ok($rows);
}

function time_ago(?string $datetime): string
{
    if (!$datetime) {
        return '';
    }
    $diff = time() - strtotime($datetime);
    if ($diff < 60)     return 'الآن';
    if ($diff < 3600)   return 'منذ ' . intdiv($diff, 60) . ' دقيقة';
    if ($diff < 86400)  return 'منذ ' . intdiv($diff, 3600) . ' ساعة';
    if ($diff < 172800) return 'أمس';
    return 'منذ ' . intdiv($diff, 86400) . ' يوم';
}

// ------------------------------------------------------------------
function mark_read(): void
{
    require_post();
    $u  = require_user();
    $id = require_int('id');

    $st = db()->prepare(
        'UPDATE notifications SET is_read = 1
          WHERE notification_id = ? AND campaign_id = ?'
    );
    $st->execute([$id, $u['campaign_id']]);
    ok(['updated' => $st->rowCount()]);
}

// ------------------------------------------------------------------
function mark_all_read(): void
{
    require_post();
    $u = require_user();

    $st = db()->prepare(
        "UPDATE notifications SET is_read = 1
          WHERE campaign_id = ?
            AND (target_role = ? OR target_role = 'all')
            AND (target_section = ? OR target_section = 'all')"
    );
    $st->execute([$u['campaign_id'], $u['role'], $u['section']]);
    ok(['updated' => $st->rowCount()]);
}

// ------------------------------------------------------------------
function send_notification(): void
{
    require_post();
    $u = require_user(['supervisor', 'campaign']);

    $title   = require_text('title', 150);
    $content = opt_text('content', 2000, '');
    $role    = one_of('target_role', ['pilgrim', 'supervisor', 'campaign', 'all'], 'all');
    $section = one_of('target_section', ['men', 'women', 'all'], 'all');

    $st = db()->prepare(
        'INSERT INTO notifications
            (supervisor_id, campaign_id, target_role, target_section, title, content, type, icon)
         VALUES (?,?,?,?,?,?,?,?)'
    );
    $st->execute([
        $u['role'] === 'supervisor' ? $u['id'] : null,
        $u['campaign_id'],
        $role,
        $section,
        $title,
        $content,
        opt_text('type', 50, 'عام'),
        opt_text('icon', 10, '📢'),
    ]);

    ok(['notification_id' => (int) db()->lastInsertId()]);
}
