<?php
/**
 * الخدمات وطلباتها
 *
 *   GET  services.php?action=list              (أنواع الخدمات المتاحة)
 *   GET  services.php?action=requests          (طلبات الخدمة / service_provisions)
 *   POST services.php?action=request           (service_id, details) — من الحاج
 *   POST services.php?action=update_status     (id, status) — من المشرف
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'list');

switch ($action) {
    case 'list':          list_services();   break;
    case 'requests':      list_requests();   break;
    case 'request':       create_request();  break;
    case 'update_status': update_status();   break;
    case 'my_services':   my_services();     break;
    case 'add':           add_service();     break;
    case 'update':        update_service();  break;
    case 'availability':  set_availability();break;
    default: fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
function list_services(): void
{
    require_user();
    $st = db()->query(
        "SELECT service_id, service_name, description, service_type,
                service_datetime, service_location, status
           FROM services ORDER BY service_id"
    );
    ok($st->fetchAll());
}

// ------------------------------------------------------------------
function list_requests(): void
{
    $u = require_user();

    $sql = "SELECT sp.provision_id, sp.request_number, sp.details, sp.status,
                   sp.provision_date, sp.provision_time,
                   s.service_name, s.service_type,
                   p.pilgrim_id, p.name AS pilgrim_name, p.gender,
                   sup.name AS supervisor_name, j.job_title
              FROM service_provisions sp
              JOIN services  s   ON s.service_id   = sp.service_id
              JOIN pilgrims  p   ON p.pilgrim_id   = sp.pilgrim_id
         LEFT JOIN supervisors sup ON sup.supervisor_id = sp.supervisor_id
         LEFT JOIN jobs j          ON j.job_id = sup.job_id
             WHERE p.campaign_id = ?";
    $args = [$u['campaign_id']];

    if ($u['role'] === 'pilgrim') {
        $sql .= ' AND sp.pilgrim_id = ?';
        $args[] = $u['id'];
    } elseif ($u['role'] === 'supervisor') {

        // المشرف المتخصص يرى طلبات تخصصه فقط:
        // الطلبات الطبية مثلاً لا تظهر لموظف الإعاشة ولا لموظف السكن.
        if (empty($u['is_general'])) {
            $sql .= ' AND s.service_type = (SELECT j.role_key FROM supervisors sv
                                              JOIN jobs j ON j.job_id = sv.job_id
                                             WHERE sv.supervisor_id = ?)';
            $args[] = $u['id'];
        }

        // والجميع — بما فيهم المشرف العام — يرون قسمهم الحالي
        $gender = section_gender(viewing_section($u));
        if ($gender !== null) {
            $sql .= ' AND p.gender = ?';
            $args[] = $gender;
        }
    }

    $sql .= ' ORDER BY sp.provision_id DESC';

    $st = db()->prepare($sql);
    $st->execute($args);
    $rows = $st->fetchAll();

    foreach ($rows as &$r) {
        $r['section'] = $r['gender'] === 'female' ? 'women' : 'men';
    }
    ok($rows);
}

// ------------------------------------------------------------------
function create_request(): void
{
    require_post();
    $u = require_user(['pilgrim']);

    $serviceId = require_int('service_id');
    $details   = opt_text('details', 255, '');

    $pdo = db();

    $st = $pdo->prepare("SELECT service_type, status FROM services WHERE service_id = ?");
    $st->execute([$serviceId]);
    $service = $st->fetch();

    if (!$service) {
        fail('الخدمة غير موجودة.', 404);
    }
    if ($service['status'] === 'غير متاحة') {
        fail('هذه الخدمة غير متاحة حالياً.', 422);
    }

    // توجيه الطلب للمشرف المختص بنفس قسم الحاج
    $st = $pdo->prepare(
        "SELECT s.supervisor_id
           FROM supervisors s JOIN jobs j ON j.job_id = s.job_id
          WHERE s.campaign_id = ? AND j.role_key = ? AND s.gender_section = ?
          LIMIT 1"
    );
    $st->execute([$u['campaign_id'], $service['service_type'], $u['section']]);
    $supervisorId = $st->fetch()['supervisor_id'] ?? null;

    $prefix = strtoupper(substr($service['service_type'] ?? 'REQ', 0, 3));

    $st = $pdo->prepare(
        'INSERT INTO service_provisions
            (pilgrim_id, service_id, supervisor_id, request_number, details,
             provision_date, provision_time, status)
         VALUES (?,?,?,?,?,?,?,?)'
    );
    $st->execute([
        $u['id'],
        $serviceId,
        $supervisorId,
        $prefix . '-' . random_int(100, 999),
        $details,
        date('Y-m-d'),
        date('H:i:s'),
        'قيد المباشرة',
    ]);

    ok(['provision_id' => (int) $pdo->lastInsertId()]);
}

// ------------------------------------------------------------------
function update_status(): void
{
    require_post();
    $u = require_user(['supervisor', 'campaign']);

    $id     = require_int('id');
    $status = require_text('status', 50);

    // نوع الخدمة يحدّد الصلاحية المطلوبة لتحديث الطلب
    $st = db()->prepare(
        'SELECT s.service_type
           FROM service_provisions sp JOIN services s ON s.service_id = sp.service_id
          WHERE sp.provision_id = ? LIMIT 1'
    );
    $st->execute([$id]);
    $serviceType = $st->fetchColumn();
    if ($serviceType === false) {
        fail('الطلب غير موجود.', 404);
    }
    require_permission(service_type_permission($serviceType));

    if ($u['role'] === 'supervisor' && empty($u['is_general'])) {
        // الطلب يجب أن يكون من نوع تخصصه ومن قسمه، سواء كان موجّهاً
        // إليه بالاسم أو لم يُوجّه لأحد بعد
        $st = db()->prepare(
            'UPDATE service_provisions sp
               JOIN services s  ON s.service_id = sp.service_id
               JOIN pilgrims p  ON p.pilgrim_id = sp.pilgrim_id
                SET sp.status = ?, sp.supervisor_id = ?
              WHERE sp.provision_id = ?
                AND p.campaign_id = ?
                AND p.gender = ?
                AND s.service_type = (SELECT j.role_key FROM supervisors sv
                                        JOIN jobs j ON j.job_id = sv.job_id
                                       WHERE sv.supervisor_id = ?)'
        );
        $st->execute([
            $status,
            $u['id'],
            $id,
            $u['campaign_id'],
            ($u['section'] ?? 'men') === 'women' ? 'female' : 'male',
            $u['id'],
        ]);
    } else {
        $st = db()->prepare(
            'UPDATE service_provisions SET status = ?
              WHERE provision_id = ?
                AND pilgrim_id IN (SELECT pilgrim_id FROM pilgrims WHERE campaign_id = ?)'
        );
        $st->execute([$status, $id, $u['campaign_id']]);
    }

    if ($st->rowCount() === 0) {
        fail('الطلب غير موجود أو ليس ضمن صلاحيتك.', 404);
    }
    ok(['provision_id' => $id, 'status' => $status]);
}

// ------------------------------------------------------------------
// إدارة خدمات التخصص
// ------------------------------------------------------------------

/**
 * أنواع الخدمات التي يملك المستخدم الحالي إدارتها.
 * موظف الإعاشة يدير خدمات catering فقط، والصحي medical فقط،
 * والمشرف العام ومدير الحملة يديران الأنواع كلها.
 */
function manageable_types(): array
{
    $types = ['medical', 'crowd', 'catering', 'housing', 'general'];

    return array_values(array_filter($types, function (string $t) {
        return can(service_type_permission($t));
    }));
}

/** الاسم العربي لنوع الخدمة */
function service_type_label(string $type): string
{
    switch ($type) {
        case 'medical':  return 'الرعاية الطبية';
        case 'crowd':    return 'التفويج والتنقل';
        case 'catering': return 'الإعاشة والوجبات';
        case 'housing':  return 'السكن والخيام';
        default:         return 'خدمات عامة';
    }
}

/** يتأكد أن المستخدم يملك إدارة هذا النوع */
function require_service_type(string $type): void
{
    if (!in_array($type, manageable_types(), true)) {
        fail('خدمات "' . service_type_label($type) . '" ليست ضمن تخصصك.', 403);
    }
}

// ------------------------------------------------------------------
/** خدمات تخصص المستخدم مع الأنواع التي يستطيع إضافتها */
function my_services(): void
{
    require_user(['supervisor', 'campaign']);

    $types = manageable_types();
    if (!$types) {
        ok(['types' => [], 'services' => []]);
    }

    $in = implode(',', array_fill(0, count($types), '?'));
    $st = db()->prepare(
        "SELECT service_id, service_name, description, service_type,
                service_datetime, service_location, status,
                (SELECT COUNT(*) FROM service_provisions sp
                  WHERE sp.service_id = services.service_id) AS requests_count
           FROM services WHERE service_type IN ($in)
       ORDER BY service_type, service_id"
    );
    $st->execute($types);
    $rows = $st->fetchAll();

    foreach ($rows as &$r) {
        $r['service_id']     = (int) $r['service_id'];
        $r['requests_count'] = (int) $r['requests_count'];
        $r['type_label']     = service_type_label((string) $r['service_type']);
    }
    unset($r);

    ok([
        'types' => array_map(function (string $t) {
            return ['key' => $t, 'label' => service_type_label($t)];
        }, $types),
        'services' => $rows,
    ]);
}

// ------------------------------------------------------------------
/** يقرأ حقول الخدمة المشتركة بين الإضافة والتعديل */
function service_input(): array
{
    $when = opt_text('service_datetime', 20);

    // النموذج يرسل 2026-05-21T06:00 فنحوّلها لصيغة القاعدة
    if ($when !== null && $when !== '') {
        $when = str_replace('T', ' ', $when);
        if (strlen($when) === 16) {
            $when .= ':00';
        }
    } else {
        $when = null;
    }

    return [
        'service_name'     => require_text('service_name', 150),
        'description'      => opt_text('description', 1000),
        'service_datetime' => $when,
        'service_location' => opt_text('service_location', 255),
        'status'           => one_of('status', ['متاحة', 'غير متاحة'], 'متاحة'),
    ];
}

// ------------------------------------------------------------------
function add_service(): void
{
    require_post();
    require_user(['supervisor', 'campaign']);

    $type = require_text('service_type', 80);
    require_service_type($type);

    $in = service_input();

    $st = db()->prepare('SELECT 1 FROM services WHERE service_name = ?');
    $st->execute([$in['service_name']]);
    if ($st->fetch()) {
        fail('يوجد خدمة بنفس الاسم. اختاري اسماً مختلفاً.', 409);
    }

    $st = db()->prepare(
        'INSERT INTO services
            (service_name, description, service_type, service_datetime, service_location, status)
         VALUES (?,?,?,?,?,?)'
    );
    $st->execute([
        $in['service_name'], $in['description'], $type,
        $in['service_datetime'], $in['service_location'], $in['status'],
    ]);

    ok(['service_id' => (int) db()->lastInsertId(), 'service_name' => $in['service_name']]);
}

// ------------------------------------------------------------------
/** يجلب الخدمة ويتأكد أنها ضمن تخصص المستخدم */
function service_in_scope(int $id): array
{
    $st = db()->prepare('SELECT * FROM services WHERE service_id = ? LIMIT 1');
    $st->execute([$id]);
    $row = $st->fetch();

    if (!$row) {
        fail('الخدمة غير موجودة.', 404);
    }
    require_service_type((string) $row['service_type']);

    return $row;
}

// ------------------------------------------------------------------
function update_service(): void
{
    require_post();
    require_user(['supervisor', 'campaign']);

    $service = service_in_scope(require_int('service_id'));
    $in      = service_input();

    $st = db()->prepare(
        'UPDATE services
            SET service_name = ?, description = ?, service_datetime = ?,
                service_location = ?, status = ?
          WHERE service_id = ?'
    );
    $st->execute([
        $in['service_name'], $in['description'], $in['service_datetime'],
        $in['service_location'], $in['status'], $service['service_id'],
    ]);

    ok(['service_id' => (int) $service['service_id']]);
}

// ------------------------------------------------------------------
/**
 * إيقاف الخدمة أو تفعيلها.
 * لا يوجد حذف: حذف الخدمة يحذف معها طلبات الحجاج المرتبطة بها،
 * فالإيقاف يخفيها عن الحاج ويبقي سجل الطلبات كما هو.
 */
function set_availability(): void
{
    require_post();
    require_user(['supervisor', 'campaign']);

    $service = service_in_scope(require_int('service_id'));
    $status  = one_of('status', ['متاحة', 'غير متاحة'], null);

    if ($status === null) {
        fail('حدّدي الحالة: متاحة أو غير متاحة.', 422);
    }

    $st = db()->prepare('UPDATE services SET status = ? WHERE service_id = ?');
    $st->execute([$status, $service['service_id']]);

    ok(['service_id' => (int) $service['service_id'], 'status' => $status]);
}
