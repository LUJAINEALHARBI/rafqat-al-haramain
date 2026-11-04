<?php
/**
 * دوال مساعدة مشتركة لكل ملفات الـ API
 * - إخراج JSON موحّد
 * - قراءة المدخلات والتحقق منها
 * - الجلسة (تسجيل الدخول) والتحقق من الصلاحية
 */

require_once __DIR__ . '/db.php';

// ---------------------------------------------------------------
// الجلسة
// ---------------------------------------------------------------
function start_app_session(): void
{
    if (session_status() === PHP_SESSION_NONE) {
        session_set_cookie_params([
            'httponly' => true,
            'samesite' => 'Lax',
        ]);
        session_start();
    }
}

// ---------------------------------------------------------------
// الإخراج
// ---------------------------------------------------------------
function json_out($data, int $status = 200): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

function ok($data = [], array $extra = []): void
{
    json_out(array_merge(['ok' => true, 'data' => $data], $extra));
}

function fail(string $message, int $status = 400, $details = null): void
{
    json_out([
        'ok'      => false,
        'error'   => $message,
        'details' => app_config('debug') ? $details : null,
    ], $status);
}

// ---------------------------------------------------------------
// المدخلات
// ---------------------------------------------------------------

/** يقرأ جسم الطلب سواء كان JSON أو نموذج عادي */
function input(): array
{
    static $data = null;
    if ($data !== null) {
        return $data;
    }

    $raw  = file_get_contents('php://input');
    $type = $_SERVER['CONTENT_TYPE'] ?? '';

    if ($raw !== '' && stripos($type, 'application/json') !== false) {
        $decoded = json_decode($raw, true);
        $data = is_array($decoded) ? $decoded : [];
    } else {
        $data = array_merge($_GET, $_POST);
    }
    return $data;
}

function param(string $key, $default = null)
{
    $all = input();
    $val = $all[$key] ?? $_GET[$key] ?? $default;
    return is_string($val) ? trim($val) : $val;
}

/** حقل نصي مطلوب مع حد أقصى للطول */
function require_text(string $key, int $max = 255): string
{
    $v = param($key);
    if ($v === null || $v === '') {
        fail("الحقل \"$key\" مطلوب.", 422);
    }
    $v = (string) $v;
    if (mb_strlen($v) > $max) {
        fail("الحقل \"$key\" أطول من المسموح ($max حرفاً).", 422);
    }
    return $v;
}

function require_int(string $key): int
{
    $v = param($key);
    if ($v === null || $v === '' || !is_numeric($v)) {
        fail("الحقل \"$key\" يجب أن يكون رقماً.", 422);
    }
    return (int) $v;
}

function opt_text(string $key, int $max = 255, ?string $default = null): ?string
{
    $v = param($key);
    if ($v === null || $v === '') {
        return $default;
    }
    return mb_substr((string) $v, 0, $max);
}

/** يتأكد أن القيمة ضمن قائمة مسموحة */
function one_of(string $key, array $allowed, ?string $default = null): ?string
{
    $v = param($key, $default);
    if ($v === null || $v === '') {
        return $default;
    }
    if (!in_array($v, $allowed, true)) {
        fail("قيمة \"$key\" غير مسموحة.", 422);
    }
    return (string) $v;
}

function method(): string
{
    return strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
}

function require_post(): void
{
    if (method() !== 'POST') {
        fail('هذه العملية تحتاج طلب POST.', 405);
    }
}

// ---------------------------------------------------------------
// المستخدم الحالي والصلاحيات
// ---------------------------------------------------------------

/** يرجع بيانات المستخدم من الجلسة أو null */
function current_user(): ?array
{
    start_app_session();
    return $_SESSION['user'] ?? null;
}

/** يمنع الوصول إذا لم يسجّل دخول، ويقيّد الأدوار المسموحة */
function require_user(array $roles = []): array
{
    $u = current_user();
    if (!$u) {
        fail('يجب تسجيل الدخول أولاً.', 401);
    }
    if ($roles && !in_array($u['role'], $roles, true)) {
        fail('ليس لديك صلاحية لهذه العملية.', 403);
    }
    return $u;
}

// ---------------------------------------------------------------
// رفع الملفات (فاتورة المصروف)
// ---------------------------------------------------------------

/**
 * يحفظ الملف المرفوع في مجلد uploads باسم آمن مولّد.
 * يرجع اسم الملف المحفوظ أو null إذا لم يُرفع شيء.
 */
function save_upload(string $field): ?string
{
    if (empty($_FILES[$field]) || $_FILES[$field]['error'] === UPLOAD_ERR_NO_FILE) {
        return null;
    }

    $file = $_FILES[$field];

    if ($file['error'] !== UPLOAD_ERR_OK) {
        fail('فشل رفع الملف.', 422);
    }
    if ($file['size'] > 2 * 1024 * 1024) {
        fail('حجم الملف يتجاوز 2 ميجابايت.', 422);
    }

    $allowed = ['jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg',
                'png' => 'image/png',  'pdf'  => 'application/pdf'];

    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    if (!isset($allowed[$ext])) {
        fail('نوع الملف غير مسموح. المسموح: jpg, png, pdf.', 422);
    }

    // التحقق من المحتوى الفعلي وليس الامتداد فقط
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mime  = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);
    if ($mime !== $allowed[$ext]) {
        fail('محتوى الملف لا يطابق امتداده.', 422);
    }

    $dir = __DIR__ . '/../uploads';
    if (!is_dir($dir)) {
        mkdir($dir, 0775, true);
    }

    $name = 'receipt_' . date('Ymd_His') . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
    if (!move_uploaded_file($file['tmp_name'], $dir . '/' . $name)) {
        fail('تعذّر حفظ الملف على الخادم.', 500);
    }

    return $name;
}

// ---------------------------------------------------------------
// الصلاحيات — تُقرأ من جدولي app_permissions و job_permissions
// ---------------------------------------------------------------

/**
 * صلاحيات المستخدم الحالي كقائمة مفاتيح.
 *   مدير الحملة  → كل الصلاحيات الموجودة في النظام
 *   المشرف       → صلاحيات وظيفته المسجّلة في job_permissions
 *   الحاج        → لا صلاحيات إدارية (له صفحاته الخاصة فقط)
 * الوظيفة تُقرأ من جدول المشرفين وقت الطلب، فأي تعديل يجريه مدير
 * الحملة على وظيفة مشرف يسري عليه مباشرة بدون إعادة تسجيل دخول.
 */
function user_permissions(): array
{
    static $cache = null;
    if ($cache !== null) {
        return $cache;
    }

    $u = current_user();
    if (!$u) {
        return $cache = [];
    }

    if ($u['role'] === 'campaign') {
        $st = db()->query('SELECT permission_key FROM app_permissions');
        return $cache = $st->fetchAll(PDO::FETCH_COLUMN);
    }

    if ($u['role'] === 'supervisor') {
        $st = db()->prepare(
            'SELECT jp.permission_key
               FROM supervisors s
               JOIN job_permissions jp ON jp.job_id = s.job_id
              WHERE s.supervisor_id = ?'
        );
        $st->execute([$u['id']]);
        return $cache = $st->fetchAll(PDO::FETCH_COLUMN);
    }

    return $cache = [];
}

/** هل يملك المستخدم الحالي هذه الصلاحية؟ */
function can(string $permission): bool
{
    return in_array($permission, user_permissions(), true);
}

/** يمنع العملية إذا لم تكن الصلاحية ضمن صلاحيات وظيفة المستخدم */
function require_permission(string $permission): array
{
    $u = require_user();
    if (!can($permission)) {
        $st = db()->prepare('SELECT permission_label FROM app_permissions WHERE permission_key = ?');
        $st->execute([$permission]);
        $label = $st->fetchColumn() ?: $permission;
        fail('صلاحية "' . $label . '" غير متاحة لوظيفتك.', 403);
    }
    return $u;
}

/**
 * يحذف الحقول الطبية من النتائج إذا لم تكن صلاحية view_medical متاحة.
 * الحاج يرى بياناته الصحية دائماً، أما المشرف فلا يراها إلا إذا كانت
 * ضمن صلاحيات وظيفته (الموظف الصحي والمشرف العام ومدير الحملة).
 */
function hide_medical_fields(array $rows, array $fields = ['chronic_conditions']): array
{
    if (can('view_medical')) {
        return $rows;
    }
    return array_map(function (array $r) use ($fields) {
        foreach ($fields as $f) {
            unset($r[$f]);
        }
        return $r;
    }, $rows);
}

/**
 * نطاق المستخدم: يمنع المشرف من الوصول لحاج خارج حملته،
 * والمشرف المتخصص من الوصول لحاج خارج قسمه.
 * يرجع صف الحاج أو يوقف الطلب برسالة واضحة.
 */
function pilgrim_in_scope(int $pilgrimId, array $u): array
{
    $st = db()->prepare(
        'SELECT pilgrim_id, campaign_id, gender, supervisor_id FROM pilgrims WHERE pilgrim_id = ? LIMIT 1'
    );
    $st->execute([$pilgrimId]);
    $row = $st->fetch();

    if (!$row) {
        fail('لا يوجد حاج بهذا الرقم.', 404);
    }
    if ((int) $row['campaign_id'] !== (int) $u['campaign_id']) {
        fail('هذا الحاج ليس من حجاج حملتك.', 403);
    }
    if ($u['role'] === 'supervisor') {
        $viewing = viewing_section($u);
        $section = $row['gender'] === 'female' ? 'women' : 'men';
        if ($viewing !== null && $section !== $viewing) {
            fail('هذا الحاج ليس من القسم الذي تتابعه حالياً.', 403);
        }
    }
    return $row;
}

// ---------------------------------------------------------------
// الهوية ورقم النسك
// ---------------------------------------------------------------

/** الاسم العربي لنوع الهوية */
function id_type_label(?string $type): string
{
    switch ($type) {
        case 'iqama':    return 'رقم الإقامة';
        case 'passport': return 'جواز السفر';
        default:         return 'الهوية الوطنية';
    }
}

/**
 * التحقق من رقم الهوية حسب نوعه:
 *   الهوية الوطنية → 10 أرقام تبدأ بـ 1
 *   الإقامة        → 10 أرقام تبدأ بـ 2
 *   جواز السفر     → 6 إلى 15 حرفاً أو رقماً
 * يوقف الطلب برسالة واضحة إذا كان الرقم لا يطابق نوعه.
 */
function validate_identity(string $type, string $number): void
{
    if ($type === 'national_id' && !preg_match('/^1\d{9}$/', $number)) {
        fail('رقم الهوية الوطنية يجب أن يكون 10 أرقام ويبدأ بالرقم 1.', 422);
    }
    if ($type === 'iqama' && !preg_match('/^2\d{9}$/', $number)) {
        fail('رقم الإقامة يجب أن يكون 10 أرقام ويبدأ بالرقم 2.', 422);
    }
    if ($type === 'passport' && !preg_match('/^[A-Za-z0-9]{6,15}$/', $number)) {
        fail('رقم جواز السفر يجب أن يكون من 6 إلى 15 حرفاً أو رقماً بدون مسافات.', 422);
    }
}

/**
 * حالة صلاحية الهوية مقارنة بتاريخ اليوم:
 *   expired  منتهية   |  soon  تنتهي خلال 30 يوماً  |  valid  سارية
 * تُرسل مع بيانات الحاج ليظهر التنبيه للمشرف في القائمة.
 */
function id_expiry_status(?string $expiry): array
{
    if (!$expiry) {
        return ['state' => 'unknown', 'label' => 'تاريخ الانتهاء غير مسجّل', 'days' => null];
    }

    $today = new DateTime('today');
    $date  = DateTime::createFromFormat('Y-m-d', substr($expiry, 0, 10));
    if (!$date) {
        return ['state' => 'unknown', 'label' => 'تاريخ الانتهاء غير مسجّل', 'days' => null];
    }

    $days = (int) $today->diff($date)->format('%r%a');

    if ($days < 0) {
        return ['state' => 'expired', 'label' => 'الهوية منتهية الصلاحية', 'days' => $days];
    }
    if ($days <= 30) {
        return ['state' => 'soon', 'label' => 'تنتهي صلاحية الهوية بعد ' . $days . ' يوماً', 'days' => $days];
    }
    return ['state' => 'valid', 'label' => 'الهوية سارية', 'days' => $days];
}

/** تاريخ ميلادي بصيغة Y-m-d أو null */
function opt_date(string $key): ?string
{
    $v = param($key);
    if ($v === null || $v === '') {
        return null;
    }
    $d = DateTime::createFromFormat('Y-m-d', substr((string) $v, 0, 10));
    if (!$d || $d->format('Y-m-d') !== substr((string) $v, 0, 10)) {
        fail("التاريخ في الحقل \"$key\" غير صحيح. الصيغة المطلوبة سنة-شهر-يوم.", 422);
    }
    return $d->format('Y-m-d');
}

/**
 * الصلاحية المطلوبة لمتابعة طلبات نوع خدمة معيّن.
 * الطلب الطبي لا يتابعه إلا من وظيفته صحية، وطلب الإعاشة لا يتابعه
 * موظف السكن، وهكذا. مدير الحملة والمشرف العام يملكان الصلاحيات كلها.
 */
function service_type_permission(?string $serviceType): string
{
    switch ($serviceType) {
        case 'medical':  return 'manage_medical';
        case 'crowd':    return 'manage_transport';
        case 'catering': return 'manage_catering';
        case 'housing':  return 'manage_housing';
        default:         return 'manage_services';
    }
}

/**
 * القسم الذي يتابعه المستخدم في هذه الجلسة.
 *   المشرف المتخصص : قسمه المسجّل في جدول المشرفين، ولا يغيّره.
 *   المشرف العام    : القسم الذي اختاره عند الدخول ويستطيع تبديله من لوحته.
 *   الحاج           : قسمه حسب جنسه.
 *   مدير الحملة     : القسمان معاً ما لم يحدّد قسماً في الطلب.
 *
 * سبب وجودها: المشرف العام كان يختار "قسم الرجال" ثم تظهر له أسماء
 * القسمين معاً، فصار ما يظهر على الشاشة لا يطابق ما هو مكتوب فوقها.
 */
function viewing_section(array $u): ?string
{
    if (($u['role'] ?? '') === 'campaign') {
        return one_of('section', ['men', 'women'], null);
    }

    $section = $u['section'] ?? null;
    return ($section === 'men' || $section === 'women') ? $section : null;
}

/** يحوّل القسم إلى قيمة عمود gender في جدول الحجاج */
function section_gender(?string $section): ?string
{
    if ($section === 'women') return 'female';
    if ($section === 'men')   return 'male';
    return null;
}
