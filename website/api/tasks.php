<?php
/**
 * مهام المشرف
 *
 *   GET  tasks.php?action=list
 *   POST tasks.php?action=update_status   (id, status)
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'list');

switch ($action) {
    case 'list':          list_tasks();   break;
    case 'update_status': update_status(); break;
    default: fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
function list_tasks(): void
{
    $u = require_user(['supervisor', 'campaign']);

    if ($u['role'] === 'supervisor') {
        $st = db()->prepare(
            'SELECT task_id, title, description, status
               FROM supervisor_tasks WHERE supervisor_id = ? ORDER BY task_id'
        );
        $st->execute([$u['id']]);
    } else {
        $st = db()->prepare(
            'SELECT t.task_id, t.title, t.description, t.status, s.name AS supervisor_name
               FROM supervisor_tasks t
               JOIN supervisors s ON s.supervisor_id = t.supervisor_id
              WHERE s.campaign_id = ? ORDER BY t.task_id'
        );
        $st->execute([$u['campaign_id']]);
    }

    ok($st->fetchAll());
}

// ------------------------------------------------------------------
function update_status(): void
{
    require_post();
    $u = require_user(['supervisor']);

    $id     = require_int('id');
    $status = require_text('status', 50);

    $st = db()->prepare(
        'UPDATE supervisor_tasks SET status = ?
          WHERE task_id = ? AND supervisor_id = ?'
    );
    $st->execute([$status, $id, $u['id']]);

    if ($st->rowCount() === 0) {
        fail('المهمة غير موجودة أو ليست من مهامك.', 404);
    }
    ok(['task_id' => $id, 'status' => $status]);
}
