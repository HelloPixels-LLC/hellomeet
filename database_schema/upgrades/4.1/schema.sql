SET @group_logo_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'groups' AND COLUMN_NAME = 'logo_filename');
SET @group_logo_sql := IF(@group_logo_exists = 0, 'ALTER TABLE `groups` ADD COLUMN `logo_filename` VARCHAR(255) NULL DEFAULT NULL', 'SELECT 1');
PREPARE stmt FROM @group_logo_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @display_group_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'display_group_id');
SET @display_group_sql := IF(@display_group_exists = 0, 'ALTER TABLE `users` ADD COLUMN `display_group_id` SMALLINT(5) UNSIGNED NULL DEFAULT NULL', 'SELECT 1');
PREPARE stmt FROM @display_group_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @display_group_fk_exists := (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND CONSTRAINT_NAME = 'fk_users_display_group' AND CONSTRAINT_TYPE = 'FOREIGN KEY');
SET @display_group_fk_sql := IF(@display_group_fk_exists = 0, 'ALTER TABLE `users` ADD CONSTRAINT `fk_users_display_group` FOREIGN KEY (`display_group_id`) REFERENCES `groups` (`group_id`) ON UPDATE CASCADE ON DELETE SET NULL', 'SELECT 1');
PREPARE stmt FROM @display_group_fk_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
