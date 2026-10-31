-- =====================================================================
--  قاعدة بيانات مشروع: رفقة بلاد الحرمين
--  الملف النهائي (البنية + بيانات تجريبية)
--  مبني على ملف rafqa_haramain1.sql الأصلي مع إضافات موثقة
--  MariaDB 10.4 / MySQL 5.7+        الترميز: utf8mb4_unicode_ci
-- =====================================================================
--
--  طريقة الاستيراد في phpMyAdmin:
--    1) أنشئي قاعدة بيانات باسم  rafqa_haramain  بترميز utf8mb4_unicode_ci
--    2) ادخلي عليها ثم اضغطي "استيراد" واختاري هذا الملف
--
--  ملاحظة: الملف يحذف الجداول القديمة (إن وُجدت) ويعيد إنشاءها.
-- =====================================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `messages`;
DROP TABLE IF EXISTS `chat_rooms`;
DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `ratings`;
DROP TABLE IF EXISTS `service_provisions`;
DROP TABLE IF EXISTS `services`;
DROP TABLE IF EXISTS `permissions`;
DROP TABLE IF EXISTS `expenses`;
DROP TABLE IF EXISTS `supervisor_tasks`;
DROP TABLE IF EXISTS `pilgrims`;
DROP TABLE IF EXISTS `supervisors`;
DROP TABLE IF EXISTS `jobs`;
DROP TABLE IF EXISTS `campaigns`;

SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- جدول `campaigns` — الحملات
-- الأعمدة المضافة: password_hash, company_name, manager_name,
--   manager_email, manager_phone, price_per_person, start_city, start_date
-- السبب: صفحة campaign-profile.html تحفظ هذه الحقول، وصفحة login.html
--        تسجّل دخول مدير الحملة برقم الحملة وكلمة مرور.
-- ---------------------------------------------------------------------
CREATE TABLE `campaigns` (
  `campaign_id` int(11) NOT NULL,
  `campaign_name` varchar(150) NOT NULL,
  `license_number` varchar(50) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `extra_info` text DEFAULT NULL,
  `company_name` varchar(150) DEFAULT NULL,
  `manager_name` varchar(100) DEFAULT NULL,
  `manager_email` varchar(150) DEFAULT NULL,
  `manager_phone` varchar(20) DEFAULT NULL,
  `price_per_person` decimal(10,2) DEFAULT NULL,
  `start_city` varchar(80) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `password_hash` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- جدول `jobs` — الوظيفة   ** جدول جديد **
-- مصدره: الرسم اليدوي المرفق (الوظيفة / وظيفة Id / مسمى وظيفي / الصلاحية)
-- `role_key` عمود تقني يربط الوظيفة بالكود في صفحة لوحة المشرف.
-- ---------------------------------------------------------------------
CREATE TABLE `jobs` (
  `job_id` int(11) NOT NULL,
  `job_title` varchar(100) NOT NULL,
  `permission_level` varchar(100) DEFAULT NULL,
  `role_key` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- جدول `supervisors` — المشرفون
-- الأعمدة المضافة: job_id (من الرسم اليدوي), gender_section
-- السبب: login.html يوجّه المشرف حسب تخصصه والقسم (رجال/نساء)،
--        و admin-supervisor.html يعرض محتوى مختلف لكل تخصص.
-- ---------------------------------------------------------------------
CREATE TABLE `supervisors` (
  `supervisor_id` int(11) NOT NULL,
  `campaign_id` int(11) NOT NULL,
  `job_id` int(11) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `gender_section` enum('men','women','all') NOT NULL DEFAULT 'men',
  `password_hash` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- جدول `pilgrims` — الحجاج
-- الأعمدة المضافة: gender, email, marital_status, chronic_conditions,
--                  camp_id, created_at
-- السبب: نموذج register.html يرسل كل هذه الحقول،
--        و assign-pilgrims.html يسند الحاج إلى رقم مخيم،
--        و admin-supervisor.html (التخصص الصحي) يعرض الأمراض المزمنة.
-- ---------------------------------------------------------------------
CREATE TABLE `pilgrims` (
  `pilgrim_id` int(11) NOT NULL,
  `campaign_id` int(11) NOT NULL,
  `supervisor_id` int(11) DEFAULT NULL,
  `booking_number` varchar(50) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `id_or_passport` varchar(50) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `nationality` varchar(50) DEFAULT NULL,
  `age` tinyint(3) UNSIGNED DEFAULT NULL,
  `city` varchar(80) DEFAULT NULL,
  `package_type` varchar(80) DEFAULT NULL,
  `gathering_point` varchar(150) DEFAULT NULL,
  `tent_number` varchar(20) DEFAULT NULL,
  `bed_number` varchar(20) DEFAULT NULL,
  `password_hash` varchar(255) DEFAULT NULL,
  `gender` enum('male','female') NOT NULL DEFAULT 'male',
  `email` varchar(150) DEFAULT NULL,
  `marital_status` varchar(50) DEFAULT NULL,
  `chronic_conditions` text DEFAULT NULL,
  `camp_id` varchar(20) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- جدول `services` — الخدمات  (كما هو في الملف الأصلي، بدون تعديل)
-- ---------------------------------------------------------------------
CREATE TABLE `services` (
  `service_id` int(11) NOT NULL,
  `service_name` varchar(150) NOT NULL,
  `description` text DEFAULT NULL,
  `service_type` varchar(80) DEFAULT NULL,
  `service_datetime` datetime DEFAULT NULL,
  `service_location` varchar(255) DEFAULT NULL,
  `status` enum('متاحة','غير متاحة') NOT NULL DEFAULT 'متاحة'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- جدول `service_provisions` — طلبات/تقديم الخدمات للحجاج
-- الأعمدة المضافة: supervisor_id, request_number, details
-- السبب: جدول الطلبات في admin-supervisor.html يعرض رقم الطلب والتفاصيل
--        والمشرف المسؤول عن الطلب.
-- ---------------------------------------------------------------------
CREATE TABLE `service_provisions` (
  `provision_id` int(11) NOT NULL,
  `pilgrim_id` int(11) NOT NULL,
  `service_id` int(11) NOT NULL,
  `supervisor_id` int(11) DEFAULT NULL,
  `request_number` varchar(30) DEFAULT NULL,
  `details` varchar(255) DEFAULT NULL,
  `provision_date` date DEFAULT NULL,
  `provision_time` time DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- جدول `ratings` — تقييمات الحجاج
-- التصحيح: الملف الأصلي كان بدون ENGINE ولا CHARSET، فكان يعتمد على
--          إعدادات الخادم (قد يتجاهل المفتاح الأجنبي أو يفسد العربي).
-- الإضافة: قيد CHECK لعدد النجوم 1..5
-- الأعمدة المضافة: pilgrim_id, service_id  — وصار provision_id اختيارياً
-- السبب: نافذة "تقييم الخدمات" في services.html تقيّم خدمة عامة
--        (وجبات/طبي/نظافة...) وليس طلباً محدداً، فلا يوجد provision لها.
-- ---------------------------------------------------------------------
CREATE TABLE `ratings` (
  `rating_id` int(11) NOT NULL,
  `pilgrim_id` int(11) NOT NULL,
  `service_id` int(11) DEFAULT NULL,
  `provision_id` int(11) DEFAULT NULL,
  `stars` tinyint(4) NOT NULL,
  `comment` text DEFAULT NULL,
  `rating_date` datetime DEFAULT current_timestamp(),
  CONSTRAINT `chk_stars_range` CHECK (`stars` BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- جدول `permissions` — تصاريح الحجاج (كما هو في الملف الأصلي)
-- تنبيه تسمية: هذا الجدول يمثل "تصريح الحج" وليس صلاحيات النظام.
--              صلاحيات النظام صارت في جدول `jobs`.
-- ---------------------------------------------------------------------
CREATE TABLE `permissions` (
  `permission_id` int(11) NOT NULL,
  `campaign_id` int(11) NOT NULL,
  `pilgrim_id` int(11) NOT NULL,
  `permission_name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `permission_type` varchar(80) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- جدول `notifications` — التنبيهات
-- الأعمدة المضافة: pilgrim_id, campaign_id, target_role, target_section
-- السبب: الجدول الأصلي فيه المُرسِل فقط (supervisor_id) ولا يوجد فيه
--        مستقبِل، فكان من المستحيل عرض تنبيهات حاج معيّن.
--        صفحة notifications.html تعرض تنبيهات مختلفة حسب الدور والقسم.
-- ---------------------------------------------------------------------
CREATE TABLE `notifications` (
  `notification_id` int(11) NOT NULL,
  `supervisor_id` int(11) DEFAULT NULL,
  `campaign_id` int(11) DEFAULT NULL,
  `pilgrim_id` int(11) DEFAULT NULL,
  `target_role` enum('pilgrim','supervisor','campaign','all') NOT NULL DEFAULT 'all',
  `target_section` enum('men','women','all') NOT NULL DEFAULT 'all',
  `title` varchar(150) NOT NULL,
  `content` text DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL,
  `icon` varchar(10) DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `sent_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- جدول `chat_rooms` — غرف المحادثة
-- الأعمدة المضافة: room_name, campaign_id, section
-- وحُذف الارتباط الإجباري بحاج واحد (pilgrim_id) لأن الغرفة جماعية.
-- السبب: chat.html فيه تبويبات غرف (غرفة عامة / غرفة المشرف ...)
--        والغرفة الواحدة فيها أكثر من مشارك.
-- ---------------------------------------------------------------------
CREATE TABLE `chat_rooms` (
  `room_id` int(11) NOT NULL,
  `campaign_id` int(11) NOT NULL,
  `room_name` varchar(100) NOT NULL,
  `section` enum('men','women','all') NOT NULL DEFAULT 'all',
  `staff_only` tinyint(1) NOT NULL DEFAULT 0,
  `message_type` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- جدول `messages` — الرسائل   ** جدول جديد **
-- السبب: الجدول الأصلي chat_rooms لا يحتوي على نص الرسالة ولا المُرسِل
--        ولا وقت الإرسال، فكانت المحادثة غير قابلة للتشغيل إطلاقاً.
-- ---------------------------------------------------------------------
CREATE TABLE `messages` (
  `message_id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL,
  `sender_type` enum('pilgrim','supervisor','campaign') NOT NULL,
  `sender_id` int(11) NOT NULL,
  `sender_name` varchar(100) DEFAULT NULL,
  `message_text` text NOT NULL,
  `sent_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- جدول `expenses` — القيود والمصروفات المالية   ** جدول جديد **
-- السبب: صفحة expenses.html فيها نموذج حفظ قيد مالي كامل،
--        و admin-campaign.html يعتمدها (اعتماد نهائي)،
--        و admin-supervisor.html يعرضها. لم يكن لها أي جدول في الملف الأصلي.
-- ---------------------------------------------------------------------
CREATE TABLE `expenses` (
  `expense_id` int(11) NOT NULL,
  `campaign_id` int(11) NOT NULL,
  `supervisor_id` int(11) DEFAULT NULL,
  `description` varchar(255) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `category` varchar(80) DEFAULT NULL,
  `expense_date` date DEFAULT NULL,
  `receipt_file` varchar(255) DEFAULT NULL,
  `status` enum('مرحّل','معتمد') NOT NULL DEFAULT 'مرحّل',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- جدول `supervisor_tasks` — مهام المشرف   ** جدول جديد **
-- السبب: admin-supervisor.html فيه جدول مهام مع زر "تحديث" للحالة،
--        وبدون جدول يبقى الزر بلا حفظ.
-- (اختياري: إذا لم تريدي حفظ حالة المهام احذفي هذا الجدول وملف api/tasks.php)
-- ---------------------------------------------------------------------
CREATE TABLE `supervisor_tasks` (
  `task_id` int(11) NOT NULL,
  `supervisor_id` int(11) NOT NULL,
  `title` varchar(150) NOT NULL,
  `description` text DEFAULT NULL,
  `status` varchar(50) NOT NULL DEFAULT 'نشط'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =====================================================================
--  المفاتيح والفهارس
-- =====================================================================

ALTER TABLE `campaigns`
  ADD PRIMARY KEY (`campaign_id`);

ALTER TABLE `jobs`
  ADD PRIMARY KEY (`job_id`),
  ADD UNIQUE KEY `role_key` (`role_key`);

ALTER TABLE `supervisors`
  ADD PRIMARY KEY (`supervisor_id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `fk_supervisor_campaign` (`campaign_id`),
  ADD KEY `fk_supervisor_job` (`job_id`);

ALTER TABLE `pilgrims`
  ADD PRIMARY KEY (`pilgrim_id`),
  ADD UNIQUE KEY `booking_number` (`booking_number`),
  ADD UNIQUE KEY `id_or_passport` (`id_or_passport`),
  ADD KEY `fk_pilgrim_campaign` (`campaign_id`),
  ADD KEY `fk_pilgrim_supervisor` (`supervisor_id`);

ALTER TABLE `services`
  ADD PRIMARY KEY (`service_id`);

ALTER TABLE `service_provisions`
  ADD PRIMARY KEY (`provision_id`),
  ADD KEY `fk_prov_pilgrim` (`pilgrim_id`),
  ADD KEY `fk_prov_service` (`service_id`),
  ADD KEY `fk_prov_supervisor` (`supervisor_id`);

ALTER TABLE `ratings`
  ADD PRIMARY KEY (`rating_id`),
  ADD KEY `fk_rating_pilgrim` (`pilgrim_id`),
  ADD KEY `fk_rating_service` (`service_id`),
  ADD KEY `fk_rating_provision` (`provision_id`);

ALTER TABLE `permissions`
  ADD PRIMARY KEY (`permission_id`),
  ADD KEY `fk_perm_campaign` (`campaign_id`),
  ADD KEY `fk_perm_pilgrim` (`pilgrim_id`);

ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `fk_notif_supervisor` (`supervisor_id`),
  ADD KEY `fk_notif_campaign` (`campaign_id`),
  ADD KEY `fk_notif_pilgrim` (`pilgrim_id`);

ALTER TABLE `chat_rooms`
  ADD PRIMARY KEY (`room_id`),
  ADD KEY `fk_room_campaign` (`campaign_id`);

ALTER TABLE `messages`
  ADD PRIMARY KEY (`message_id`),
  ADD KEY `fk_msg_room` (`room_id`);

ALTER TABLE `expenses`
  ADD PRIMARY KEY (`expense_id`),
  ADD KEY `fk_exp_campaign` (`campaign_id`),
  ADD KEY `fk_exp_supervisor` (`supervisor_id`);

ALTER TABLE `supervisor_tasks`
  ADD PRIMARY KEY (`task_id`),
  ADD KEY `fk_task_supervisor` (`supervisor_id`);


-- =====================================================================
--  الترقيم التلقائي
--  ملاحظة: pilgrim_id يبدأ من 100105 حتى يبقى رقم العضوية بصيغة 100xxx
--          كما تتوقعه صفحة تسجيل الدخول.
-- =====================================================================

ALTER TABLE `jobs`
  MODIFY `job_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `services`
  MODIFY `service_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `service_provisions`
  MODIFY `provision_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `ratings`
  MODIFY `rating_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `permissions`
  MODIFY `permission_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `notifications`
  MODIFY `notification_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `chat_rooms`
  MODIFY `room_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `messages`
  MODIFY `message_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `expenses`
  MODIFY `expense_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `supervisor_tasks`
  MODIFY `task_id` int(11) NOT NULL AUTO_INCREMENT;


-- =====================================================================
--  قيود المفاتيح الأجنبية
-- =====================================================================

ALTER TABLE `supervisors`
  ADD CONSTRAINT `fk_supervisor_campaign` FOREIGN KEY (`campaign_id`) REFERENCES `campaigns` (`campaign_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_supervisor_job` FOREIGN KEY (`job_id`) REFERENCES `jobs` (`job_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `pilgrims`
  ADD CONSTRAINT `fk_pilgrim_campaign` FOREIGN KEY (`campaign_id`) REFERENCES `campaigns` (`campaign_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_pilgrim_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `supervisors` (`supervisor_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `service_provisions`
  ADD CONSTRAINT `fk_prov_pilgrim` FOREIGN KEY (`pilgrim_id`) REFERENCES `pilgrims` (`pilgrim_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_prov_service` FOREIGN KEY (`service_id`) REFERENCES `services` (`service_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_prov_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `supervisors` (`supervisor_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `ratings`
  ADD CONSTRAINT `fk_rating_pilgrim` FOREIGN KEY (`pilgrim_id`) REFERENCES `pilgrims` (`pilgrim_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_rating_service` FOREIGN KEY (`service_id`) REFERENCES `services` (`service_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_rating_provision` FOREIGN KEY (`provision_id`) REFERENCES `service_provisions` (`provision_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `permissions`
  ADD CONSTRAINT `fk_perm_campaign` FOREIGN KEY (`campaign_id`) REFERENCES `campaigns` (`campaign_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_perm_pilgrim` FOREIGN KEY (`pilgrim_id`) REFERENCES `pilgrims` (`pilgrim_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notif_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `supervisors` (`supervisor_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_notif_campaign` FOREIGN KEY (`campaign_id`) REFERENCES `campaigns` (`campaign_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_notif_pilgrim` FOREIGN KEY (`pilgrim_id`) REFERENCES `pilgrims` (`pilgrim_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `chat_rooms`
  ADD CONSTRAINT `fk_room_campaign` FOREIGN KEY (`campaign_id`) REFERENCES `campaigns` (`campaign_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `messages`
  ADD CONSTRAINT `fk_msg_room` FOREIGN KEY (`room_id`) REFERENCES `chat_rooms` (`room_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `expenses`
  ADD CONSTRAINT `fk_exp_campaign` FOREIGN KEY (`campaign_id`) REFERENCES `campaigns` (`campaign_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_exp_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `supervisors` (`supervisor_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `supervisor_tasks`
  ADD CONSTRAINT `fk_task_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `supervisors` (`supervisor_id`) ON DELETE CASCADE ON UPDATE CASCADE;


-- =====================================================================
--  بيانات تجريبية للمناقشة
--  كلمات المرور (نص صريح — غيّريها بعد التسليم):
--    الحجاج     : Hajj@1234
--    المشرفون   : Sup@1234
--    مدير الحملة: Admin@1234
--  مخزّنة في قاعدة البيانات مشفّرة بـ bcrypt عبر password_hash()
-- =====================================================================

INSERT INTO `campaigns`
  (`campaign_id`,`campaign_name`,`license_number`,`phone`,`location`,`extra_info`,
   `company_name`,`manager_name`,`manager_email`,`manager_phone`,
   `price_per_person`,`start_city`,`start_date`,`password_hash`) VALUES
(30089, 'رفقة بلاد الحرمين', 'LIC-2026-30089', '0126000000', 'مكة المكرمة - العزيزية',
 'حملة حج وعمرة تخدم قسمي الرجال والنساء.',
 'Belad Alharamain Co. Hajj & Umrah L.C.C', 'خالد العتيبي', 'manager@rafqa.sa', '0501234567',
 8500.00, 'جدة', '2026-05-20',
 '$2y$10$d..u7tTdhiLeOqYRyNo4oO4T3ZZPWW2RY4KEgl1LYCOvbwZ6B6Gla');

INSERT INTO `jobs` (`job_id`,`job_title`,`permission_level`,`role_key`) VALUES
(1, 'مشرف عام',                  'متابعة شاملة لكل التخصصات والأقسام', 'general'),
(2, 'الموظف الصحي',              'الحالات الصحية والطلبات الطبية',      'medical'),
(3, 'موظف الحشود والتنقل',        'التفويج وحركة الحافلات',             'crowd'),
(4, 'موظف الإعاشة والأطعمة',      'الوجبات والاحتياجات الغذائية',        'catering'),
(5, 'موظف السكن وخدمة الحجاج',    'الخيام والأسرّة وصيانة المخيم',        'housing');

INSERT INTO `supervisors`
  (`supervisor_id`,`campaign_id`,`job_id`,`name`,`phone`,`email`,`gender_section`,`password_hash`) VALUES
(5000,   30089, 1, 'سعد الشهري',   '0551000000', 'general@rafqa.sa',  'all',
 '$2y$10$AnwyS.2J5sT03vQ/IibFRu4.eDJgebet/cmg5Pz4VPXDJZcvE.YNa'),
(500101, 30089, 2, 'أحمد الزهراني','0551000101', 'med.m@rafqa.sa',    'men',
 '$2y$10$AnwyS.2J5sT03vQ/IibFRu4.eDJgebet/cmg5Pz4VPXDJZcvE.YNa'),
(500102, 30089, 3, 'ماجد الحارثي', '0551000102', 'crowd.m@rafqa.sa',  'men',
 '$2y$10$AnwyS.2J5sT03vQ/IibFRu4.eDJgebet/cmg5Pz4VPXDJZcvE.YNa'),
(500103, 30089, 4, 'فهد العمري',   '0551000103', 'cater.m@rafqa.sa',  'men',
 '$2y$10$AnwyS.2J5sT03vQ/IibFRu4.eDJgebet/cmg5Pz4VPXDJZcvE.YNa'),
(500104, 30089, 5, 'تركي المالكي', '0551000104', 'house.m@rafqa.sa',  'men',
 '$2y$10$AnwyS.2J5sT03vQ/IibFRu4.eDJgebet/cmg5Pz4VPXDJZcvE.YNa'),
(500201, 30089, 2, 'نورة السبيعي', '0551000201', 'med.w@rafqa.sa',    'women',
 '$2y$10$AnwyS.2J5sT03vQ/IibFRu4.eDJgebet/cmg5Pz4VPXDJZcvE.YNa'),
(500202, 30089, 3, 'هند القرني',   '0551000202', 'crowd.w@rafqa.sa',  'women',
 '$2y$10$AnwyS.2J5sT03vQ/IibFRu4.eDJgebet/cmg5Pz4VPXDJZcvE.YNa'),
(500203, 30089, 4, 'لمياء الشمري', '0551000203', 'cater.w@rafqa.sa',  'women',
 '$2y$10$AnwyS.2J5sT03vQ/IibFRu4.eDJgebet/cmg5Pz4VPXDJZcvE.YNa'),
(500204, 30089, 5, 'عبير الدوسري', '0551000204', 'house.w@rafqa.sa',  'women',
 '$2y$10$AnwyS.2J5sT03vQ/IibFRu4.eDJgebet/cmg5Pz4VPXDJZcvE.YNa');

INSERT INTO `pilgrims`
  (`pilgrim_id`,`campaign_id`,`supervisor_id`,`booking_number`,`name`,`id_or_passport`,
   `phone`,`nationality`,`age`,`city`,`package_type`,`gathering_point`,
   `tent_number`,`bed_number`,`password_hash`,`gender`,`email`,`marital_status`,
   `chronic_conditions`,`camp_id`) VALUES
(100101, 30089, 500101, 'BK-2026-0001', 'عبدالرحمن القحطاني', '1012345678',
 '0551110001', 'Saudi Arabia', 52, 'Jeddah', 'باقة شاملة', 'نقطة تجمع جدة',
 'خيمة رجال ب1', '3', '$2y$10$wVwRqDskYQhQG75.2Yfq5.zWMu8Ywl7u1y.4lQeKBa/1eZDlmBuc2',
 'male', 'abdulrahman@example.com', 'متزوج', 'السكري', 'CAMP-101'),
(100102, 30089, 500102, 'BK-2026-0002', 'إبراهيم الدوسري', '1022345678',
 '0551110002', 'Saudi Arabia', 45, 'Riyadh', 'باقة اقتصادية', 'نقطة تجمع الرياض',
 'خيمة رجال ب2', '8', '$2y$10$wVwRqDskYQhQG75.2Yfq5.zWMu8Ywl7u1y.4lQeKBa/1eZDlmBuc2',
 'male', 'ibrahim@example.com', 'متزوج', 'ضغط الدم', 'CAMP-101'),
(100201, 30089, 500201, 'BK-2026-0003', 'سارة الحربي', '2012345678',
 '0551110003', 'Saudi Arabia', 39, 'Makkah', 'باقة شاملة', 'نقطة تجمع مكة',
 'خيمة نساء أ1', '5', '$2y$10$wVwRqDskYQhQG75.2Yfq5.zWMu8Ywl7u1y.4lQeKBa/1eZDlmBuc2',
 'female', 'sarah@example.com', 'متزوجة', 'لا يوجد', 'CAMP-201'),
(100202, 30089, 500203, 'BK-2026-0004', 'مريم الغامدي', '2022345678',
 '0551110004', 'Egypt', 47, 'Cairo', 'باقة شاملة', 'نقطة تجمع القاهرة',
 'خيمة نساء أ2', '12', '$2y$10$wVwRqDskYQhQG75.2Yfq5.zWMu8Ywl7u1y.4lQeKBa/1eZDlmBuc2',
 'female', 'maryam@example.com', 'أرملة', 'السكري', 'CAMP-201');

ALTER TABLE `pilgrims`
  MODIFY `pilgrim_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=100203;

INSERT INTO `permissions`
  (`campaign_id`,`pilgrim_id`,`permission_name`,`description`,`permission_type`) VALUES
(30089, 100101, '34567890', 'تصريح حج صادر عبر مسار', 'تصريح حج'),
(30089, 100102, '34567891', 'تصريح حج صادر عبر مسار', 'تصريح حج'),
(30089, 100201, '98765432', 'تصريح حج صادر عبر مسار', 'تصريح حج'),
(30089, 100202, '98765433', 'تصريح حج صادر عبر مسار', 'تصريح حج');

INSERT INTO `services`
  (`service_id`,`service_name`,`description`,`service_type`,`service_datetime`,`service_location`,`status`) VALUES
(1, 'الرعاية الطبية',   'عيادة ميدانية وطاقم طبي داخل المخيم',  'medical',  '2026-05-21 08:00:00', 'مخيم منى', 'متاحة'),
(2, 'التفويج والحافلات','تنظيم حركة الحجاج بين المشاعر',        'crowd',    '2026-05-21 05:00:00', 'نقطة التجمع', 'متاحة'),
(3, 'الإعاشة والوجبات', 'ثلاث وجبات يومية مع وجبات خاصة',       'catering', '2026-05-21 12:00:00', 'مطعم المخيم', 'متاحة'),
(4, 'السكن والخيام',    'تسكين الحجاج وصيانة مرافق المخيم',     'housing',  '2026-05-20 16:00:00', 'مخيم منى', 'متاحة'),
(5, 'الأمتعة المفقودة', 'استقبال بلاغات الأمتعة المفقودة',      'housing',  NULL, 'مكتب خدمة الحجاج', 'متاحة'),
(6, 'الخدمات العامة بالحملة',     'التقييم العام لتجربة الحاج مع الحملة',  'general',  NULL, NULL, 'متاحة'),
(7, 'تعامل المشرفين والمرشدين',  'تقييم تعامل الطاقم الميداني',           'general',  NULL, NULL, 'متاحة');

INSERT INTO `service_provisions`
  (`pilgrim_id`,`service_id`,`supervisor_id`,`request_number`,`details`,`provision_date`,`provision_time`,`status`) VALUES
(100101, 1, 500101, 'MED-101', 'طلب استشارة وفحص ضغط',        '2026-05-21', '09:15:00', 'قيد المباشرة'),
(100102, 1, 500101, 'MED-102', 'صرف أدوية السكري',            '2026-05-21', '10:30:00', 'مكتمل'),
(100101, 2, 500102, 'CRD-201', 'تنسيق موعد ركوب حافلة منى',   '2026-05-21', '05:30:00', 'مجدول'),
(100102, 2, 500102, 'CRD-202', 'توجيه المسار البديل',         '2026-05-21', '06:00:00', 'معتمد'),
(100201, 3, 500203, 'CAT-301', 'وجبة خالية من السكر',         '2026-05-21', '12:30:00', 'قيد التجهيز'),
(100202, 3, 500203, 'CAT-302', 'توزيع وجبة الغداء للخيمة',    '2026-05-21', '13:00:00', 'مكتمل'),
(100201, 4, 500204, 'HOU-401', 'إصلاح وحدة التكييف بالمخيم',  '2026-05-20', '17:00:00', 'قيد المتابعة'),
(100202, 4, 500204, 'HOU-402', 'تسكين بجانب المرافق',         '2026-05-20', '18:00:00', 'مكتمل');

INSERT INTO `ratings` (`pilgrim_id`,`service_id`,`provision_id`,`stars`,`comment`) VALUES
(100101, 1, 1,    5, 'خدمة ممتازة واهتمام عالي بمرضى السكري والوجبات.'),
(100102, 2, 4,    4, 'التفويج منظم جداً ونقترح زيادة عدد حافلات العودة.'),
(100201, 3, 5,    5, 'تعامل مشرفة المخيم راقي جداً والتنظيم في منى رائع.'),
(100201, 4, 7,    4, 'الصيانة وصلت بسرعة، شكراً لكم.'),
(100202, 7, NULL, 5, 'المشرفات متعاونات جداً وسريعات الاستجابة.');

INSERT INTO `expenses`
  (`campaign_id`,`supervisor_id`,`description`,`amount`,`category`,`expense_date`,`receipt_file`,`status`) VALUES
(30089, 500101, 'توفير أدوات إسعافات أولية ومطهرات',      2800.00, 'مستلزمات طبية',  '2026-05-18', NULL, 'معتمد'),
(30089, 500101, 'شراء أدوية طارئة للأمراض المزمنة',       1500.00, 'أدوية وعلاجات',  '2026-05-19', NULL, 'مرحّل'),
(30089, 500102, 'تأجير عربات تنقل وحشود ميدانية',          4500.00, 'تنقل وحشود',     '2026-05-18', NULL, 'معتمد'),
(30089, 500102, 'لوحات إرشادية لمسارات التفويج',           1200.00, 'تنظيم إرشادي',   '2026-05-20', NULL, 'مرحّل'),
(30089, 500103, 'شراء وجبات إضافية ومشروبات طازجة',        3400.00, 'وجبات وإعاشة',   '2026-05-18', NULL, 'معتمد'),
(30089, 500104, 'صيانة وحدات التكييف والإنارة بالخيمة',    5000.00, 'صيانة سكن',      '2026-05-17', NULL, 'مرحّل');

INSERT INTO `supervisor_tasks` (`supervisor_id`,`title`,`description`,`status`) VALUES
(5000,   'متابعة الحالات الصحية للحجاج',   'الإشراف على التقارير الصحية والأمراض المزمنة.', 'نشط'),
(5000,   'تنظيم حركة الحجاج والمجموعات',   'مراقبة وتوجيه تفويج الحشود والحافلات.',        'مجدول'),
(5000,   'تنظيم وجبات الإعاشة والأطعمة',    'متابعة توزيع الوجبات والاحتياجات الغذائية.',   'معتمد'),
(5000,   'إدارة بيانات الغرف والسكن',       'متابعة أسماء وتسكين الحجاج في المخيمات.',      'مكتمل'),
(500101, 'متابعة الحالات الصحية للحجاج',   'الاطلاع على التقارير الصحية ومتابعة الأمراض المزمنة.', 'نشط'),
(500101, 'تسجيل طلبات الرعاية الطبية',     'استقبال وإدخال طلبات الكشف والأدوية للحجاج.',  'قيد المتابعة'),
(500101, 'متابعة الحالات الطارئة والإحالات','التنسيق السريع لحالات الطوارئ والإحالة للمستشفيات.', 'جاهز'),
(500102, 'تنظيم حركة الحجاج والمجموعات',   'توجيه وتنظيم تفويج المجموعات الميدانية.',      'مجدول'),
(500102, 'متابعة المخيم والحافلات',        'مراقبة مواعيد حركات الحافلات والمخيمات.',      'قيد المتابعة'),
(500103, 'تنظيم الفطور والغداء والعشاء',   'جدولة وتنظيم مواقيت وجبات الإعاشة اليومية.',   'معتمد'),
(500103, 'متابعة توزيع الوجبات حسب المخيم','الإشراف على وصول الوجبات وتوزيعها للخيام.',    'جاري التوزيع'),
(500104, 'متابعة أسماء الحجاج في المخيم',  'التحقق من كشوفات الأسماء وتوزيع الخيام.',      'مكتمل'),
(500104, 'إدارة بيانات الغرف والسكن',      'توزيع الأسرّة ومتابعة مواقع السكن بمكة ومنى.', 'مرتب'),
(500201, 'متابعة الحالات الصحية للحاجات',  'الاطلاع على التقارير الصحية لقسم النساء.',     'نشط'),
(500202, 'تنظيم حركة الحاجات والمجموعات',  'توجيه وتنظيم تفويج مجموعات النساء.',           'مجدول'),
(500203, 'تنظيم وجبات قسم النساء',         'متابعة توزيع الوجبات على خيام النساء.',        'معتمد'),
(500204, 'إدارة تسكين قسم النساء',         'توزيع الأسرّة في مخيم النساء.',                 'مكتمل');

INSERT INTO `chat_rooms` (`room_id`,`campaign_id`,`room_name`,`section`,`staff_only`,`message_type`) VALUES
(1, 30089, 'الغرفة العامة',                   'all',   0, 'عام'),
(2, 30089, 'قسم الرجال (مع مشرف الرجال)',    'men',   0, 'قسم'),
(3, 30089, 'قسم النساء (مع مشرفة النساء)',   'women', 0, 'قسم'),
(4, 30089, 'غرفة المشرفين وإدارة الحملة',    'all',   1, 'إشراف');

INSERT INTO `messages` (`room_id`,`sender_type`,`sender_id`,`sender_name`,`message_text`) VALUES
(1, 'supervisor', 5000,   'غرفة العمليات',       'أهلاً بكم في الغرفة العامة، أي استفسار نحن في الخدمة.'),
(1, 'pilgrim',    100101, 'عبدالرحمن القحطاني', 'السلام عليكم، متى موعد انطلاق حافلة منى؟'),
(1, 'supervisor', 500102, 'ماجد الحارثي',        'وعليكم السلام، الانطلاق الساعة 5:00 مساءً من نقطة التجمع.'),
(2, 'supervisor', 500101, 'أحمد الزهراني',       'تم رفع تقرير الحالات الصحية لليوم.'),
(3, 'supervisor', 500201, 'نورة السبيعي',        'تم تأكيد اكتمال التسكين في مخيم النساء ب2.');

INSERT INTO `notifications`
  (`supervisor_id`,`campaign_id`,`pilgrim_id`,`target_role`,`target_section`,`title`,`content`,`type`,`icon`) VALUES
(5000, 30089, NULL, 'campaign',   'all',   'قيد مالي جديد بانتظار الترحيل',
 'تم رفع قيد مصروفات جديد ومستند الفاتورة مرفق.', 'مالي', '🧾'),
(500102, 30089, NULL, 'supervisor','men',   'جدول تفويج حافلات الرجال',
 'موعد انطلاق حافلة الرجال رقم 3 إلى الحرم الساعة 5:00 م.', 'تفويج', '🚌'),
(500201, 30089, NULL, 'supervisor','women', 'تحديث تسكين الخيام النسائية',
 'تم تأكيد اكتمال التسكين في مخيم النساء ب2.', 'سكن', '⛺'),
(500101, 30089, 100101, 'pilgrim', 'men',   'تذكير بموعد المراجعة الطبية',
 'لديك موعد مراجعة في العيادة الميدانية الساعة 9:00 صباحاً.', 'طبي', '🩺'),
(500203, 30089, 100201, 'pilgrim', 'women', 'وجبتك الخاصة جاهزة',
 'تم تجهيز الوجبة الخالية من السكر، يمكنك استلامها من مطعم المخيم.', 'إعاشة', '🍽️'),
(5000, 30089, NULL, 'all', 'all', 'تعليمات السلامة في المشاعر',
 'يرجى الالتزام بتعليمات المشرفين وحمل بطاقة التصريح دائماً.', 'عام', '📢');

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
