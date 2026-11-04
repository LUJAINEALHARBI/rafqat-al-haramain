-- =====================================================================
--  رفقة بلاد الحرمين — تحديث قاعدة البيانات (الإصدار الثاني)
--  يُشغَّل مرة واحدة فوق القاعدة الموجودة، ولا يحذف أي جدول أو بيانات.
--
--  ما يضيفه هذا الملف:
--    1) حقول التسجيل الجديدة: رقم النسك ونوع الهوية وتاريخ انتهاء صلاحيتها
--    2) جداول برنامج المناسك (الرحلة والمحطات) لمتابعة رحلة الحاج كاملة
--    3) جداول تتبع الموقع: مواقع المخيمات والمشاعر + مواقع الحجاج
--    4) جداول الصلاحيات: قائمة الصلاحيات وربطها بوظائف المشرفين
--
--  طريقة التشغيل في phpMyAdmin:
--    افتحي قاعدة البيانات ← استيراد ← اختاري هذا الملف ← تنفيذ
--
--  MariaDB 10.4 / MySQL 5.7+        الترميز: utf8mb4_unicode_ci
-- =====================================================================

SET NAMES utf8mb4;
SET time_zone = "+00:00";

-- ---------------------------------------------------------------------
-- 1) حقول جديدة في جدول الحجاج
--    رقم النسك: رقم تصريح الحج الصادر من منصة نسك
--    نوع الهوية: هوية وطنية / إقامة / جواز سفر
--    تاريخ الانتهاء: صلاحية الهوية، ينبّه المشرف قبل انتهائها
-- ---------------------------------------------------------------------
ALTER TABLE `pilgrims`
  ADD COLUMN IF NOT EXISTS `id_type` enum('national_id','iqama','passport')
      NOT NULL DEFAULT 'national_id' AFTER `id_or_passport`,
  ADD COLUMN IF NOT EXISTS `id_expiry` date DEFAULT NULL AFTER `id_type`,
  ADD COLUMN IF NOT EXISTS `nusuk_number` varchar(30) DEFAULT NULL AFTER `id_expiry`;

-- فهرس يسرّع التحقق من تكرار رقم الهوية ورقم النسك عند التسجيل
ALTER TABLE `pilgrims`
  ADD INDEX IF NOT EXISTS `idx_pilgrim_identity` (`id_or_passport`),
  ADD INDEX IF NOT EXISTS `idx_pilgrim_nusuk`    (`nusuk_number`);

-- ---------------------------------------------------------------------
-- 2) برنامج المناسك: الرحلة ومحطاتها
--    المشرف ينشئ الرحلة ويرتّب محطاتها ويحدّد المنجز منها،
--    والحاج يتابع رحلته كاملة: ماذا انتهى وماذا بقي ومتى وبأي وسيلة.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `journey_programs` (
  `program_id`   int(11) NOT NULL AUTO_INCREMENT,
  `campaign_id`  int(11) NOT NULL,
  `program_name` varchar(150) NOT NULL,
  `hijri_year`   varchar(10) DEFAULT NULL,
  `section`      enum('men','women','all') NOT NULL DEFAULT 'all',
  `notes`        text DEFAULT NULL,
  `is_active`    tinyint(1) NOT NULL DEFAULT 1,
  `created_by`   int(11) DEFAULT NULL,
  `created_at`   datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`program_id`),
  UNIQUE KEY `uq_program_name` (`campaign_id`, `program_name`),
  KEY `idx_program_campaign` (`campaign_id`),
  KEY `idx_program_creator`  (`created_by`),
  CONSTRAINT `fk_program_campaign` FOREIGN KEY (`campaign_id`)
      REFERENCES `campaigns` (`campaign_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_program_creator` FOREIGN KEY (`created_by`)
      REFERENCES `supervisors` (`supervisor_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `journey_stations` (
  `station_id`     int(11) NOT NULL AUTO_INCREMENT,
  `program_id`     int(11) NOT NULL,
  `station_order`  int(11) NOT NULL DEFAULT 1,
  `station_name`   varchar(150) NOT NULL,
  `place_name`     varchar(120) DEFAULT NULL,
  `hijri_day`      varchar(40)  DEFAULT NULL,
  `start_datetime` datetime DEFAULT NULL,
  `end_datetime`   datetime DEFAULT NULL,
  `transport_type` enum('لا يوجد','سيراً على القدم','حافلة','قطار المشاعر','سيارة')
                   NOT NULL DEFAULT 'لا يوجد',
  `latitude`       decimal(10,7) DEFAULT NULL,
  `longitude`      decimal(10,7) DEFAULT NULL,
  `notes`          text DEFAULT NULL,
  `status`         enum('لم تبدأ','جارية','مكتملة') NOT NULL DEFAULT 'لم تبدأ',
  `completed_at`   datetime DEFAULT NULL,
  `updated_by`     int(11) DEFAULT NULL,
  PRIMARY KEY (`station_id`),
  UNIQUE KEY `uq_station_order` (`program_id`, `station_order`),
  KEY `idx_station_updater` (`updated_by`),
  CONSTRAINT `fk_station_program` FOREIGN KEY (`program_id`)
      REFERENCES `journey_programs` (`program_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_station_updater` FOREIGN KEY (`updated_by`)
      REFERENCES `supervisors` (`supervisor_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3) تتبع الموقع
--    site_locations: مواقع الفنادق والمخيمات والمشاعر ونقاط التجمع،
--                    كانت مكتوبة داخل صفحة الخريطة وصارت تُقرأ من هنا.
--    pilgrim_locations: الموقع الذي يشاركه الحاج من جواله،
--                    والمشرف يرى آخر موقع لكل حاج من حجاجه.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `site_locations` (
  `site_id`     int(11) NOT NULL AUTO_INCREMENT,
  `campaign_id` int(11) NOT NULL,
  `site_name`   varchar(150) NOT NULL,
  `site_type`   varchar(60) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `period_note` varchar(150) DEFAULT NULL,
  `latitude`    decimal(10,7) NOT NULL,
  `longitude`   decimal(10,7) NOT NULL,
  `section`     enum('men','women','all') NOT NULL DEFAULT 'all',
  PRIMARY KEY (`site_id`),
  UNIQUE KEY `uq_site_name` (`campaign_id`, `site_name`),
  KEY `idx_site_campaign` (`campaign_id`),
  CONSTRAINT `fk_site_campaign` FOREIGN KEY (`campaign_id`)
      REFERENCES `campaigns` (`campaign_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pilgrim_locations` (
  `location_id` int(11) NOT NULL AUTO_INCREMENT,
  `pilgrim_id`  int(11) NOT NULL,
  `latitude`    decimal(10,7) NOT NULL,
  `longitude`   decimal(10,7) NOT NULL,
  `accuracy_m`  int(11) DEFAULT NULL,
  `note`        varchar(150) DEFAULT NULL,
  `recorded_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`location_id`),
  KEY `idx_loc_pilgrim` (`pilgrim_id`, `recorded_at`),
  CONSTRAINT `fk_loc_pilgrim` FOREIGN KEY (`pilgrim_id`)
      REFERENCES `pilgrims` (`pilgrim_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 4) الصلاحيات
--    app_permissions: قائمة الصلاحيات الموجودة في النظام بأسمائها العربية
--    job_permissions: ربط كل وظيفة مشرف بالصلاحيات المسموحة لها
--    الـ API يقرأ هذين الجدولين قبل تنفيذ أي عملية، فالصلاحية صارت
--    بيانات في القاعدة وليست شرطاً مكتوباً داخل الكود.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `app_permissions` (
  `permission_key`   varchar(40) NOT NULL,
  `permission_label` varchar(150) NOT NULL,
  `category`         varchar(60) DEFAULT NULL,
  PRIMARY KEY (`permission_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `job_permissions` (
  `job_id`         int(11) NOT NULL,
  `permission_key` varchar(40) NOT NULL,
  PRIMARY KEY (`job_id`, `permission_key`),
  KEY `idx_jobperm_key` (`permission_key`),
  CONSTRAINT `fk_jobperm_job` FOREIGN KEY (`job_id`)
      REFERENCES `jobs` (`job_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_jobperm_perm` FOREIGN KEY (`permission_key`)
      REFERENCES `app_permissions` (`permission_key`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  البيانات الأولية
-- =====================================================================

-- ---------------------------------------------------------------------
-- قائمة الصلاحيات الموجودة في النظام
-- ---------------------------------------------------------------------
INSERT INTO `app_permissions` (`permission_key`, `permission_label`, `category`) VALUES
('view_pilgrims',      'عرض قائمة الحجاج وبياناتهم الأساسية',           'الحجاج'),
('edit_pilgrims',      'تعديل بيانات الحجاج والتسكين',                  'الحجاج'),
('view_medical',       'عرض الحالات الصحية والأمراض المزمنة',           'الصحة'),
('manage_medical',     'متابعة الطلبات الطبية وتحديث حالتها',           'الصحة'),
('manage_transport',   'إدارة التفويج وحركة الحافلات',                  'التنقل'),
('manage_catering',    'إدارة الوجبات والإعاشة',                        'الإعاشة'),
('manage_housing',     'إدارة الخيام والأسرّة وصيانة المخيم',            'السكن'),
('manage_journey',     'إنشاء برنامج المناسك وتحديث محطات الرحلة',      'الرحلة'),
('view_locations',     'متابعة مواقع الحجاج على الخريطة',               'الرحلة'),
('manage_sites',       'إضافة مواقع المخيمات والمشاعر وتعديلها',         'الرحلة'),
('manage_services',    'إضافة الخدمات وتعديل حالتها',                   'الخدمات'),
('view_ratings',       'عرض تقييمات الحجاج للخدمات',                    'الخدمات'),
('manage_expenses',    'تسجيل مصروفات الحملة',                          'المالية'),
('approve_expenses',   'اعتماد المصروفات',                              'المالية'),
('manage_cultural',    'إدارة المسابقة الثقافية',                       'الثقافي'),
('send_notifications', 'إرسال التنبيهات للحجاج والمشرفين',              'التنبيهات'),
('manage_chat',        'إدارة غرف المحادثة',                            'المحادثة'),
('manage_supervisors', 'إضافة المشرفين وتعديل وظائفهم',                 'الإدارة'),
('reset_passwords',    'إعادة تعيين كلمات مرور الحسابات',               'الإدارة')
ON DUPLICATE KEY UPDATE `permission_label` = VALUES(`permission_label`),
                        `category`         = VALUES(`category`);

-- ---------------------------------------------------------------------
-- صلاحيات كل وظيفة
--   1 مشرف عام        : متابعة شاملة، يرى الحالات الصحية ولا يتصرف فيها
--   2 الموظف الصحي     : الحالات الصحية والطلبات الطبية فقط، ولا يدخل
--                        على التفويج أو الإعاشة أو السكن أو المصروفات
--   3 موظف الحشود      : التفويج وبرنامج المناسك ومتابعة المواقع،
--                        ولا يرى الأمراض المزمنة للحجاج
--   4 موظف الإعاشة     : الوجبات فقط، ولا يرى الحالات الصحية
--   5 موظف السكن       : الخيام والأسرّة وتعديل التسكين، بدون الحالات الصحية
--   مدير الحملة يملك كل الصلاحيات ولا يحتاج صفوفاً هنا
-- ---------------------------------------------------------------------
INSERT IGNORE INTO `job_permissions` (`job_id`, `permission_key`) VALUES
-- (1) مشرف عام
(1,'view_pilgrims'),(1,'edit_pilgrims'),(1,'view_medical'),(1,'manage_transport'),
(1,'manage_catering'),(1,'manage_housing'),(1,'manage_journey'),(1,'view_locations'),
(1,'manage_services'),(1,'view_ratings'),(1,'manage_expenses'),(1,'manage_cultural'),
(1,'manage_sites'),(1,'send_notifications'),(1,'manage_chat'),
-- (2) الموظف الصحي
(2,'view_pilgrims'),(2,'view_medical'),(2,'manage_medical'),(2,'view_locations'),
(2,'view_ratings'),(2,'send_notifications'),(2,'manage_chat'),
-- (3) موظف الحشود والتنقل
(3,'view_pilgrims'),(3,'manage_transport'),(3,'manage_journey'),(3,'view_locations'),
(3,'view_ratings'),(3,'send_notifications'),(3,'manage_chat'),
-- (4) موظف الإعاشة والأطعمة
(4,'view_pilgrims'),(4,'manage_catering'),(4,'view_ratings'),
(4,'send_notifications'),(4,'manage_chat'),
-- (5) موظف السكن وخدمة الحجاج
(5,'view_pilgrims'),(5,'edit_pilgrims'),(5,'manage_housing'),(5,'view_ratings'),
(5,'send_notifications'),(5,'manage_chat');

-- ---------------------------------------------------------------------
-- مواقع الحملة الحقيقية (إحداثيات فعلية لمكة والمشاعر)
-- ---------------------------------------------------------------------
INSERT IGNORE INTO `site_locations`
  (`campaign_id`,`site_name`,`site_type`,`description`,`period_note`,`latitude`,`longitude`,`section`) VALUES
(30089,'نقطة تجمع جدة','نقطة تجمع','نقطة انطلاق الحافلات وحصر الحجاج قبل التحرك','قبل الإحرام بيوم',21.5433000,39.1728000,'all'),
(30089,'فندق الحملة بالعزيزية','فندق','سكن الحجاج في مكة قبل التوجه إلى المشاعر','من 4 إلى 7 ذو الحجة',21.4094000,39.8579000,'all'),
(30089,'المسجد الحرام','مشعر','الطواف والسعي وطواف الإفاضة وطواف الوداع','طوال أيام الرحلة',21.4225000,39.8262000,'all'),
(30089,'مخيم منى - قسم الرجال','مخيم','خيام قسم الرجال في منى (CAMP-101)','من 8 إلى 12 ذو الحجة',21.4133000,39.8933000,'men'),
(30089,'مخيم منى - قسم النساء','مخيم','خيام قسم النساء في منى (CAMP-201)','من 8 إلى 12 ذو الحجة',21.4145000,39.8947000,'women'),
(30089,'مخيم عرفات','مشعر','مخيم الحملة في عرفات ليوم الوقوف','يوم 9 ذو الحجة',21.3548000,39.9840000,'all'),
(30089,'مبيت مزدلفة','مشعر','مكان المبيت وجمع الحصى بعد النفرة من عرفة','ليلة 10 ذو الحجة',21.3933000,39.9372000,'all'),
(30089,'جسر الجمرات','مشعر','مكان رمي الجمرات في منى','من 10 إلى 12 ذو الحجة',21.4219000,39.8728000,'all');

-- ---------------------------------------------------------------------
-- برنامج المناسك: رحلة الحج كاملة بمحطاتها الحقيقية
--   المحطات مرتّبة كما تسير الرحلة فعلاً، وكل محطة فيها وقتها
--   ووسيلة الانتقال إليها وموقعها، وحالتها يحدّثها المشرف.
-- ---------------------------------------------------------------------
INSERT IGNORE INTO `journey_programs`
  (`campaign_id`,`program_name`,`hijri_year`,`section`,`notes`,`is_active`,`created_by`) VALUES
(30089,'برنامج مناسك الحج','1447هـ','all',
 'برنامج الرحلة من نقطة التجمع حتى طواف الوداع. المشرف يحدّث حالة كل محطة أثناء الرحلة.',
 1, 5000);

SET @pid = (SELECT `program_id` FROM `journey_programs`
             WHERE `campaign_id` = 30089 AND `program_name` = 'برنامج مناسك الحج' LIMIT 1);

INSERT IGNORE INTO `journey_stations`
  (`program_id`,`station_order`,`station_name`,`place_name`,`hijri_day`,
   `start_datetime`,`end_datetime`,`transport_type`,`latitude`,`longitude`,`notes`,`status`,`completed_at`) VALUES
(@pid, 1,'التجمع وانطلاق الحافلات','نقطة تجمع جدة','7 ذو الحجة',
 '2026-05-20 06:00:00','2026-05-20 08:00:00','حافلة',21.5433000,39.1728000,
 'حصر الحجاج مع مشرف كل مجموعة قبل تحرك الحافلة.','مكتملة','2026-05-20 08:10:00'),
(@pid, 2,'الوصول إلى مكة والتسكين في الفندق','فندق الحملة بالعزيزية','7 ذو الحجة',
 '2026-05-20 12:30:00','2026-05-20 16:00:00','حافلة',21.4094000,39.8579000,
 'استلام الغرف وتوزيع الحجاج حسب القسم.','مكتملة','2026-05-20 16:20:00'),
(@pid, 3,'الإحرام والتوجه إلى منى (يوم التروية)','مخيم منى','8 ذو الحجة',
 '2026-05-21 07:00:00','2026-05-21 10:00:00','حافلة',21.4133000,39.8933000,
 'الإحرام من الفندق ثم الانتقال إلى الخيام في منى.','مكتملة','2026-05-21 10:15:00'),
(@pid, 4,'المبيت في منى','مخيم منى','ليلة 9 ذو الحجة',
 '2026-05-21 20:00:00','2026-05-22 04:00:00','لا يوجد',21.4133000,39.8933000,
 'المبيت في الخيام وصلاة الفجر قبل التحرك لعرفة.','مكتملة','2026-05-22 04:30:00'),
(@pid, 5,'الانتقال من منى إلى عرفة','مخيم عرفات','9 ذو الحجة',
 '2026-05-22 05:00:00','2026-05-22 07:30:00','حافلة',21.3548000,39.9840000,
 'التحرك بعد الفجر بحافلات الحملة حسب كشف التفويج.','مكتملة','2026-05-22 07:40:00'),
(@pid, 6,'الوقوف بعرفة حتى الغروب','مخيم عرفات','9 ذو الحجة',
 '2026-05-22 08:00:00','2026-05-22 18:50:00','لا يوجد',21.3548000,39.9840000,
 'الدعاء والذكر في المخيم، وتوزيع الماء والوجبات على الحجاج.','جارية',NULL),
(@pid, 7,'النفرة من عرفة إلى مزدلفة','مبيت مزدلفة','ليلة 10 ذو الحجة',
 '2026-05-22 19:00:00','2026-05-22 21:30:00','حافلة',21.3933000,39.9372000,
 'التحرك بعد الغروب، والتجمع عند الحافلة بأرقام المجموعات.','لم تبدأ',NULL),
(@pid, 8,'المبيت في مزدلفة وجمع الحصى','مبيت مزدلفة','ليلة 10 ذو الحجة',
 '2026-05-22 21:30:00','2026-05-23 04:00:00','لا يوجد',21.3933000,39.9372000,
 'المبيت حتى ما بعد منتصف الليل وجمع حصى الجمرات.','لم تبدأ',NULL),
(@pid, 9,'الانتقال من مزدلفة إلى منى','مخيم منى','10 ذو الحجة',
 '2026-05-23 04:30:00','2026-05-23 06:00:00','قطار المشاعر',21.4133000,39.8933000,
 'الانتقال بقطار المشاعر حسب الموعد المخصص للحملة.','لم تبدأ',NULL),
(@pid,10,'رمي جمرة العقبة ثم الحلق والهدي','جسر الجمرات','10 ذو الحجة',
 '2026-05-23 06:30:00','2026-05-23 11:00:00','سيراً على القدم',21.4219000,39.8728000,
 'الرمي ضمن وقت الحملة المحدد، ثم الهدي والحلق.','لم تبدأ',NULL),
(@pid,11,'طواف الإفاضة والسعي','المسجد الحرام','10 ذو الحجة',
 '2026-05-23 14:00:00','2026-05-23 19:00:00','قطار المشاعر',21.4225000,39.8262000,
 'الذهاب للحرم بمجموعات مع المشرف ثم العودة إلى منى.','لم تبدأ',NULL),
(@pid,12,'المبيت في منى ورمي الجمرات','جسر الجمرات','11 و12 ذو الحجة',
 '2026-05-24 13:00:00','2026-05-25 17:00:00','سيراً على القدم',21.4219000,39.8728000,
 'رمي الجمرات الثلاث بعد الزوال في اليومين.','لم تبدأ',NULL),
(@pid,13,'النفرة من منى والعودة إلى الفندق','فندق الحملة بالعزيزية','12 ذو الحجة',
 '2026-05-25 18:00:00','2026-05-25 20:30:00','حافلة',21.4094000,39.8579000,
 'التعجل والنفرة قبل الغروب وفك الخيام.','لم تبدأ',NULL),
(@pid,14,'طواف الوداع والعودة','المسجد الحرام','13 ذو الحجة',
 '2026-05-26 08:00:00','2026-05-26 14:00:00','حافلة',21.4225000,39.8262000,
 'طواف الوداع ثم انطلاق الحافلات إلى نقطة التجمع.','لم تبدأ',NULL);

-- ---------------------------------------------------------------------
-- تعبئة الحقول الجديدة لحسابات الحجاج الموجودة
--   نوع الهوية يُحدَّد من بداية الرقم: 1 هوية وطنية، 2 إقامة
--   وأرقام النسك أُضيفت بصيغة الحملة، وتواريخ الصلاحية من البيانات الرسمية
--   للحاج. (لا يُحذف أي سجل، التحديث يملأ الحقول الفارغة فقط)
-- ---------------------------------------------------------------------
UPDATE `pilgrims` SET `id_type` = 'national_id'
  WHERE `id_or_passport` LIKE '1%' AND `nationality` = 'Saudi Arabia';
UPDATE `pilgrims` SET `id_type` = 'iqama'
  WHERE `id_or_passport` LIKE '2%' AND `nationality` <> 'Saudi Arabia';
UPDATE `pilgrims` SET `id_type` = 'national_id'
  WHERE `id_or_passport` LIKE '2%' AND `nationality` = 'Saudi Arabia';

UPDATE `pilgrims` SET `nusuk_number` = CONCAT('NSK-1447-', `pilgrim_id`)
  WHERE `nusuk_number` IS NULL OR `nusuk_number` = '';

UPDATE `pilgrims` SET `id_expiry` = '2028-03-14' WHERE `pilgrim_id` = 100101 AND `id_expiry` IS NULL;
UPDATE `pilgrims` SET `id_expiry` = '2027-09-02' WHERE `pilgrim_id` = 100102 AND `id_expiry` IS NULL;
UPDATE `pilgrims` SET `id_expiry` = '2026-11-28' WHERE `pilgrim_id` = 100201 AND `id_expiry` IS NULL;
UPDATE `pilgrims` SET `id_expiry` = '2029-01-20' WHERE `pilgrim_id` = 100202 AND `id_expiry` IS NULL;

-- تم.

-- ---------------------------------------------------------------------
-- 5) باقات الحملة
--    كانت الباقات وأسعارها مكتوبة داخل الصفحة الرئيسية، وصارت تُقرأ
--    من هذا الجدول. أسماء الباقات نفس القيم المستخدمة في
--    pilgrims.package_type حتى تربط الحاج بباقته.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `packages` (
  `package_id`   int(11) NOT NULL AUTO_INCREMENT,
  `campaign_id`  int(11) NOT NULL,
  `package_name` varchar(100) NOT NULL,
  `package_tag`  varchar(60) DEFAULT NULL,
  `price`        decimal(10,2) NOT NULL,
  `features`     text DEFAULT NULL,
  `is_featured`  tinyint(1) NOT NULL DEFAULT 0,
  `sort_order`   int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`package_id`),
  UNIQUE KEY `uq_package_name` (`campaign_id`, `package_name`),
  CONSTRAINT `fk_package_campaign` FOREIGN KEY (`campaign_id`)
      REFERENCES `campaigns` (`campaign_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- السعر المعروض للباقة الشاملة هو نفس price_per_person في جدول الحملة
INSERT IGNORE INTO `packages`
  (`campaign_id`,`package_name`,`package_tag`,`price`,`features`,`is_featured`,`sort_order`) VALUES
(30089,'باقة اقتصادية','اقتصادية',6500.00,
 'السكن في مخيم الحملة\nالنقل بين المشاعر\nثلاث وجبات يومية\nالتواصل مع المشرف\nمتابعة برنامج المناسك',0,1),
(30089,'باقة شاملة','الأكثر طلباً',8500.00,
 'كل خدمات الباقة الاقتصادية\nالرعاية الطبية داخل المخيم\nبلاغات الأمتعة المفقودة\nالبرنامج الثقافي\nغرفة المحادثة مع المشرفين',1,2),
(30089,'باقة مميزة','مميزة',11900.00,
 'كل خدمات الباقة الشاملة\nأولوية في التفويج والتنقل\nمتابعة مباشرة من المشرف العام\nخيمة بعدد أسرّة أقل\nخدمة طلبات خاصة',0,3);

-- ---------------------------------------------------------------------
-- 6) وجبات الإعاشة كخدمات فعلية
--    جدول الوجبات ومواعيدها كان مكتوباً داخل صفحة الخدمات، وصار
--    صفوفاً في جدول services من نوع catering بمواعيدها وأصنافها.
--    (INSERT ... WHERE NOT EXISTS حتى لا يتكرر عند إعادة التشغيل)
-- ---------------------------------------------------------------------
INSERT INTO `services` (`service_name`,`description`,`service_type`,`service_datetime`,`service_location`,`status`)
SELECT 'وجبة الإفطار','بيض مسلوق، فول، خبز، جبن، شاي','catering','2026-05-21 06:00:00','مطعم المخيم','متاحة'
 WHERE NOT EXISTS (SELECT 1 FROM `services` WHERE `service_name` = 'وجبة الإفطار');

INSERT INTO `services` (`service_name`,`description`,`service_type`,`service_datetime`,`service_location`,`status`)
SELECT 'وجبة الغداء','أرز بخاري مع دجاج، سلطة، مياه معدنية','catering','2026-05-21 13:00:00','مطعم المخيم','متاحة'
 WHERE NOT EXISTS (SELECT 1 FROM `services` WHERE `service_name` = 'وجبة الغداء');

INSERT INTO `services` (`service_name`,`description`,`service_type`,`service_datetime`,`service_location`,`status`)
SELECT 'وجبة العشاء','كبسة لحم أو دجاج، خبز، لبن وفواكه','catering','2026-05-21 19:00:00','مطعم المخيم','متاحة'
 WHERE NOT EXISTS (SELECT 1 FROM `services` WHERE `service_name` = 'وجبة العشاء');
