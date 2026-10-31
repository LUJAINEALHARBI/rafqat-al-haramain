<?php
/**
 * المشرفون
 *
 *   GET supervisors.php?action=list[&section=men|women]
 *   GET supervisors.php?action=profile      (ملف المشرف المسجّل دخوله)
 *   GET supervisors.php?action=jobs         (قائمة الوظائف والصلاحيات)
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'list');

switch ($action) {
    case 'list':    list_supervisors(); break;
    case 'profile': supervisor_profile(); break;
    case 'jobs':    list_jobs();        break;
    default: fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
function list_supervisors(): void
{
    $u = require_user();

    $sql = "SELECT s.supervisor_id, s.name, s.phone, s.email, s.gender_section,
                   j.job_id, j.job_title, j.role_key, j.permission_level
              FROM supervisors s
         LEFT JOIN jobs j ON j.job_id = s.job_id
             WHERE s.campaign_id = ?";
    $args = [$u['campaign_id']];

    $section = one_of('section', ['men', 'women'], null);
    if ($section) {
        $sql .= " AND s.gender_section IN (?, 'all')";
        $args[] = $section;
    }
    $sql .= ' ORDER BY s.supervisor_id';

    $st = db()->prepare($sql);
    $st->execute($args);
    $rows = $st->fetchAll();

    // الحاج يحتاج اسم المشرف ووظيفته وهاتفه فقط،
    // أما وصف الصلاحيات الداخلية فلا يخصّه.
    if (($u['role'] ?? '') === 'pilgrim') {
        $rows = array_map(function (array $r) {
            unset($r['permission_level']);
            return $r;
        }, $rows);
    }

    ok($rows);
}

// ------------------------------------------------------------------
function supervisor_profile(): void
{
    $u = require_user(['supervisor']);

    $st = db()->prepare(
        "SELECT s.supervisor_id, s.name, s.phone, s.email, s.gender_section,
                c.campaign_name, c.location,
                j.job_title, j.role_key, j.permission_level
           FROM supervisors s
      LEFT JOIN jobs j      ON j.job_id = s.job_id
      LEFT JOIN campaigns c ON c.campaign_id = s.campaign_id
          WHERE s.supervisor_id = ? LIMIT 1"
    );
    $st->execute([$u['id']]);
    $row = $st->fetch();

    if (!$row) {
        fail('لم يتم العثور على بيانات المشرف.', 404);
    }

    // القسم الذي يتابعه فعلياً في هذه الجلسة
    $row['active_section'] = $u['section'];
    $row['is_general']     = !empty($u['is_general']);

    // عدد الحجاج تحت إشرافه
    $c = db()->prepare('SELECT COUNT(*) AS n FROM pilgrims WHERE supervisor_id = ?');
    $c->execute([$u['id']]);
    $row['pilgrims_count'] = (int) ($c->fetch()['n'] ?? 0);

    ok($row);
}

// ------------------------------------------------------------------
function list_jobs(): void
{
    $u  = require_user();
    $st = db()->query('SELECT job_id, job_title, permission_level, role_key FROM jobs ORDER BY job_id');
    $rows = $st->fetchAll();

    // نفس القاعدة: وصف الصلاحيات الداخلية لا يُعرض للحاج.
    if (($u['role'] ?? '') === 'pilgrim') {
        $rows = array_map(function (array $r) {
            unset($r['permission_level']);
            return $r;
        }, $rows);
    }

    ok($rows);
}
