<?php
/**
 * برنامج المناسك — رحلة الحج ومحطاتها
 *
 *   GET  journey.php?action=program[&program_id=..]   الرحلة ومحطاتها ونسبة التقدم
 *   GET  journey.php?action=programs                   قائمة البرامج (للمشرف والإدارة)
 *   POST journey.php?action=add_program                إنشاء برنامج رحلة
 *   POST journey.php?action=update_program             تعديل بيانات البرنامج
 *   POST journey.php?action=add_station                إضافة محطة للرحلة
 *   POST journey.php?action=update_station             تعديل محطة
 *   POST journey.php?action=set_status                 تحديد المحطة: منجزة / جارية / لم تبدأ
 *   POST journey.php?action=move_station               تغيير ترتيب المحطة
 *   POST journey.php?action=delete_station             حذف محطة أضافها المشرف
 *
 * الحاج يقرأ رحلته كاملة: ما انتهى وما بقي ومتى وبأي وسيلة انتقال.
 * المشرف هو من ينشئ الرحلة ويرتّب محطاتها ويحدّث حالتها.
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'program');

switch ($action) {
    case 'program':        get_program();     break;
    case 'programs':       list_programs();   break;
    case 'add_program':    add_program();     break;
    case 'update_program': update_program();  break;
    case 'add_station':    add_station();     break;
    case 'update_station': update_station();  break;
    case 'set_status':     set_status();      break;
    case 'move_station':   move_station();    break;
    case 'delete_station': delete_station();  break;
    default: fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
/** وسائل الانتقال المسموحة — نفس قيم عمود transport_type */
function transport_options(): array
{
    return ['لا يوجد', 'سيراً على القدم', 'حافلة', 'قطار المشاعر', 'سيارة'];
}

/** حالات المحطة المسموحة */
function station_statuses(): array
{
    return ['لم تبدأ', 'جارية', 'مكتملة'];
}

/**
 * يرجع البرنامج المطلوب بعد التأكد أنه يتبع حملة المستخدم.
 * بدون program_id يرجع البرنامج النشط المناسب لقسم المستخدم.
 */
function find_program(array $u, ?int $programId): array
{
    $pdo = db();

    if ($programId) {
        $st = $pdo->prepare(
            'SELECT * FROM journey_programs WHERE program_id = ? AND campaign_id = ? LIMIT 1'
        );
        $st->execute([$programId, $u['campaign_id']]);
    } else {
        // الحاج يرى برنامج قسمه أو البرنامج العام، والأحدث أولاً
        $section = $u['section'] ?? 'all';
        $st = $pdo->prepare(
            "SELECT * FROM journey_programs
              WHERE campaign_id = ? AND is_active = 1
                AND (section = 'all' OR section = ?)
           ORDER BY program_id DESC LIMIT 1"
        );
        $st->execute([$u['campaign_id'], $section]);
    }

    $row = $st->fetch();
    if (!$row) {
        fail('لا يوجد برنامج مناسك منشور لحملتك بعد.', 404);
    }
    return $row;
}

// ------------------------------------------------------------------
function get_program(): void
{
    $u  = require_user();
    $id = param('program_id') ? (int) param('program_id') : null;

    $program = find_program($u, $id);

    $st = db()->prepare(
        'SELECT s.station_id, s.station_order, s.station_name, s.place_name, s.hijri_day,
                s.start_datetime, s.end_datetime, s.transport_type,
                s.latitude, s.longitude, s.notes, s.status, s.completed_at,
                sup.name AS updated_by_name
           FROM journey_stations s
      LEFT JOIN supervisors sup ON sup.supervisor_id = s.updated_by
          WHERE s.program_id = ?
       ORDER BY s.station_order'
    );
    $st->execute([$program['program_id']]);
    $stations = $st->fetchAll();

    $done = 0;
    $current = null;
    foreach ($stations as &$s) {
        $s['station_id']    = (int) $s['station_id'];
        $s['station_order'] = (int) $s['station_order'];
        if ($s['status'] === 'مكتملة') {
            $done++;
        }
        if ($current === null && $s['status'] !== 'مكتملة') {
            $current = $s;
        }
    }
    unset($s);

    $total = count($stations);

    ok([
        'program'  => [
            'program_id'   => (int) $program['program_id'],
            'program_name' => $program['program_name'],
            'hijri_year'   => $program['hijri_year'],
            'section'      => $program['section'],
            'notes'        => $program['notes'],
            'is_active'    => (bool) $program['is_active'],
        ],
        'stations' => $stations,
        'progress' => [
            'total'     => $total,
            'done'      => $done,
            'remaining' => $total - $done,
            'percent'   => $total ? (int) round($done * 100 / $total) : 0,
            'current'   => $current,
        ],
        'can_manage' => can('manage_journey'),
        'options'    => [
            'transport' => transport_options(),
            'statuses'  => station_statuses(),
        ],
    ]);
}

// ------------------------------------------------------------------
function list_programs(): void
{
    $u = require_user(['supervisor', 'campaign']);

    $st = db()->prepare(
        'SELECT p.program_id, p.program_name, p.hijri_year, p.section, p.notes,
                p.is_active, p.created_at, sup.name AS created_by_name,
                (SELECT COUNT(*) FROM journey_stations s WHERE s.program_id = p.program_id) AS stations_count,
                (SELECT COUNT(*) FROM journey_stations s
                  WHERE s.program_id = p.program_id AND s.status = ?) AS done_count
           FROM journey_programs p
      LEFT JOIN supervisors sup ON sup.supervisor_id = p.created_by
          WHERE p.campaign_id = ?
       ORDER BY p.program_id DESC'
    );
    $st->execute(['مكتملة', $u['campaign_id']]);
    $rows = $st->fetchAll();

    foreach ($rows as &$r) {
        $r['program_id']     = (int) $r['program_id'];
        $r['stations_count'] = (int) $r['stations_count'];
        $r['done_count']     = (int) $r['done_count'];
        $r['is_active']      = (bool) $r['is_active'];
        $r['percent']        = $r['stations_count']
            ? (int) round($r['done_count'] * 100 / $r['stations_count']) : 0;
    }
    unset($r);

    ok($rows);
}

// ------------------------------------------------------------------
function add_program(): void
{
    require_post();
    $u = require_permission('manage_journey');

    $name    = require_text('program_name', 150);
    $year    = opt_text('hijri_year', 10);
    $section = one_of('section', ['men', 'women', 'all'], 'all');
    $notes   = opt_text('notes', 1000);

    $st = db()->prepare(
        'SELECT 1 FROM journey_programs WHERE campaign_id = ? AND program_name = ?'
    );
    $st->execute([$u['campaign_id'], $name]);
    if ($st->fetch()) {
        fail('يوجد برنامج بنفس الاسم في حملتك. اختاري اسماً آخر.', 409);
    }

    $st = db()->prepare(
        'INSERT INTO journey_programs
            (campaign_id, program_name, hijri_year, section, notes, is_active, created_by)
         VALUES (?,?,?,?,?,1,?)'
    );
    $st->execute([
        $u['campaign_id'], $name, $year, $section, $notes,
        $u['role'] === 'supervisor' ? $u['id'] : null,
    ]);

    ok(['program_id' => (int) db()->lastInsertId(), 'program_name' => $name]);
}

// ------------------------------------------------------------------
function update_program(): void
{
    require_post();
    $u = require_permission('manage_journey');

    $program = find_program($u, require_int('program_id'));

    $active = param('is_active');
    $st = db()->prepare(
        'UPDATE journey_programs
            SET program_name = COALESCE(?, program_name),
                hijri_year   = COALESCE(?, hijri_year),
                section      = COALESCE(?, section),
                notes        = COALESCE(?, notes),
                is_active    = COALESCE(?, is_active)
          WHERE program_id = ? AND campaign_id = ?'
    );
    $st->execute([
        opt_text('program_name', 150),
        opt_text('hijri_year', 10),
        one_of('section', ['men', 'women', 'all'], null),
        opt_text('notes', 1000),
        ($active === null || $active === '') ? null : (int) (bool) $active,
        $program['program_id'],
        $u['campaign_id'],
    ]);

    ok(['program_id' => (int) $program['program_id'], 'updated' => $st->rowCount()]);
}

// ------------------------------------------------------------------
/** يقرأ حقول المحطة المشتركة بين الإضافة والتعديل */
function station_input(): array
{
    $lat = param('latitude');
    $lng = param('longitude');

    if ($lat !== null && $lat !== '' && (!is_numeric($lat) || $lat < -90 || $lat > 90)) {
        fail('خط العرض يجب أن يكون رقماً بين -90 و 90.', 422);
    }
    if ($lng !== null && $lng !== '' && (!is_numeric($lng) || $lng < -180 || $lng > 180)) {
        fail('خط الطول يجب أن يكون رقماً بين -180 و 180.', 422);
    }

    $start = opt_text('start_datetime', 20);
    $end   = opt_text('end_datetime', 20);

    // النموذج يرسل التاريخ بصيغة 2026-05-22T05:00 فنحوّلها لصيغة القاعدة
    $fix = function (?string $v): ?string {
        if ($v === null || $v === '') {
            return null;
        }
        $v = str_replace('T', ' ', $v);
        return strlen($v) === 16 ? $v . ':00' : $v;
    };

    if ($start && $end && $fix($start) > $fix($end)) {
        fail('وقت نهاية المحطة يجب أن يكون بعد وقت بدايتها.', 422);
    }

    return [
        'station_name'   => require_text('station_name', 150),
        'place_name'     => opt_text('place_name', 120),
        'hijri_day'      => opt_text('hijri_day', 40),
        'start_datetime' => $fix($start),
        'end_datetime'   => $fix($end),
        'transport_type' => one_of('transport_type', transport_options(), 'لا يوجد'),
        'latitude'       => ($lat === null || $lat === '') ? null : (float) $lat,
        'longitude'      => ($lng === null || $lng === '') ? null : (float) $lng,
        'notes'          => opt_text('notes', 1000),
    ];
}

// ------------------------------------------------------------------
function add_station(): void
{
    require_post();
    $u = require_permission('manage_journey');

    $program = find_program($u, require_int('program_id'));
    $in      = station_input();

    $pdo = db();
    $st  = $pdo->prepare('SELECT COALESCE(MAX(station_order), 0) + 1 FROM journey_stations WHERE program_id = ?');
    $st->execute([$program['program_id']]);
    $order = (int) $st->fetchColumn();

    $st = $pdo->prepare(
        'INSERT INTO journey_stations
            (program_id, station_order, station_name, place_name, hijri_day,
             start_datetime, end_datetime, transport_type, latitude, longitude,
             notes, status, updated_by)
         VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)'
    );
    $st->execute([
        $program['program_id'], $order,
        $in['station_name'], $in['place_name'], $in['hijri_day'],
        $in['start_datetime'], $in['end_datetime'], $in['transport_type'],
        $in['latitude'], $in['longitude'], $in['notes'],
        'لم تبدأ',
        $u['role'] === 'supervisor' ? $u['id'] : null,
    ]);

    ok(['station_id' => (int) $pdo->lastInsertId(), 'station_order' => $order]);
}

// ------------------------------------------------------------------
/** يتأكد أن المحطة تتبع برنامجاً في حملة المستخدم */
function station_in_scope(int $stationId, array $u): array
{
    $st = db()->prepare(
        'SELECT s.*, p.campaign_id
           FROM journey_stations s
           JOIN journey_programs p ON p.program_id = s.program_id
          WHERE s.station_id = ? LIMIT 1'
    );
    $st->execute([$stationId]);
    $row = $st->fetch();

    if (!$row) {
        fail('المحطة غير موجودة.', 404);
    }
    if ((int) $row['campaign_id'] !== (int) $u['campaign_id']) {
        fail('هذه المحطة ليست من برامج حملتك.', 403);
    }
    return $row;
}

// ------------------------------------------------------------------
function update_station(): void
{
    require_post();
    $u = require_permission('manage_journey');

    $station = station_in_scope(require_int('station_id'), $u);
    $in      = station_input();

    $st = db()->prepare(
        'UPDATE journey_stations
            SET station_name = ?, place_name = ?, hijri_day = ?,
                start_datetime = ?, end_datetime = ?, transport_type = ?,
                latitude = ?, longitude = ?, notes = ?, updated_by = ?
          WHERE station_id = ?'
    );
    $st->execute([
        $in['station_name'], $in['place_name'], $in['hijri_day'],
        $in['start_datetime'], $in['end_datetime'], $in['transport_type'],
        $in['latitude'], $in['longitude'], $in['notes'],
        $u['role'] === 'supervisor' ? $u['id'] : null,
        $station['station_id'],
    ]);

    ok(['station_id' => (int) $station['station_id']]);
}

// ------------------------------------------------------------------
function set_status(): void
{
    require_post();
    $u = require_permission('manage_journey');

    $station = station_in_scope(require_int('station_id'), $u);
    $status  = one_of('status', station_statuses(), null);
    if ($status === null) {
        fail('حالة المحطة مطلوبة: لم تبدأ أو جارية أو مكتملة.', 422);
    }

    $st = db()->prepare(
        'UPDATE journey_stations
            SET status = ?, completed_at = ?, updated_by = ?
          WHERE station_id = ?'
    );
    $st->execute([
        $status,
        $status === 'مكتملة' ? date('Y-m-d H:i:s') : null,
        $u['role'] === 'supervisor' ? $u['id'] : null,
        $station['station_id'],
    ]);

    ok([
        'station_id' => (int) $station['station_id'],
        'status'     => $status,
    ]);
}

// ------------------------------------------------------------------
function move_station(): void
{
    require_post();
    $u = require_permission('manage_journey');

    $station   = station_in_scope(require_int('station_id'), $u);
    $direction = one_of('direction', ['up', 'down'], 'up');
    $pdo       = db();

    // المحطة المجاورة في اتجاه الحركة
    $st = $pdo->prepare(
        $direction === 'up'
            ? 'SELECT station_id, station_order FROM journey_stations
                WHERE program_id = ? AND station_order < ?
             ORDER BY station_order DESC LIMIT 1'
            : 'SELECT station_id, station_order FROM journey_stations
                WHERE program_id = ? AND station_order > ?
             ORDER BY station_order ASC LIMIT 1'
    );
    $st->execute([$station['program_id'], $station['station_order']]);
    $neighbour = $st->fetch();

    if (!$neighbour) {
        ok(['moved' => false, 'message' => 'المحطة في طرف الترتيب أصلاً.']);
    }

    // التبديل على ثلاث خطوات لأن الترتيب داخل البرنامج فريد
    $pdo->beginTransaction();
    try {
        $upd = $pdo->prepare('UPDATE journey_stations SET station_order = ? WHERE station_id = ?');
        $upd->execute([-1, $station['station_id']]);
        $upd->execute([(int) $station['station_order'], $neighbour['station_id']]);
        $upd->execute([(int) $neighbour['station_order'], $station['station_id']]);
        $pdo->commit();
    } catch (Throwable $e) {
        $pdo->rollBack();
        fail('تعذّر تغيير الترتيب.', 500, $e->getMessage());
    }

    ok(['moved' => true, 'station_order' => (int) $neighbour['station_order']]);
}

// ------------------------------------------------------------------
function delete_station(): void
{
    require_post();
    $u = require_permission('manage_journey');

    $station = station_in_scope(require_int('station_id'), $u);

    $st = db()->prepare('DELETE FROM journey_stations WHERE station_id = ?');
    $st->execute([$station['station_id']]);

    ok(['deleted' => (int) $station['station_id']]);
}
