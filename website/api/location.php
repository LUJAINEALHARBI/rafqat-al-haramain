<?php
/**
 * تتبع الموقع
 *
 *   GET  location.php?action=sites              مواقع المخيمات والمشاعر من القاعدة
 *   POST location.php?action=report             الحاج يشارك موقعه الحالي
 *   GET  location.php?action=my_last            آخر موقع شاركه الحاج
 *   GET  location.php?action=pilgrims           آخر موقع لكل حاج (للمشرف والإدارة)
 *   GET  location.php?action=history&pilgrim_id=..  مسار حاج معيّن
 *   POST location.php?action=add_site           إضافة موقع (مدير الحملة والمشرف العام)
 *   POST location.php?action=delete_site        حذف موقع أُضيف بالخطأ
 *
 * الإحداثيات كانت مكتوبة داخل صفحة الخريطة، وصارت تُقرأ من جدول
 * site_locations، وموقع الحاج يُحفظ في جدول pilgrim_locations.
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'sites');

switch ($action) {
    case 'sites':       list_sites();      break;
    case 'report':      report_location(); break;
    case 'my_last':     my_last();         break;
    case 'pilgrims':    pilgrims_latest(); break;
    case 'history':     location_history();break;
    case 'add_site':    add_site();        break;
    case 'delete_site': delete_site();     break;
    default: fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
/** يتحقق من الإحداثيات الواردة من المتصفح */
function read_coords(): array
{
    $lat = param('latitude');
    $lng = param('longitude');

    if ($lat === null || $lat === '' || !is_numeric($lat) || $lat < -90 || $lat > 90) {
        fail('خط العرض غير صحيح.', 422);
    }
    if ($lng === null || $lng === '' || !is_numeric($lng) || $lng < -180 || $lng > 180) {
        fail('خط الطول غير صحيح.', 422);
    }
    return [(float) $lat, (float) $lng];
}

// ------------------------------------------------------------------
function list_sites(): void
{
    $u = require_user();

    $sql  = 'SELECT site_id, site_name, site_type, description, period_note,
                    latitude, longitude, section
               FROM site_locations WHERE campaign_id = ?';
    $args = [$u['campaign_id']];

    // الحاج والمشرف المتخصص يريان مواقع قسمهما والمواقع العامة
    if ($u['role'] === 'pilgrim' || ($u['role'] === 'supervisor' && empty($u['is_general']))) {
        $sql   .= " AND (section = 'all' OR section = ?)";
        $args[] = $u['section'] ?? 'all';
    }

    $sql .= ' ORDER BY site_id';

    $st = db()->prepare($sql);
    $st->execute($args);
    $rows = $st->fetchAll();

    foreach ($rows as &$r) {
        $r['site_id']   = (int) $r['site_id'];
        $r['latitude']  = (float) $r['latitude'];
        $r['longitude'] = (float) $r['longitude'];
    }
    unset($r);

    ok($rows);
}

// ------------------------------------------------------------------
function report_location(): void
{
    require_post();
    $u = require_user(['pilgrim']);

    [$lat, $lng] = read_coords();

    $accuracy = param('accuracy');
    $accuracy = ($accuracy === null || $accuracy === '' || !is_numeric($accuracy))
        ? null : (int) $accuracy;

    $note = opt_text('note', 150);

    $st = db()->prepare(
        'INSERT INTO pilgrim_locations (pilgrim_id, latitude, longitude, accuracy_m, note)
         VALUES (?,?,?,?,?)'
    );
    $st->execute([$u['id'], $lat, $lng, $accuracy, $note]);

    ok([
        'location_id' => (int) db()->lastInsertId(),
        'recorded_at' => date('Y-m-d H:i:s'),
        'nearest'     => nearest_site($u['campaign_id'], $lat, $lng, $u['section'] ?? null),
    ]);
}

// ------------------------------------------------------------------
/**
 * أقرب موقع من مواقع الحملة للإحداثيات المعطاة.
 * المسافة تُحسب بصيغة هافرساين المعروفة (نصف قطر الأرض 6371 كم).
 */
function nearest_site(int $campaignId, float $lat, float $lng, ?string $section = null): ?array
{
    $sql = 'SELECT site_name, site_type, latitude, longitude,
                (6371 * ACOS(
                    COS(RADIANS(?)) * COS(RADIANS(latitude)) *
                    COS(RADIANS(longitude) - RADIANS(?)) +
                    SIN(RADIANS(?)) * SIN(RADIANS(latitude))
                )) AS distance_km
           FROM site_locations
          WHERE campaign_id = ?';
    $args = [$lat, $lng, $lat, $campaignId];

    if ($section === 'men' || $section === 'women') {
        $sql   .= " AND (section = 'all' OR section = ?)";
        $args[] = $section;
    }

    $sql .= ' ORDER BY distance_km ASC LIMIT 1';

    $st = db()->prepare($sql);
    $st->execute($args);
    $row = $st->fetch();

    if (!$row) {
        return null;
    }
    return [
        'site_name'   => $row['site_name'],
        'site_type'   => $row['site_type'],
        'distance_km' => round((float) $row['distance_km'], 2),
    ];
}

// ------------------------------------------------------------------
function my_last(): void
{
    $u = require_user(['pilgrim']);

    $st = db()->prepare(
        'SELECT location_id, latitude, longitude, accuracy_m, note, recorded_at
           FROM pilgrim_locations WHERE pilgrim_id = ?
       ORDER BY recorded_at DESC, location_id DESC LIMIT 1'
    );
    $st->execute([$u['id']]);
    $row = $st->fetch();

    if (!$row) {
        ok(null);
    }

    $row['latitude']  = (float) $row['latitude'];
    $row['longitude'] = (float) $row['longitude'];
    $row['nearest']   = nearest_site($u['campaign_id'], $row['latitude'], $row['longitude'], $u['section'] ?? null);

    ok($row);
}

// ------------------------------------------------------------------
function pilgrims_latest(): void
{
    require_user(['supervisor', 'campaign']);
    $u = require_permission('view_locations');

    // آخر صف لكل حاج: نأخذ أكبر location_id لكل حاج ثم نجلب بياناته
    $sql = "SELECT p.pilgrim_id, p.name, p.gender, p.phone, p.camp_id, p.tent_number,
                   l.latitude, l.longitude, l.accuracy_m, l.note, l.recorded_at,
                   TIMESTAMPDIFF(MINUTE, l.recorded_at, NOW()) AS minutes_ago
              FROM pilgrims p
              JOIN pilgrim_locations l
                ON l.location_id = (SELECT MAX(l2.location_id) FROM pilgrim_locations l2
                                     WHERE l2.pilgrim_id = p.pilgrim_id)
             WHERE p.campaign_id = ?";
    $args = [$u['campaign_id']];

    if ($u['role'] === 'supervisor' && empty($u['is_general'])) {
        $sql   .= ' AND p.gender = ?';
        $args[] = ($u['section'] ?? 'men') === 'women' ? 'female' : 'male';
    }

    $sql .= ' ORDER BY l.recorded_at DESC';

    $st = db()->prepare($sql);
    $st->execute($args);
    $rows = $st->fetchAll();

    foreach ($rows as &$r) {
        $r['pilgrim_id'] = (int) $r['pilgrim_id'];
        $r['latitude']   = (float) $r['latitude'];
        $r['longitude']  = (float) $r['longitude'];
        $r['section']    = $r['gender'] === 'female' ? 'women' : 'men';
        $r['minutes_ago'] = $r['minutes_ago'] === null ? null : (int) $r['minutes_ago'];
        $r['nearest']     = nearest_site($u['campaign_id'], $r['latitude'], $r['longitude'], $r['section']);
    }
    unset($r);

    ok($rows);
}

// ------------------------------------------------------------------
function location_history(): void
{
    require_user(['supervisor', 'campaign']);
    $u = require_permission('view_locations');

    $pilgrimId = require_int('pilgrim_id');
    pilgrim_in_scope($pilgrimId, $u);

    $st = db()->prepare(
        'SELECT location_id, latitude, longitude, accuracy_m, note, recorded_at
           FROM pilgrim_locations WHERE pilgrim_id = ?
       ORDER BY recorded_at DESC, location_id DESC LIMIT 20'
    );
    $st->execute([$pilgrimId]);
    $rows = $st->fetchAll();

    foreach ($rows as &$r) {
        $r['latitude']  = (float) $r['latitude'];
        $r['longitude'] = (float) $r['longitude'];
    }
    unset($r);

    ok($rows);
}

// ------------------------------------------------------------------
function add_site(): void
{
    require_post();
    $u = require_permission('manage_sites');

    $name = require_text('site_name', 150);
    [$lat, $lng] = read_coords();

    $st = db()->prepare('SELECT 1 FROM site_locations WHERE campaign_id = ? AND site_name = ?');
    $st->execute([$u['campaign_id'], $name]);
    if ($st->fetch()) {
        fail('يوجد موقع بنفس الاسم في حملتك.', 409);
    }

    $st = db()->prepare(
        'INSERT INTO site_locations
            (campaign_id, site_name, site_type, description, period_note,
             latitude, longitude, section)
         VALUES (?,?,?,?,?,?,?,?)'
    );
    $st->execute([
        $u['campaign_id'],
        $name,
        opt_text('site_type', 60, 'موقع'),
        opt_text('description', 255),
        opt_text('period_note', 150),
        $lat,
        $lng,
        one_of('section', ['men', 'women', 'all'], 'all'),
    ]);

    ok(['site_id' => (int) db()->lastInsertId(), 'site_name' => $name]);
}

// ------------------------------------------------------------------
function delete_site(): void
{
    require_post();
    $u = require_permission('manage_sites');

    $id = require_int('site_id');
    $st = db()->prepare('DELETE FROM site_locations WHERE site_id = ? AND campaign_id = ?');
    $st->execute([$id, $u['campaign_id']]);

    if ($st->rowCount() === 0) {
        fail('الموقع غير موجود في حملتك.', 404);
    }
    ok(['deleted' => $id]);
}
