<?php
/**
 * الحجاج — قراءة، تسجيل جديد، تعديل الملف، حذف
 *
 *   GET  pilgrims.php?action=list[&section=men|women][&supervisor_id=..]
 *   GET  pilgrims.php?action=get[&id=..]        (بدون id ترجع بيانات الحاج المسجّل دخوله)
 *   POST pilgrims.php?action=register           (من صفحة إنشاء حساب جديد)
 *   POST pilgrims.php?action=update             (من صفحة ملفي الشخصي)
 *   POST pilgrims.php?action=delete&id=..       (مدير الحملة فقط)
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'list');

switch ($action) {
    case 'list':     list_pilgrims();   break;
    case 'get':      get_pilgrim();     break;
    case 'register': register_pilgrim();break;
    case 'update':   update_pilgrim();  break;
    case 'delete':   delete_pilgrim();  break;
    default: fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
function list_pilgrims(): void
{
    require_user(['supervisor', 'campaign']);
    $u   = require_permission('view_pilgrims');
    $pdo = db();

    $sql = "SELECT p.pilgrim_id, p.name, p.gender, p.nationality, p.city, p.age,
                   p.phone, p.id_or_passport, p.id_type, p.id_expiry, p.nusuk_number,
                   p.booking_number, p.camp_id,
                   p.tent_number, p.bed_number, p.chronic_conditions,
                   p.package_type, p.supervisor_id,
                   s.name  AS supervisor_name,
                   j.job_title AS supervisor_job,
                   (SELECT pr.permission_name FROM permissions pr
                     WHERE pr.pilgrim_id = p.pilgrim_id LIMIT 1) AS permit_number
              FROM pilgrims p
         LEFT JOIN supervisors s ON s.supervisor_id = p.supervisor_id
         LEFT JOIN jobs j        ON j.job_id = s.job_id
             WHERE p.campaign_id = ?";
    $args = [$u['campaign_id']];

    // مشرف متخصص يرى حجاج قسمه فقط
    $section = param('section');
    if ($u['role'] === 'supervisor' && empty($u['is_general'])) {
        $section = $u['section'];
    }
    if ($section === 'men' || $section === 'women') {
        $sql .= ' AND p.gender = ?';
        $args[] = $section === 'women' ? 'female' : 'male';
    }

    if (param('supervisor_id')) {
        $sql .= ' AND p.supervisor_id = ?';
        $args[] = (int) param('supervisor_id');
    }

    $sql .= ' ORDER BY p.pilgrim_id';

    $st = $pdo->prepare($sql);
    $st->execute($args);
    $rows = $st->fetchAll();

    foreach ($rows as &$r) {
        $r['section'] = $r['gender'] === 'female' ? 'women' : 'men';
        $r['room']    = trim(($r['tent_number'] ?? '') . ($r['bed_number'] ? ' - سرير ' . $r['bed_number'] : ''));

        // تنبيه صلاحية الهوية: منتهية أو تنتهي خلال 30 يوماً
        $r['id_status'] = id_expiry_status($r['id_expiry'] ?? null);
    }
    unset($r);

    // الأمراض المزمنة لا تظهر إلا لمن وظيفته تسمح بذلك
    $rows = hide_medical_fields($rows);

    ok($rows);
}

// ------------------------------------------------------------------
function get_pilgrim(): void
{
    $u  = require_user();
    $id = param('id') ? (int) param('id') : null;

    if ($id === null) {
        if ($u['role'] !== 'pilgrim') {
            fail('حدّد رقم الحاج.', 422);
        }
        $id = $u['id'];
    }
    // الحاج لا يطّلع إلا على ملفه
    if ($u['role'] === 'pilgrim' && $id !== $u['id']) {
        fail('ليس لديك صلاحية لعرض هذا الملف.', 403);
    }

    // المشرف لا يفتح ملف حاج من حملة أخرى ولا من قسم غير قسمه
    if ($u['role'] !== 'pilgrim') {
        require_permission('view_pilgrims');
        pilgrim_in_scope($id, $u);
    }

    $st = db()->prepare(
        "SELECT p.pilgrim_id, p.campaign_id, p.supervisor_id, p.booking_number, p.name,
                p.id_or_passport, p.phone, p.nationality, p.age, p.city, p.package_type,
                p.gathering_point, p.tent_number, p.bed_number, p.gender, p.email,
                p.marital_status, p.chronic_conditions, p.camp_id,
                p.id_type, p.id_expiry, p.nusuk_number,
                s.name AS supervisor_name,
                (SELECT pr.permission_name FROM permissions pr
                  WHERE pr.pilgrim_id = p.pilgrim_id LIMIT 1) AS permit_number
           FROM pilgrims p
      LEFT JOIN supervisors s ON s.supervisor_id = p.supervisor_id
          WHERE p.pilgrim_id = ? LIMIT 1"
    );
    $st->execute([$id]);
    $row = $st->fetch();

    if (!$row) {
        fail('لا يوجد حاج بهذا الرقم.', 404);
    }
    $row['section']   = $row['gender'] === 'female' ? 'women' : 'men';
    $row['id_status']  = id_expiry_status($row['id_expiry'] ?? null);
    $row['id_type_ar'] = id_type_label($row['id_type'] ?? null);

    // الحاج يرى حالته الصحية في ملفه، والمشرف حسب صلاحية وظيفته
    if ($u['role'] !== 'pilgrim') {
        $row = hide_medical_fields([$row])[0];
    }

    ok($row);
}

// ------------------------------------------------------------------
function register_pilgrim(): void
{
    require_post();
    $pdo = db();

    $name        = require_text('name', 100);
    $password    = require_text('password', 100);
    $nationalId  = require_text('nationalId', 50);
    $phone       = require_text('phone', 20);
    $gender      = one_of('gender', ['male', 'female'], 'male');
    $idType      = one_of('idType', ['national_id', 'iqama', 'passport'], 'national_id');
    $nusuk       = (string) (param('nusukNumber') ?? '');
    $idExpiry    = opt_date('idExpiry');

    // صلاحية الهوية: الرقم يطابق نوعه، والتاريخ لم ينتهِ
    validate_identity($idType, $nationalId);

    if ($nusuk === '') {
        fail('رقم النسك مطلوب، وهو رقم تصريح الحج الصادر من منصة نسك.', 422);
    }
    if (!preg_match('/^[A-Za-z0-9\-]{5,30}$/', $nusuk)) {
        fail('رقم النسك يجب أن يكون من 5 إلى 30 حرفاً أو رقماً (يسمح بالشرطة -).', 422);
    }
    if ($idExpiry !== null && $idExpiry < date('Y-m-d')) {
        fail('الهوية منتهية الصلاحية، لا يمكن إكمال التسجيل بها.', 422);
    }

    if (mb_strlen($password) < 6) {
        fail('كلمة المرور يجب ألا تقل عن 6 خانات.', 422);
    }

    $email = opt_text('email', 150);
    if ($email !== null && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        fail('صيغة البريد الإلكتروني غير صحيحة.', 422);
    }

    $age = param('age');
    if ($age !== null && $age !== '' && (!ctype_digit((string) $age) || (int) $age < 1 || (int) $age > 120)) {
        fail('العمر غير منطقي.', 422);
    }
    $age = ($age === null || $age === '') ? null : (int) $age;

    $campaignId = param('campaignId') ?: app_config('default_campaign_id');
    $st = $pdo->prepare('SELECT 1 FROM campaigns WHERE campaign_id = ?');
    $st->execute([(int) $campaignId]);
    if (!$st->fetch()) {
        fail('رقم الحملة غير موجود في قاعدة البيانات.', 422);
    }

    // المشرف اختياري — يُقبل فقط إذا كان موجوداً فعلاً
    $supervisorId = param('supervisorId');
    if ($supervisorId !== null && $supervisorId !== '') {
        $st = $pdo->prepare('SELECT 1 FROM supervisors WHERE supervisor_id = ?');
        $st->execute([(int) $supervisorId]);
        $supervisorId = $st->fetch() ? (int) $supervisorId : null;
    } else {
        $supervisorId = null;
    }

    $st = $pdo->prepare('SELECT 1 FROM pilgrims WHERE id_or_passport = ?');
    $st->execute([$nationalId]);
    if ($st->fetch()) {
        fail('رقم الهوية/الجواز مسجّل من قبل.', 409);
    }

    $st = $pdo->prepare('SELECT 1 FROM pilgrims WHERE nusuk_number = ?');
    $st->execute([$nusuk]);
    if ($st->fetch()) {
        fail('رقم النسك مسجّل من قبل لحاج آخر.', 409);
    }

    $st = $pdo->prepare(
        'INSERT INTO pilgrims
            (campaign_id, supervisor_id, booking_number, name, id_or_passport, phone,
             nationality, age, city, password_hash, gender, email, marital_status,
             chronic_conditions, id_type, id_expiry, nusuk_number)
         VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)'
    );
    $st->execute([
        (int) $campaignId,
        $supervisorId,
        'BK-' . date('Y') . '-' . bin2hex(random_bytes(3)),
        $name,
        $nationalId,
        $phone,
        opt_text('nationality', 50),
        $age,
        opt_text('city', 80),
        password_hash($password, PASSWORD_DEFAULT),
        $gender,
        $email,
        opt_text('marital', 50),
        opt_text('chronic', 1000),
        $idType,
        $idExpiry,
        $nusuk,
    ]);

    $newId = (int) $pdo->lastInsertId();

    ok([
        'pilgrim_id' => $newId,
        'name'       => $name,
        'message'    => 'تم إنشاء الحساب. رقم عضويتك هو ' . $newId,
    ]);
}

// ------------------------------------------------------------------
function update_pilgrim(): void
{
    require_post();
    $u = require_user();

    $id = param('id') ? (int) param('id') : ($u['role'] === 'pilgrim' ? $u['id'] : null);
    if ($id === null) {
        fail('حدّد رقم الحاج.', 422);
    }
    if ($u['role'] === 'pilgrim' && $id !== $u['id']) {
        fail('ليس لديك صلاحية لتعديل هذا الملف.', 403);
    }

    // المشرف يعدّل بيانات حجاج قسمه فقط، وبشرط أن وظيفته تسمح بالتعديل
    if ($u['role'] !== 'pilgrim') {
        require_permission('edit_pilgrims');
        pilgrim_in_scope($id, $u);
    }

    // الحالة الصحية يعدّلها الحاج في ملفه، أو من وظيفته متابعة الحالات الطبية
    $chronic = opt_text('chronic', 1000);
    if ($chronic !== null && $u['role'] !== 'pilgrim' && !can('manage_medical')) {
        fail('تعديل الحالة الصحية من مهام الموظف الصحي.', 403);
    }

    $email = opt_text('email', 150);
    if ($email !== null && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        fail('صيغة البريد الإلكتروني غير صحيحة.', 422);
    }

    $age = param('age');
    $age = ($age === null || $age === '') ? null : (int) $age;

    $st = db()->prepare(
        'UPDATE pilgrims
            SET name = COALESCE(?, name),
                phone = COALESCE(?, phone),
                nationality = COALESCE(?, nationality),
                age = COALESCE(?, age),
                city = COALESCE(?, city),
                email = COALESCE(?, email),
                marital_status = COALESCE(?, marital_status),
                chronic_conditions = COALESCE(?, chronic_conditions)
          WHERE pilgrim_id = ?'
    );
    $st->execute([
        opt_text('name', 100),
        opt_text('phone', 20),
        opt_text('nationality', 50),
        $age,
        opt_text('city', 80),
        $email,
        opt_text('marital', 50),
        $chronic,
        $id,
    ]);

    ok(['updated' => $st->rowCount()]);
}

// ------------------------------------------------------------------
function delete_pilgrim(): void
{
    require_post();
    require_user(['campaign']);
    $id = require_int('id');

    $st = db()->prepare('DELETE FROM pilgrims WHERE pilgrim_id = ?');
    $st->execute([$id]);

    if ($st->rowCount() === 0) {
        fail('لا يوجد حاج بهذا الرقم.', 404);
    }
    ok(['deleted' => $id]);
}
