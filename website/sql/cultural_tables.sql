-- =====================================================================
--  جدولا المسابقة الثقافية — إضافة لقاعدة بيانات rafqa_haramain
--  يُنفَّذ مرة واحدة من phpMyAdmin. لا يحذف ولا يعدّل أي جدول قائم.
-- =====================================================================

CREATE TABLE IF NOT EXISTS `cultural_questions` (
  `question_id`    int(11)       NOT NULL AUTO_INCREMENT,
  `campaign_id`    int(11)       NOT NULL,
  `target_section` enum('all','men','women') NOT NULL DEFAULT 'all',
  `question_text`  varchar(500)  NOT NULL,
  `options`        varchar(1000) NOT NULL COMMENT 'خيارات مفصولة بفواصل كما تُدخَل من لوحة الحملة',
  `correct_answer` varchar(255)  NOT NULL,
  `is_active`      tinyint(1)    NOT NULL DEFAULT 1,
  `created_at`     datetime      DEFAULT current_timestamp(),
  PRIMARY KEY (`question_id`),
  KEY `fk_cq_campaign` (`campaign_id`),
  CONSTRAINT `fk_cq_campaign` FOREIGN KEY (`campaign_id`)
      REFERENCES `campaigns` (`campaign_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cultural_answers` (
  `answer_id`     int(11)      NOT NULL AUTO_INCREMENT,
  `question_id`   int(11)      NOT NULL,
  `pilgrim_id`    int(11)      NOT NULL,
  `chosen_answer` varchar(255) NOT NULL,
  `is_correct`    tinyint(1)   NOT NULL DEFAULT 0,
  `answered_at`   datetime     DEFAULT current_timestamp(),
  PRIMARY KEY (`answer_id`),
  UNIQUE KEY `uniq_question_pilgrim` (`question_id`,`pilgrim_id`),
  KEY `fk_ca_pilgrim` (`pilgrim_id`),
  CONSTRAINT `fk_ca_question` FOREIGN KEY (`question_id`)
      REFERENCES `cultural_questions` (`question_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ca_pilgrim` FOREIGN KEY (`pilgrim_id`)
      REFERENCES `pilgrims` (`pilgrim_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- الأسئلة الثلاثة التي كانت ثابتة داخل صفحة cultural.html تُنقل كما هي
INSERT INTO `cultural_questions`
  (`campaign_id`,`target_section`,`question_text`,`options`,`correct_answer`)
SELECT 30089,'all','ما الركن الذي يتم فيه الوقوف بعرفة؟','الطواف, الوقوف بعرفة, السعي','الوقوف بعرفة'
WHERE NOT EXISTS (SELECT 1 FROM `cultural_questions` WHERE `question_text` = 'ما الركن الذي يتم فيه الوقوف بعرفة؟');

INSERT INTO `cultural_questions`
  (`campaign_id`,`target_section`,`question_text`,`options`,`correct_answer`)
SELECT 30089,'all','أين يقع المسجد الحرام؟','مكة المكرمة, المدينة المنورة, جدة','مكة المكرمة'
WHERE NOT EXISTS (SELECT 1 FROM `cultural_questions` WHERE `question_text` = 'أين يقع المسجد الحرام؟');

INSERT INTO `cultural_questions`
  (`campaign_id`,`target_section`,`question_text`,`options`,`correct_answer`)
SELECT 30089,'all','أين يوجد المسجد النبوي؟','مكة المكرمة, المدينة المنورة, الطائف','المدينة المنورة'
WHERE NOT EXISTS (SELECT 1 FROM `cultural_questions` WHERE `question_text` = 'أين يوجد المسجد النبوي؟');
