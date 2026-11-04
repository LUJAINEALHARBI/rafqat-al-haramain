<?php
/**
 * بيانات الصفحة الرئيسية (بدون تسجيل دخول)
 *
 *   GET public.php?action=home
 *
 * يرجع بيانات الحملة المعلنة وخدماتها وباقاتها وأرقامها، كلها من
 * قاعدة البيانات. لا يرجع هذا الملف أي بيانات شخصية لحاج أو مشرف،
 * لأنه مفتوح لزوار الموقع قبل تسجيل الدخول.
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'home');

switch ($action) {
    case 'home': home_data(); break;
    default: fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
function home_data(): void
{
    $pdo        = db();
    $campaignId = (int) app_config('default_campaign_id');

    $st = $pdo->prepare(
        'SELECT campaign_id, campaign_name, company_name, phone, location,
                price_per_person, start_city, start_date, extra_info
           FROM campaigns WHERE campaign_id = ? LIMIT 1'
    );
    $st->execute([$campaignId]);
    $campaign = $st->fetch() ?: null;

    // الخدمات المتاحة فقط، وبدون بنود التقييم العامة لأنها ليست
    // خدمة تُعلن للزوار بل محور تقييم داخل النظام
    $st = $pdo->prepare(
        "SELECT service_id, service_name, description, service_type, service_location
           FROM services
          WHERE status = 'متاحة'
            AND (service_type IS NULL OR service_type <> 'general')
       ORDER BY service_id"
    );
    $st->execute();
    $services = $st->fetchAll();

    $st = $pdo->prepare(
        'SELECT package_id, package_name, package_tag, price, features, is_featured
           FROM packages WHERE campaign_id = ? ORDER BY sort_order, package_id'
    );
    $st->execute([$campaignId]);
    $packages = $st->fetchAll();

    foreach ($packages as &$p) {
        $p['package_id']  = (int) $p['package_id'];
        $p['is_featured'] = (bool) $p['is_featured'];
        $p['price']       = (float) $p['price'];
        $p['features']    = array_values(array_filter(array_map(
            'trim',
            preg_split('/\r\n|\r|\n/', (string) $p['features'])
        )));
    }
    unset($p);

    // أرقام معلنة عن الحملة — بلا أي بيانات شخصية
    $stations = $pdo->prepare(
        'SELECT COUNT(*) FROM journey_stations s
           JOIN journey_programs p ON p.program_id = s.program_id
          WHERE p.campaign_id = ? AND p.is_active = 1'
    );
    $stations->execute([$campaignId]);

    $sites = $pdo->prepare('SELECT COUNT(*) FROM site_locations WHERE campaign_id = ?');
    $sites->execute([$campaignId]);

    $jobs = $pdo->query('SELECT COUNT(*) FROM jobs');

    ok([
        'campaign' => $campaign,
        'services' => $services,
        'packages' => $packages,
        'stats'    => [
            'services'  => count($services),
            'packages'  => count($packages),
            'stations'  => (int) $stations->fetchColumn(),
            'sites'     => (int) $sites->fetchColumn(),
            'job_types' => (int) $jobs->fetchColumn(),
        ],
    ]);
}
