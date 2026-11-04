<?php
/**
 * تسجيل الدخول والخروج ومعرفة المستخدم الحالي
 *
 *   GET|POST  auth.php?action=login    (id, password, section)
 *   POST      auth.php?action=logout
 *   GET       auth.php?action=me
 *
 * قاعدة التوجيه محفوظة كما كانت في الواجهة:
 *   100xxx → حاج      |  500xxx / 5000 → مشرف  |  300xxx → مدير حملة
 * الفرق أن كلمة المرور صارت تُتحقّق فعلياً من قاعدة البيانات.
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'me');

switch ($action) {
    case 'login':
        do_login();
        break;
    case 'logout':
        do_logout();
        break;
    case 'me':
        do_me();
        break;
    case 'reset_password':
        do_reset_password();
        break;
    case 'set_section':
        do_set_section();
        break;
    default:
        fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
/**
 * تبديل القسم الذي يتابعه المشرف العام أثناء الجلسة.
 * المشرف المتخصص قسمه ثابت من قاعدة البيانات ولا يبدّله.
 */
function do_set_section(): void
{
    require_post();
    $u = require_user(['supervisor']);

    if (empty($u['is_general'])) {
        fail('قسمك محدد في بياناتك ولا يمكن تغييره.', 403);
    }

    $section = one_of('section', ['men', 'women'], null);
    if ($section === null) {
        fail('حدد القسم: men أو women.', 422);
    }

    start_app_session();
    $_SESSION['user']['section'] = $section;

    ok(['section' => $section]);
}

// ------------------------------------------------------------------
/**
 * إعادة تعيين كلمة مرور حساب — مدير الحملة فقط.
 * لا توجد خدمة رسائل على الاستضافة، فاستعادة كلمة المرور تتم عبر
 * مدير الحملة بدل رمز تحقق وهمي يسمح لأي شخص بالاستيلاء على حساب.
 */
function do_reset_password(): void
{
    require_post();
    $u = require_user(['campaign']);

    $targetId = require_text('target_id', 20);
    $newPass  = require_text('new_password', 100);

    if (!preg_match('/^\d{3,12}$/', $targetId)) {
        fail('رقم العضوية يجب أن يكون أرقاماً فقط.', 422);
    }

    // نفس شروط كلمة المرور المعروضة في الواجهة
    if (strlen($newPass) < 8
        || !preg_match('/[A-Z]/', $newPass)
        || !preg_match('/[a-z]/', $newPass)
        || !preg_match('/\d/', $newPass)
        || !preg_match('/[!@#$%^&*(),.?":{}|<>]/', $newPass)) {
        fail('كلمة المرور يجب أن تكون 8 خانات فأكثر وتحتوي أحرفاً كبيرة وصغيرة وأرقاماً ورمزاً خاصاً.', 422);
    }

    $hash = password_hash($newPass, PASSWORD_DEFAULT);

    if (str_starts_with($targetId, '100')) {
        $st = db()->prepare(
            'UPDATE pilgrims SET password_hash = ? WHERE pilgrim_id = ? AND campaign_id = ?'
        );
        $st->execute([$hash, $targetId, $u['campaign_id']]);
        $label = 'حاج';
    } elseif (str_starts_with($targetId, '500')) {
        $st = db()->prepare(
            'UPDATE supervisors SET password_hash = ? WHERE supervisor_id = ? AND campaign_id = ?'
        );
        $st->execute([$hash, $targetId, $u['campaign_id']]);
        $label = 'مشرف';
    } elseif (str_starts_with($targetId, '300')) {
        // المدير يغيّر كلمة مرور حملته هو فقط
        if ((int) $targetId !== (int) $u['campaign_id']) {
            fail('لا يمكنك تغيير كلمة مرور حملة أخرى.', 403);
        }
        $st = db()->prepare('UPDATE campaigns SET password_hash = ? WHERE campaign_id = ?');
        $st->execute([$hash, $targetId]);
        $label = 'مدير الحملة';
    } else {
        fail('رقم العضوية غير معروف. يبدأ بـ 100 للحجاج، 500 للمشرفين، 300 لمدير الحملة.', 422);
    }

    if ($st->rowCount() === 0) {
        fail('لا يوجد حساب بهذا الرقم ضمن حملتك.', 404);
    }

    ok(['target_id' => $targetId, 'role' => $label]);
}

// ------------------------------------------------------------------
function do_login(): void
{
    require_post();

    $loginId  = require_text('id', 20);
    $password = require_text('password', 100);
    $section  = one_of('section', ['men', 'women'], null);

    if (!preg_match('/^\d{3,12}$/', $loginId)) {
        fail('رقم العضوية يجب أن يكون أرقاماً فقط.', 422);
    }

    $pdo = db();

    // --- حاج ---------------------------------------------------
    if (str_starts_with($loginId, '100')) {
        $st = $pdo->prepare(
            'SELECT pilgrim_id, campaign_id, supervisor_id, name, gender, password_hash
               FROM pilgrims WHERE pilgrim_id = ? LIMIT 1'
        );
        $st->execute([$loginId]);
        $row = $st->fetch();

        if (!$row || !$row['password_hash'] || !password_verify($password, $row['password_hash'])) {
            fail('رقم العضوية أو كلمة المرور غير صحيحة.', 401);
        }

        set_session_user([
            'role'        => 'pilgrim',
            'id'          => (int) $row['pilgrim_id'],
            'name'        => $row['name'],
            'campaign_id' => (int) $row['campaign_id'],
            // القسم يُؤخذ من جنس الحاج في قاعدة البيانات، لا من الاختيار في الشاشة
            'section'     => $row['gender'] === 'female' ? 'women' : 'men',
            'job_role'    => null,
            'job_title'   => null,
            'redirect'    => 'index.html',
        ]);
    }

    // --- مشرف --------------------------------------------------
    if (str_starts_with($loginId, '500')) {
        $st = $pdo->prepare(
            'SELECT s.supervisor_id, s.campaign_id, s.name, s.gender_section,
                    s.password_hash, j.role_key, j.job_title, j.permission_level
               FROM supervisors s
          LEFT JOIN jobs j ON j.job_id = s.job_id
              WHERE s.supervisor_id = ? LIMIT 1'
        );
        $st->execute([$loginId]);
        $row = $st->fetch();

        if (!$row || !password_verify($password, $row['password_hash'])) {
            fail('رقم العضوية أو كلمة المرور غير صحيحة.', 401);
        }

        // مشرف قسم محدد: القسم من قاعدة البيانات.
        // المشرف العام (gender_section = all): يتابع القسم الذي اختاره في الشاشة.
        $resolved = $row['gender_section'] === 'all'
            ? ($section ?: 'men')
            : $row['gender_section'];

        set_session_user([
            'role'             => 'supervisor',
            'id'               => (int) $row['supervisor_id'],
            'name'             => $row['name'],
            'campaign_id'      => (int) $row['campaign_id'],
            'section'          => $resolved,
            'is_general'       => $row['gender_section'] === 'all',
            'job_role'         => $row['role_key'] ?? 'general',
            'job_title'        => $row['job_title'] ?? 'مشرف',
            'permission_level' => $row['permission_level'],
            'redirect'         => 'admin-supervisor.html',
        ]);
    }

    // --- مدير الحملة --------------------------------------------
    if (str_starts_with($loginId, '300')) {
        $st = $pdo->prepare(
            'SELECT campaign_id, campaign_name, manager_name, password_hash
               FROM campaigns WHERE campaign_id = ? LIMIT 1'
        );
        $st->execute([$loginId]);
        $row = $st->fetch();

        if (!$row || !$row['password_hash'] || !password_verify($password, $row['password_hash'])) {
            fail('رقم الحملة أو كلمة المرور غير صحيحة.', 401);
        }

        set_session_user([
            'role'        => 'campaign',
            'id'          => (int) $row['campaign_id'],
            'name'        => $row['manager_name'] ?: $row['campaign_name'],
            'campaign_id' => (int) $row['campaign_id'],
            'section'     => 'all',
            'job_role'    => 'campaign_manager',
            'job_title'   => 'مدير الحملة',
            'redirect'    => 'admin-campaign.html',
        ]);
    }

    fail('رقم العضوية غير صحيح. يبدأ بـ 100 للحجاج، 500 للمشرفين، 300 لمدير الحملة.', 422);
}

function set_session_user(array $user): void
{
    start_app_session();
    session_regenerate_id(true);       // يمنع تثبيت الجلسة
    $_SESSION['user'] = $user;

    $user['permissions'] = user_permissions();
    ok($user);
}

// ------------------------------------------------------------------
function do_logout(): void
{
    start_app_session();
    $_SESSION = [];
    if (ini_get('session.use_cookies')) {
        $p = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000,
                  $p['path'], $p['domain'], $p['secure'], $p['httponly']);
    }
    session_destroy();
    ok(['loggedOut' => true]);
}

// ------------------------------------------------------------------
function do_me(): void
{
    $u = current_user();
    if (!$u) {
        json_out(['ok' => true, 'data' => null, 'loggedIn' => false]);
    }

    // الصلاحيات تُرسل مع بيانات المستخدم حتى تبني كل صفحة واجهتها
    // على صلاحيات وظيفته فعلاً، بدل إظهار كل الأزرار للجميع.
    $u['permissions'] = user_permissions();

    json_out(['ok' => true, 'data' => $u, 'loggedIn' => true]);
}
