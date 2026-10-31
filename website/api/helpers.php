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
