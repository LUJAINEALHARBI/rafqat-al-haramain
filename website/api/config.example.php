<?php
/**
 * نموذج ملف الإعدادات — بدون كلمات مرور حقيقية
 * -------------------------------------------------
 * انسخي هذا الملف باسم  config.php  وعدّلي القيم.
 *
 *   cp api/config.example.php api/config.php
 *
 * على XAMPP المحلي القيم الافتراضية تكفي:
 *   المستخدم root وكلمة المرور فارغة.
 *
 * على استضافة حقيقية لا تتركي root ولا كلمة مرور فارغة،
 * واستخدمي متغيرات البيئة بدل كتابة كلمة المرور داخل الملف.
 */

return [
    'db_host' => getenv('DB_HOST') ?: '127.0.0.1',
    'db_port' => getenv('DB_PORT') ?: '3306',
    'db_name' => getenv('DB_NAME') ?: 'rafqa_haramain',
    'db_user' => getenv('DB_USER') ?: 'CHANGE_ME',
    'db_pass' => getenv('DB_PASS') !== false ? getenv('DB_PASS') : 'CHANGE_ME',

    // اجعليه false على الاستضافة حتى لا تظهر تفاصيل الأخطاء للزوار
    'debug'   => false,

    // رقم الحملة الافتراضي المستخدم عند تسجيل حاج جديد
    'default_campaign_id' => 30089,
];
