<?php
/**
 * المسابقة الثقافية
 *
 *   GET  cultural.php?action=list      قائمة الأسئلة (حسب الدور والقسم)
 *   POST cultural.php?action=add       إضافة سؤال      — مدير الحملة فقط
 *   POST cultural.php?action=answer    إجابة سؤال      — الحاج فقط (التصحيح في الخادم)
 *   GET  cultural.php?action=results   نتائج الأسئلة   — مدير الحملة فقط
 *
 * ملاحظة: الإجابة الصحيحة لا تُرسل للحاج قبل أن يجيب.
 */

require_once __DIR__ . '/helpers.php';

$action = param('action', 'list');

switch ($action) {
    case 'list':    list_questions();  break;
    case 'add':     add_question();    break;
    case 'answer':  answer_question(); break;
    case 'results': question_results(); break;
    default: fail('عملية غير معروفة.', 404);
}

// ------------------------------------------------------------------
/** تطبيع النص قبل المقارنة: مسافات زائدة وتشكيل بسيط */
function normalize_answer(string $s): string
{
    $s = trim($s);
    $s = preg_replace('/\s+/u', ' ', $s);
    return mb_strtolower($s, 'UTF-8');
}

/** يحوّل نص الخيارات المفصولة بفواصل إلى مصفوفة نظيفة */
function split_options(string $raw): array
{
    $parts = preg_split('/[,،]/u', $raw);
    $out = [];
    foreach ($parts as $p) {
        $p = trim($p);
        if ($p !== '') {
            $out[] = $p;
        }
    }
    return $out;
}

// ------------------------------------------------------------------
function list_questions(): void
{
    $u = require_user();

    if ($u['role'] === 'pilgrim') {
        $st = db()->prepare(
            "SELECT q.question_id, q.question_text, q.options, q.target_section,
                    a.chosen_answer, a.is_correct
               FROM cultural_questions q
          LEFT JOIN cultural_answers a
                 ON a.question_id = q.question_id AND a.pilgrim_id = ?
              WHERE q.campaign_id = ? AND q.is_active = 1
                AND q.target_section IN ('all', ?)
           ORDER BY q.question_id"
        );
        $st->execute([$u['id'], $u['campaign_id'], $u['section']]);
        $rows = $st->fetchAll();

        $out = [];
        foreach ($rows as $r) {
            $answered = $r['chosen_answer'] !== null;
            $out[] = [
                'question_id'   => (int) $r['question_id'],
                'question_text' => $r['question_text'],
                'options'       => split_options($r['options']),
                'answered'      => $answered,
                'chosen_answer' => $r['chosen_answer'],
                'is_correct'    => $answered ? (bool) $r['is_correct'] : null,
            ];
        }
        ok($out);
    }

    // مدير الحملة والمشرفون: كل الأسئلة مع عدد الإجابات
    require_user(['campaign', 'supervisor']);

    $st = db()->prepare(
        "SELECT q.question_id, q.question_text, q.options, q.correct_answer,
                q.target_section, q.is_active, q.created_at,
                COUNT(a.answer_id)                               AS answers_count,
                SUM(CASE WHEN a.is_correct = 1 THEN 1 ELSE 0 END) AS correct_count
           FROM cultural_questions q
      LEFT JOIN cultural_answers a ON a.question_id = q.question_id
          WHERE q.campaign_id = ?
       GROUP BY q.question_id
       ORDER BY q.question_id DESC"
    );
    $st->execute([$u['campaign_id']]);
    $rows = $st->fetchAll();

    foreach ($rows as &$r) {
        $r['question_id']   = (int) $r['question_id'];
        $r['options']       = split_options($r['options']);
        $r['answers_count'] = (int) $r['answers_count'];
        $r['correct_count'] = (int) $r['correct_count'];
        $r['is_active']     = (bool) $r['is_active'];
    }
    unset($r);

    ok($rows);
}

// ------------------------------------------------------------------
function add_question(): void
{
    require_post();
    $u = require_user(['campaign']);

    $text    = require_text('question_text', 500);
    $rawOpts = require_text('options', 1000);
    $correct = require_text('correct_answer', 255);
    $section = one_of('target_section', ['all', 'men', 'women'], 'all');

    $options = split_options($rawOpts);
    if (count($options) < 2) {
        fail('أدخل خيارين على الأقل مفصولين بفاصلة.', 422);
    }

    // الإجابة الصحيحة يجب أن تكون أحد الخيارات، وإلا صار السؤال بلا إجابة صحيحة
    $match = null;
    foreach ($options as $opt) {
        if (normalize_answer($opt) === normalize_answer($correct)) {
            $match = $opt;
            break;
        }
    }
    if ($match === null) {
        fail('الإجابة الصحيحة يجب أن تكون واحدة من الخيارات المكتوبة.', 422);
    }

    $st = db()->prepare(
        'INSERT INTO cultural_questions
            (campaign_id, target_section, question_text, options, correct_answer)
         VALUES (?,?,?,?,?)'
    );
    $st->execute([
        $u['campaign_id'],
        $section,
        $text,
        implode(', ', $options),
        $match,
    ]);

    ok(['question_id' => (int) db()->lastInsertId()]);
}

// ------------------------------------------------------------------
function answer_question(): void
{
    require_post();
    $u = require_user(['pilgrim']);

    $qid    = require_int('question_id');
    $chosen = require_text('answer', 255);

    $st = db()->prepare(
        "SELECT question_id, options, correct_answer, target_section
           FROM cultural_questions
          WHERE question_id = ? AND campaign_id = ? AND is_active = 1
          LIMIT 1"
    );
    $st->execute([$qid, $u['campaign_id']]);
    $q = $st->fetch();

    if (!$q) {
        fail('السؤال غير موجود أو غير متاح.', 404);
    }
    if ($q['target_section'] !== 'all' && $q['target_section'] !== $u['section']) {
        fail('هذا السؤال ليس مخصصاً لقسمك.', 403);
    }

    // الخيار المرسل يجب أن يكون من خيارات السؤال
    $options = split_options($q['options']);
    $valid = false;
    foreach ($options as $opt) {
        if (normalize_answer($opt) === normalize_answer($chosen)) {
            $chosen = $opt;
            $valid  = true;
            break;
        }
    }
    if (!$valid) {
        fail('الإجابة المرسلة ليست من خيارات السؤال.', 422);
    }

    // التصحيح يتم هنا في الخادم، لا في المتصفح
    $isCorrect = normalize_answer($chosen) === normalize_answer($q['correct_answer']) ? 1 : 0;

    $ins = db()->prepare(
        'INSERT INTO cultural_answers (question_id, pilgrim_id, chosen_answer, is_correct)
         VALUES (?,?,?,?)
         ON DUPLICATE KEY UPDATE chosen_answer = VALUES(chosen_answer),
                                 is_correct    = VALUES(is_correct),
                                 answered_at   = CURRENT_TIMESTAMP'
    );
    $ins->execute([$qid, $u['id'], $chosen, $isCorrect]);

    ok([
        'question_id'    => $qid,
        'is_correct'     => (bool) $isCorrect,
        'correct_answer' => $q['correct_answer'],
    ]);
}

// ------------------------------------------------------------------
function question_results(): void
{
    $u = require_user(['campaign']);

    $st = db()->prepare(
        "SELECT q.question_id, q.question_text, p.pilgrim_id, p.name AS pilgrim_name,
                a.chosen_answer, a.is_correct, a.answered_at
           FROM cultural_answers a
           JOIN cultural_questions q ON q.question_id = a.question_id
           JOIN pilgrims p           ON p.pilgrim_id  = a.pilgrim_id
          WHERE q.campaign_id = ?
       ORDER BY a.answered_at DESC"
    );
    $st->execute([$u['campaign_id']]);
    $rows = $st->fetchAll();

    foreach ($rows as &$r) {
        $r['question_id'] = (int) $r['question_id'];
        $r['pilgrim_id']  = (int) $r['pilgrim_id'];
        $r['is_correct']  = (bool) $r['is_correct'];
    }
    unset($r);

    ok($rows);
}
