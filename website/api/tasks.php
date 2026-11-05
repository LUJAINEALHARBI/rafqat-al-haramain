<?php
/**
 * مهام المشرف
 *
 *   GET  tasks.php?action=list
 *   POST tasks.php?action=update_status   (id, status)
 *   GET  tasks.php?action=statuses        (الحالات المسموح بها)
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'list');

switch ($action) {
    case 'list':          list_tasks();   break;
    case 'update_status': update_status(); break;
    case 'statuses':      list_statuses(); break;
    default: fail('عملية غير معروفة.', 404);
}

/**
 * الحالات التي يستطيع المشرف اختيارها لمهمته.
 * الحالات القديمة في قاعدة البيانات (مجدول، معتمد، جاهز...) تبقى كما هي
 * وتُعرض كما سجّلتها الحملة، لكن التحديث يكون إلى إحدى هذه الحالات.
 */
function task_statuses(): array
{
    return ['نشط', 'قيد المتابعة', 'مكتمل'];
}

function list_statuses(): void
{
    require_user(['supervisor', 'campaign']);
    ok(task_statuses());
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

    if (!in_array($status, task_statuses(), true)) {
        fail('حالة غير مسموحة. المسموح: ' . implode(' / ', task_statuses()) . '.', 422);
    }

    // نتأكد أولاً أن المهمة موجودة وأنها من مهام هذا المشرف.
    // سابقاً كنا نعتمد على عدد الصفوف المتأثرة بالتعديل، وقاعدة البيانات
    // ترجع صفراً أيضاً حين تكون الحالة الجديدة مطابقة للقديمة، فكانت
    // تظهر رسالة "المهمة غير موجودة" لمهمة موجودة فعلاً ولم تتغير حالتها.
    $st = db()->prepare(
        'SELECT status FROM supervisor_tasks WHERE task_id = ? AND supervisor_id = ? LIMIT 1'
    );
    $st->execute([$id, $u['id']]);
    $current = $st->fetchColumn();

    if ($current === false) {
        fail('هذه المهمة ليست ضمن مهامك.', 404);
    }

    if ($current === $status) {
        ok(['task_id' => $id, 'status' => $status, 'changed' => false]);
    }

    $st = db()->prepare(
        'UPDATE supervisor_tasks SET status = ? WHERE task_id = ? AND supervisor_id = ?'
    );
    $st->execute([$status, $id, $u['id']]);

    ok(['task_id' => $id, 'status' => $status, 'changed' => true]);
}
