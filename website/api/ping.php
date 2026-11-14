<?php
/**
 * فحص سريع للاتصال — يستخدمه التطبيق ليعرف هل عنوان الخادم صحيح.
 * -------------------------------------------------
 * لا يحتاج تسجيل دخول، ولا يكشف أي بيانات.
 * يرد دائماً بـ JSON حتى لو كانت قاعدة البيانات متوقفة،
 * حتى يستطيع التطبيق التفريق بين:
 *   - الخادم غير موجود أصلاً (لا رد)
 *   - الخادم يعمل لكن قاعدة البيانات متوقفة (رد فيه database=false)
 */

// نمنع طباعة تنبيهات PHP كـ HTML، لأنها تفسد ردّ JSON
// وتجعل التطبيق يرى صفحة بدل البيانات.
@ini_set('display_errors', '0');
error_reporting(0);

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

$result = [
    'ok'   => true,
    'data' => [
        'app'      => 'rafqa-haramain',
        'php'      => PHP_VERSION,
        'config'   => false,
        'database' => false,
        'server'   => '',
        'db_name'  => '',
        'session'  => '',
        'message'  => '',
    ],
];

// فحص الجلسات: إن لم يكن مجلد الجلسات قابلاً للكتابة فسيُسجّل المستخدم
// الدخول بنجاح ثم تقول له الصفحة التالية «يجب تسجيل الدخول أولاً».
$sessPath = ini_get('session.save_path');
if ($sessPath === '' || $sessPath === false) {
    $sessPath = sys_get_temp_dir();
}
$sessPath = preg_replace('/^\d+;/', '', $sessPath);
if (!is_dir($sessPath)) {
    $result['data']['session'] = 'مجلد الجلسات غير موجود: ' . $sessPath;
} elseif (!is_writable($sessPath)) {
    $result['data']['session'] = 'مجلد الجلسات غير قابل للكتابة: ' . $sessPath;
} else {
    $result['data']['session'] = 'سليم';
}

$configPath = __DIR__ . '/config.php';

if (!file_exists($configPath)) {
    $result['data']['message'] = 'ملف الإعدادات config.php غير موجود. انسخي config.example.php باسم config.php.';
    echo json_encode($result, JSON_UNESCAPED_UNICODE);
    exit;
}

$result['data']['config'] = true;

// نتأكد أن الملف يُرجع مصفوفة فيها المفاتيح المطلوبة،
// لأن أكثر خطأ شائع هو نسخ الملف وتعديله بطريقة تكسر بنيته.
$cfg = @include $configPath;

if (!is_array($cfg)) {
    $result['data']['message'] = 'ملف config.php موجود لكنه لا يُرجع إعدادات صحيحة. '
        . 'لازم يبدأ بـ <?php ثم return [ ... ]; — انسخي config.example.php من جديد وعدّلي القيم فقط.';
    echo json_encode($result, JSON_UNESCAPED_UNICODE);
    exit;
}

$missing = [];
foreach (['db_host', 'db_port', 'db_name', 'db_user'] as $key) {
    if (!isset($cfg[$key]) || $cfg[$key] === '' || $cfg[$key] === 'CHANGE_ME') {
        $missing[] = $key;
    }
}
if ($missing) {
    $result['data']['message'] = 'ملف config.php ناقص أو غير معبّأ: ' . implode('، ', $missing)
        . '. افتحيه وعبّي هذه القيم.';
    echo json_encode($result, JSON_UNESCAPED_UNICODE);
    exit;
}

// نفتح الاتصال هنا مباشرة بدل db() حتى نتحكم في رسالة الخطأ
// ولا يتوقف الفحص إذا كانت قاعدة البيانات متوقفة.
try {
    // نعرض المضيف والمنفذ واسم القاعدة فقط — بلا مستخدم ولا كلمة مرور
    $result['data']['server']  = $cfg['db_host'] . ':' . $cfg['db_port'];
    $result['data']['db_name'] = $cfg['db_name'];
    $dsn = sprintf(
        'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
        $cfg['db_host'],
        $cfg['db_port'],
        $cfg['db_name']
    );
    $pdo = new PDO($dsn, $cfg['db_user'], $cfg['db_pass'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);
    $pdo->query('SELECT 1');
    $result['data']['database'] = true;
    $result['data']['message'] = $result['data']['session'] === 'سليم'
        ? 'الخادم وقاعدة البيانات والجلسات كلها تعمل.'
        : 'الخادم وقاعدة البيانات يعملان، لكن هناك مشكلة في الجلسات: '
          . $result['data']['session']
          . ' — وهذا يجعل تسجيل الدخول ينجح ثم تظهر رسالة «يجب تسجيل الدخول أولاً». '
          . 'أنشئي المجلد أو اضبطي session.save_path في php.ini.';
} catch (Throwable $e) {
    $result['data']['message'] = 'الخادم يعمل، لكن تعذّر الاتصال بقاعدة البيانات على '
        . $result['data']['server']
        . '. تأكدي أن MySQL يعمل، وأن رقم المنفذ في config.php يطابق الرقم الظاهر في لوحة XAMPP، وأن قاعدة '
        . $result['data']['db_name'] . ' مستوردة.';
}

echo json_encode($result, JSON_UNESCAPED_UNICODE);
