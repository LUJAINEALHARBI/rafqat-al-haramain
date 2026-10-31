<?php
/**
 * الاتصال بقاعدة البيانات عبر PDO
 * -------------------------------------------------
 * ملف واحد فقط يعرف بيانات الاتصال، وكل ملفات الـ API تستدعيه.
 * - ERRMODE_EXCEPTION حتى لا يمر خطأ بصمت.
 * - emulate_prepares = false حتى تكون الاستعلامات المجهّزة حقيقية
 *   على مستوى الخادم (حماية فعلية من SQL Injection).
 */

function db(): PDO
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $cfg = require __DIR__ . '/config.php';

    $dsn = sprintf(
        'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
        $cfg['db_host'],
        $cfg['db_port'],
        $cfg['db_name']
    );

    try {
        $pdo = new PDO($dsn, $cfg['db_user'], $cfg['db_pass'], [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'ok'      => false,
            'error'   => 'تعذّر الاتصال بقاعدة البيانات. تأكد أن MySQL يعمل وأن قاعدة البيانات مستوردة.',
            'details' => !empty($cfg['debug']) ? $e->getMessage() : null,
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    return $pdo;
}

function app_config(string $key, $default = null)
{
    static $cfg = null;
    if ($cfg === null) {
        $cfg = require __DIR__ . '/config.php';
    }
    return $cfg[$key] ?? $default;
}
