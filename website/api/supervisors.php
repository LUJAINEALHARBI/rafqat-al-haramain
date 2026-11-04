<?php
/**
 * المشرفون
 *
 *   GET supervisors.php?action=list[&section=men|women]
 *   GET supervisors.php?action=profile      (ملف المشرف المسجّل دخوله)
 *   GET supervisors.php?action=jobs         (قائمة الوظائف والصلاحيات)
 *   GET supervisors.php?action=permissions  (مصفوفة صلاحيات الوظائف — للمراجعة)
 *   GET supervisors.php?action=my_permissions (صلاحيات المستخدم الحالي)
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'list');

switch ($action) {
    case 'list':    list_supervisors(); break;
    case 'profile': supervisor_profile(); break;
    case 'jobs':    list_jobs();        break;
    case 'permissions':    permissions_matrix(); break;
    case 'my_permissions': my_permissions();     break;
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

    // صلاحيات وظيفته مقروءة من جدول job_permissions
    $row['permissions'] = user_permissions();

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

// ------------------------------------------------------------------
/**
 * مصفوفة الصلاحيات: كل وظيفة وما يُسمح لها به، تُقرأ من جدولي
 * app_permissions و job_permissions لتراجعها إدارة الحملة على الشاشة.
 */
function permissions_matrix(): void
{
    require_user(['campaign', 'supervisor']);

    $perms = db()->query(
        'SELECT permission_key, permission_label, category
           FROM app_permissions ORDER BY category, permission_key'
    )->fetchAll();

    $jobs = db()->query(
        'SELECT job_id, job_title, role_key, permission_level FROM jobs ORDER BY job_id'
    )->fetchAll();

    $pairs = db()->query('SELECT job_id, permission_key FROM job_permissions')->fetchAll();

    $byJob = [];
    foreach ($pairs as $row) {
        $byJob[(int) $row['job_id']][] = $row['permission_key'];
    }

    foreach ($jobs as &$job) {
        $job['job_id']      = (int) $job['job_id'];
        $job['permissions'] = $byJob[$job['job_id']] ?? [];
    }
    unset($job);

    // عدد المشرفين في كل وظيفة داخل الحملة
    $u  = current_user();
    $st = db()->prepare(
        'SELECT job_id, COUNT(*) AS n FROM supervisors WHERE campaign_id = ? GROUP BY job_id'
    );
    $st->execute([$u['campaign_id']]);
    $counts = [];
    foreach ($st->fetchAll() as $row) {
        $counts[(int) $row['job_id']] = (int) $row['n'];
    }
    foreach ($jobs as &$job) {
        $job['supervisors_count'] = $counts[$job['job_id']] ?? 0;
    }
    unset($job);

    ok(['permissions' => $perms, 'jobs' => $jobs]);
}

// ------------------------------------------------------------------
/** صلاحيات المستخدم الحالي بأسمائها العربية */
function my_permissions(): void
{
    $u    = require_user();
    $keys = user_permissions();

    if (!$keys) {
        ok(['role' => $u['role'], 'keys' => [], 'list' => []]);
    }

    $in = implode(',', array_fill(0, count($keys), '?'));
    $st = db()->prepare(
        "SELECT permission_key, permission_label, category
           FROM app_permissions WHERE permission_key IN ($in)
       ORDER BY category, permission_key"
    );
    $st->execute($keys);

    ok(['role' => $u['role'], 'keys' => $keys, 'list' => $st->fetchAll()]);
}
