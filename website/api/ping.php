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
        'message'  => '',
    ],
];

$configPath = __DIR__ . '/config.php';

if (!file_exists($configPath)) {
    $result['data']['message'] = 'ملف الإعدادات config.php غير موجود. انسخي config.example.php باسم config.php.';
    echo json_encode($result, JSON_UNESCAPED_UNICODE);
    exit;
}

$result['data']['config'] = true;

// نفتح الاتصال هنا مباشرة بدل db() حتى نتحكم في رسالة الخطأ
// ولا يتوقف الفحص إذا كانت قاعدة البيانات متوقفة.
try {
    $cfg = require $configPath;
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
    $result['data']['message']  = 'الخادم وقاعدة البيانات يعملان.';
} catch (Throwable $e) {
    $result['data']['message'] = 'الخادم يعمل، لكن تعذّر الاتصال بقاعدة البيانات على '
        . $result['data']['server']
        . '. تأكدي أن MySQL يعمل، وأن رقم المنفذ في config.php يطابق الرقم الظاهر في لوحة XAMPP، وأن قاعدة '
        . $result['data']['db_name'] . ' مستوردة.';
}

echo json_encode($result, JSON_UNESCAPED_UNICODE);
