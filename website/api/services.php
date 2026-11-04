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
