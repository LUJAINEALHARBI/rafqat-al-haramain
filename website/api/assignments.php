<?php
/**
 * توزيع الحجاج على المخيمات والمشرفين
 *
 *   GET  assignments.php?action=list
 *   POST assignments.php?action=assign   (pilgrim_ids[], camp_id, supervisor_id)
 *   POST assignments.php?action=auto     (توزيع تلقائي على المشرفين المتخصصين)
 *   POST assignments.php?action=remove   (pilgrim_id)
 *
 * الإسناد يُحفظ في جدول pilgrims نفسه (supervisor_id + camp_id)،
 * فلا حاجة لجدول توزيع منفصل.
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'list');

switch ($action) {
    case 'list':   list_assignments();  break;
    case 'assign': assign_batch();      break;
    case 'auto':   auto_distribute();   break;
    case 'remove': remove_assignment(); break;
    default: fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
function list_assignments(): void
{
    $u = require_user(['campaign', 'supervisor']);

    $st = db()->prepare(
        "SELECT p.pilgrim_id, p.name AS pilgrim_name, p.gender, p.camp_id,
                p.supervisor_id, s.name AS supervisor_name, j.job_title
           FROM pilgrims p
      LEFT JOIN supervisors s ON s.supervisor_id = p.supervisor_id
      LEFT JOIN jobs j        ON j.job_id = s.job_id
          WHERE p.campaign_id = ?
            AND p.camp_id IS NOT NULL
            AND p.supervisor_id IS NOT NULL
       ORDER BY p.camp_id, p.pilgrim_id"
    );
    $st->execute([$u['campaign_id']]);
    $rows = $st->fetchAll();

    foreach ($rows as &$r) {
        $r['section']    = $r['gender'] === 'female' ? 'women' : 'men';
        $r['supervisor'] = $r['job_title'] ?: $r['supervisor_name'];
    }
    ok($rows);
}

// ------------------------------------------------------------------
function assign_batch(): void
{
    require_post();
    require_user(['campaign']);
    $u   = require_permission('edit_pilgrims');
    $pdo = db();

    $ids = param('pilgrim_ids');
    if (is_string($ids)) {
        $ids = array_filter(explode(',', $ids));
    }
    if (!is_array($ids) || !$ids) {
        fail('الرجاء تحديد حاج واحد على الأقل.', 422);
    }

    $campId       = require_text('camp_id', 20);
    $supervisorId = require_int('supervisor_id');

    if (!preg_match('/^[A-Za-z0-9\-]{1,20}$/', $campId)) {
        fail('رقم المخيم غير صالح.', 422);
    }

    $st = $pdo->prepare('SELECT 1 FROM supervisors WHERE supervisor_id = ? AND campaign_id = ?');
    $st->execute([$supervisorId, $u['campaign_id']]);
    if (!$st->fetch()) {
        fail('المشرف غير موجود في هذه الحملة.', 422);
    }

    $pdo->beginTransaction();
    try {
        $upd = $pdo->prepare(
            'UPDATE pilgrims SET supervisor_id = ?, camp_id = ?
              WHERE pilgrim_id = ? AND campaign_id = ?'
        );
        $count = 0;
        foreach ($ids as $pid) {
            if (!ctype_digit((string) $pid)) {
                continue;
            }
            $upd->execute([$supervisorId, $campId, (int) $pid, $u['campaign_id']]);
            $count += $upd->rowCount();
        }
        $pdo->commit();
    } catch (Throwable $e) {
        $pdo->rollBack();
        fail('تعذّر حفظ التوزيع.', 500, $e->getMessage());
    }

    ok(['assigned' => $count]);
}

// ------------------------------------------------------------------
function auto_distribute(): void
{
    require_post();
    $u   = require_user(['campaign']);
    $pdo = db();

    // المشرفون المتخصصون فقط (بدون المشرف العام) مقسّمين حسب القسم
    $st = $pdo->prepare(
        "SELECT s.supervisor_id, s.gender_section
           FROM supervisors s
      LEFT JOIN jobs j ON j.job_id = s.job_id
          WHERE s.campaign_id = ? AND s.gender_section <> 'all'
       ORDER BY s.supervisor_id"
    );
    $st->execute([$u['campaign_id']]);
    $sups = $st->fetchAll();

    if (!$sups) {
        fail('لا يوجد مشرفون متخصصون لتوزيع الحجاج عليهم.', 422);
    }

    $bySection = ['men' => [], 'women' => []];
    foreach ($sups as $s) {
        $bySection[$s['gender_section']][] = (int) $s['supervisor_id'];
    }

    $st = $pdo->prepare('SELECT pilgrim_id, gender FROM pilgrims WHERE campaign_id = ? ORDER BY pilgrim_id');
    $st->execute([$u['campaign_id']]);
    $pilgrims = $st->fetchAll();

    $pdo->beginTransaction();
    try {
        $upd = $pdo->prepare('UPDATE pilgrims SET supervisor_id = ?, camp_id = ? WHERE pilgrim_id = ?');
        $counters = ['men' => 0, 'women' => 0];
        $count = 0;

        foreach ($pilgrims as $p) {
            $section = $p['gender'] === 'female' ? 'women' : 'men';
            $pool    = $bySection[$section];
            if (!$pool) {
                continue;
            }
            $sup    = $pool[$counters[$section] % count($pool)];
            $campId = $section === 'men' ? 'CAMP-101' : 'CAMP-201';
            $counters[$section]++;

            $upd->execute([$sup, $campId, (int) $p['pilgrim_id']]);
            $count++;
        }
        $pdo->commit();
    } catch (Throwable $e) {
        $pdo->rollBack();
        fail('تعذّر تنفيذ التوزيع التلقائي.', 500, $e->getMessage());
    }

    ok(['assigned' => $count]);
}

// ------------------------------------------------------------------
function remove_assignment(): void
{
    require_post();
    $u  = require_user(['campaign']);
    $id = require_int('pilgrim_id');

    $st = db()->prepare(
        'UPDATE pilgrims SET supervisor_id = NULL, camp_id = NULL
          WHERE pilgrim_id = ? AND campaign_id = ?'
    );
    $st->execute([$id, $u['campaign_id']]);

    ok(['removed' => $st->rowCount()]);
}
