<?php
/**
 * تقييمات الحجاج
 *
 *   GET  ratings.php?action=list     (مع ملخص المعدل العام) — مدير الحملة والمشرف
 *   POST ratings.php?action=add      — من الحاج
 *          service_id   : الخدمة المقيَّمة (من نافذة "تقييم الخدمات")
 *          provision_id : (اختياري) طلب خدمة محدد خاص بالحاج
 *          stars        : 1..5
 *          comment      : نص اختياري
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'list');

switch ($action) {
    case 'list': list_ratings(); break;
    case 'add':  add_rating();   break;
    default: fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
function list_ratings(): void
{
    $u = require_user(['campaign', 'supervisor']);

    // موضوع التقييم: الخدمة المختارة مباشرة، أو خدمة الطلب إن قُيِّم طلب محدد
    $st = db()->prepare(
        "SELECT r.rating_id, r.stars, r.comment, r.rating_date,
                p.name AS pilgrim_name, p.gender,
                COALESCE(s.service_name, s2.service_name, 'عام') AS topic
           FROM ratings r
           JOIN pilgrims p                ON p.pilgrim_id    = r.pilgrim_id
      LEFT JOIN services s                ON s.service_id    = r.service_id
      LEFT JOIN service_provisions sp     ON sp.provision_id = r.provision_id
      LEFT JOIN services s2               ON s2.service_id   = sp.service_id
          WHERE p.campaign_id = ?
       ORDER BY r.rating_id DESC"
    );
    $st->execute([$u['campaign_id']]);
    $rows = $st->fetchAll();

    $sum = 0;
    foreach ($rows as &$r) {
        $r['stars']   = (int) $r['stars'];
        $r['section'] = $r['gender'] === 'female' ? 'women' : 'men';
        $sum += $r['stars'];
    }

    $avg = $rows ? round($sum / count($rows), 1) : 0;

    ok($rows, ['summary' => ['average' => $avg, 'count' => count($rows)]]);
}

// ------------------------------------------------------------------
function add_rating(): void
{
    require_post();
    $u = require_user(['pilgrim']);

    $stars = require_int('stars');
    if ($stars < 1 || $stars > 5) {
        fail('التقييم يجب أن يكون من 1 إلى 5 نجوم.', 422);
    }

    $serviceId   = param('service_id');
    $provisionId = param('provision_id');
    $serviceId   = ($serviceId   === null || $serviceId   === '') ? null : (int) $serviceId;
    $provisionId = ($provisionId === null || $provisionId === '') ? null : (int) $provisionId;

    if ($serviceId === null && $provisionId === null) {
        fail('حدّد الخدمة المراد تقييمها.', 422);
    }

    $pdo = db();

    if ($serviceId !== null) {
        $st = $pdo->prepare('SELECT 1 FROM services WHERE service_id = ?');
        $st->execute([$serviceId]);
        if (!$st->fetch()) {
            fail('الخدمة غير موجودة.', 404);
        }
    }

    // لا يقيّم الحاج إلا طلباً قُدّم له هو
    if ($provisionId !== null) {
        $st = $pdo->prepare('SELECT 1 FROM service_provisions WHERE provision_id = ? AND pilgrim_id = ?');
        $st->execute([$provisionId, $u['id']]);
        if (!$st->fetch()) {
            fail('لا يمكنك تقييم خدمة ليست لك.', 403);
        }
    }

    $st = $pdo->prepare(
        'INSERT INTO ratings (pilgrim_id, service_id, provision_id, stars, comment)
         VALUES (?,?,?,?,?)'
    );
    $st->execute([$u['id'], $serviceId, $provisionId, $stars, opt_text('comment', 1000, '')]);

    ok(['rating_id' => (int) $pdo->lastInsertId()]);
}
