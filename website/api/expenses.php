<?php
/**
 * القيود والمصروفات المالية
 *
 *   GET  expenses.php?action=list[&supervisor_id=..]
 *   POST expenses.php?action=add       (description, amount, category, receipt[ملف])
 *   POST expenses.php?action=approve   (id)   — مدير الحملة فقط
 *   POST expenses.php?action=delete    (id)   — مدير الحملة فقط
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'list');

switch ($action) {
    case 'list':    list_expenses();   break;
    case 'add':     add_expense();     break;
    case 'approve': approve_expense(); break;
    case 'delete':  delete_expense();  break;
    default: fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
function list_expenses(): void
{
    $u = require_user(['campaign', 'supervisor']);

    $sql = "SELECT e.expense_id, e.description, e.amount, e.category,
                   e.expense_date, e.receipt_file, e.status, e.supervisor_id,
                   s.name AS supervisor_name
              FROM expenses e
         LEFT JOIN supervisors s ON s.supervisor_id = e.supervisor_id
             WHERE e.campaign_id = ?";
    $args = [$u['campaign_id']];

    // مشرف متخصص يرى قيوده فقط؛ المشرف العام ومدير الحملة يرون الكل
    if ($u['role'] === 'supervisor' && empty($u['is_general'])) {
        $sql .= ' AND e.supervisor_id = ?';
        $args[] = $u['id'];
    } elseif (param('supervisor_id')) {
        $sql .= ' AND e.supervisor_id = ?';
        $args[] = (int) param('supervisor_id');
    }

    $sql .= ' ORDER BY e.expense_id DESC';

    $st = db()->prepare($sql);
    $st->execute($args);
    $rows = $st->fetchAll();

    $total = 0.0;
    $withReceipt = 0;
    foreach ($rows as &$r) {
        $r['amount']      = (float) $r['amount'];
        $r['hasReceipt']  = !empty($r['receipt_file']);
        $total += $r['amount'];
        if ($r['hasReceipt']) {
            $withReceipt++;
        }
    }

    ok($rows, ['summary' => [
        'count'        => count($rows),
        'total'        => $total,
        'withReceipt'  => $withReceipt,
    ]]);
}

// ------------------------------------------------------------------
function add_expense(): void
{
    require_post();
    require_user(['supervisor', 'campaign']);
    // تسجيل المصروفات من مهام المشرف العام ومدير الحملة،
    // ولا تدخل في مهام الموظف الصحي أو الإعاشة أو السكن
    $u = require_permission('manage_expenses');

    $description = require_text('description', 255);

    $amount = param('amount');
    if (!is_numeric($amount) || (float) $amount <= 0) {
        fail('المبلغ يجب أن يكون رقماً أكبر من صفر.', 422);
    }
    if ((float) $amount > 99999999) {
        fail('المبلغ أكبر من المسموح.', 422);
    }

    $receipt = save_upload('receipt');

    $st = db()->prepare(
        'INSERT INTO expenses
            (campaign_id, supervisor_id, description, amount, category,
             expense_date, receipt_file, status)
         VALUES (?,?,?,?,?,?,?,?)'
    );
    $st->execute([
        $u['campaign_id'],
        $u['role'] === 'supervisor' ? $u['id'] : null,
        $description,
        (float) $amount,
        opt_text('category', 80, 'أخرى'),
        date('Y-m-d'),
        $receipt,
        'مرحّل',
    ]);

    ok(['expense_id' => (int) db()->lastInsertId()]);
}

// ------------------------------------------------------------------
function approve_expense(): void
{
    require_post();
    require_user(['campaign']);
    $u  = require_permission('approve_expenses');
    $id = require_int('id');

    $st = db()->prepare(
        "UPDATE expenses SET status = 'معتمد'
          WHERE expense_id = ? AND campaign_id = ?"
    );
    $st->execute([$id, $u['campaign_id']]);

    if ($st->rowCount() === 0) {
        fail('لم يتم العثور على القيد أو أنه معتمد مسبقاً.', 404);
    }
    ok(['approved' => $id]);
}

// ------------------------------------------------------------------
function delete_expense(): void
{
    require_post();
    $u  = require_user(['campaign']);
    $id = require_int('id');

    $st = db()->prepare('DELETE FROM expenses WHERE expense_id = ? AND campaign_id = ?');
    $st->execute([$id, $u['campaign_id']]);

    if ($st->rowCount() === 0) {
        fail('لا يوجد قيد بهذا الرقم.', 404);
    }
    ok(['deleted' => $id]);
}
