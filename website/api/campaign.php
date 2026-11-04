<?php
/**
 * ملف الحملة
 *
 *   GET  campaign.php?action=get
 *   POST campaign.php?action=update    (مدير الحملة فقط)
 *   GET  campaign.php?action=stats     (أرقام مختصرة للوحة الإدارة)
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'get');

switch ($action) {
    case 'get':    get_campaign();    break;
    case 'update': update_campaign(); break;
    case 'stats':  campaign_stats();  break;
    default: fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
function get_campaign(): void
{
    $u = require_user();

    $st = db()->prepare(
        'SELECT campaign_id, campaign_name, license_number, phone, location, extra_info,
                company_name, manager_name, manager_email, manager_phone,
                price_per_person, start_city, start_date
           FROM campaigns WHERE campaign_id = ? LIMIT 1'
    );
    $st->execute([$u['campaign_id']]);
    $row = $st->fetch();

    if (!$row) {
        fail('لم يتم العثور على بيانات الحملة.', 404);
    }

    // الحاج يحتاج اسم الحملة ومقرها وهاتفها، أما رقم الترخيص وبيانات
    // اتصال المدير الشخصية فهي بيانات إدارية لا تخصه.
    if (($u['role'] ?? '') === 'pilgrim') {
        unset($row['license_number'], $row['manager_email'], $row['manager_phone']);
    }

    ok($row);
}

// ------------------------------------------------------------------
function update_campaign(): void
{
    require_post();
    $u = require_user(['campaign']);

    $email = opt_text('manager_email', 150);
    if ($email !== null && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        fail('صيغة بريد المدير غير صحيحة.', 422);
    }

    $price = param('price_per_person');
    if ($price !== null && $price !== '' && !is_numeric($price)) {
        fail('سعر الفرد يجب أن يكون رقماً.', 422);
    }
    $price = ($price === null || $price === '') ? null : (float) $price;

    $startDate = opt_text('start_date', 20);
    if ($startDate !== null && !preg_match('/^\d{4}-\d{2}-\d{2}$/', $startDate)) {
        $startDate = null;
    }

    $st = db()->prepare(
        'UPDATE campaigns SET
            campaign_name    = COALESCE(?, campaign_name),
            company_name     = COALESCE(?, company_name),
            license_number   = COALESCE(?, license_number),
            phone            = COALESCE(?, phone),
            location         = COALESCE(?, location),
            extra_info       = COALESCE(?, extra_info),
            manager_name     = COALESCE(?, manager_name),
            manager_email    = COALESCE(?, manager_email),
            manager_phone    = COALESCE(?, manager_phone),
            price_per_person = COALESCE(?, price_per_person),
            start_city       = COALESCE(?, start_city),
            start_date       = COALESCE(?, start_date)
          WHERE campaign_id = ?'
    );
    $st->execute([
        opt_text('campaign_name', 150),
        opt_text('company_name', 150),
        opt_text('license_number', 50),
        opt_text('phone', 20),
        opt_text('location', 255),
        opt_text('extra_info', 2000),
        opt_text('manager_name', 100),
        $email,
        opt_text('manager_phone', 20),
        $price,
        opt_text('start_city', 80),
        $startDate,
        $u['campaign_id'],
    ]);

    ok(['updated' => true]);
}

// ------------------------------------------------------------------
function campaign_stats(): void
{
    $u   = require_user(['campaign', 'supervisor']);
    $pdo = db();
    $cid = $u['campaign_id'];

    $q = function (string $sql, array $args) use ($pdo) {
        $st = $pdo->prepare($sql);
        $st->execute($args);
        return $st->fetch();
    };

    $pilgrims = $q(
        "SELECT COUNT(*) AS total,
                SUM(gender = 'male')   AS men,
                SUM(gender = 'female') AS women
           FROM pilgrims WHERE campaign_id = ?", [$cid]
    );

    $sups = $q('SELECT COUNT(*) AS total FROM supervisors WHERE campaign_id = ?', [$cid]);

    $exp = $q(
        "SELECT COUNT(*) AS count, COALESCE(SUM(amount),0) AS total,
                COALESCE(SUM(status = 'معتمد'),0) AS approved
           FROM expenses WHERE campaign_id = ?", [$cid]
    );

    // توزيع الحجاج على المخيمات وعدد من تم تسكينه فعلاً
    $st = $pdo->prepare(
        "SELECT camp_id, gender, COUNT(*) AS total,
                SUM(tent_number IS NOT NULL AND tent_number <> '') AS housed
           FROM pilgrims
          WHERE campaign_id = ? AND camp_id IS NOT NULL AND camp_id <> ''
       GROUP BY camp_id, gender
       ORDER BY camp_id"
    );
    $st->execute([$cid]);

    $camps = [];
    foreach ($st->fetchAll() as $row) {
        $camps[] = [
            'camp_id' => $row['camp_id'],
            'section' => $row['gender'] === 'female' ? 'women' : 'men',
            'total'   => (int) $row['total'],
            'housed'  => (int) $row['housed'],
        ];
    }

    ok([
        'pilgrims'    => ['total' => (int) $pilgrims['total'],
                          'men'   => (int) $pilgrims['men'],
                          'women' => (int) $pilgrims['women']],
        'camps'       => $camps,
        'supervisors' => (int) $sups['total'],
        'expenses'    => ['count'    => (int) $exp['count'],
                          'total'    => (float) $exp['total'],
                          'approved' => (int) $exp['approved']],
    ]);
}
