-- ================================================================
-- Jarvis ToDo App - MySQL Database Schema
-- ================================================================
-- 版本: 1.0
-- 创建日期: 2024-08-17
-- 描述: Jarvis 待办应用完整数据库表结构
-- 功能支持: 用户管理、清单、任务、子任务、标签、提醒、同步等
-- ================================================================

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;

-- 创建数据库
CREATE DATABASE IF NOT EXISTS `jarvis_todo` 
DEFAULT CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `jarvis_todo`;

-- ================================================================
-- 1. 用户和认证相关表
-- ================================================================

-- 用户表
CREATE TABLE `users` (
    `id` CHAR(36) NOT NULL PRIMARY KEY COMMENT '用户UUID',
    `email` VARCHAR(255) NOT NULL UNIQUE COMMENT '用户邮箱',
    `username` VARCHAR(100) NOT NULL COMMENT '用户名',
    `password_hash` VARCHAR(255) NOT NULL COMMENT '密码哈希',
    `avatar_url` VARCHAR(500) NULL COMMENT '头像URL',
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '账户是否激活',
    `email_verified` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '邮箱是否验证',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `last_login_at` TIMESTAMP NULL COMMENT '最后登录时间',
    `timezone` VARCHAR(50) DEFAULT 'UTC' COMMENT '用户时区',
    INDEX `idx_email` (`email`),
    INDEX `idx_username` (`username`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 用户设置表
CREATE TABLE `user_settings` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` CHAR(36) NOT NULL COMMENT '用户ID',
    `sync_enabled` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '同步是否启用',
    `default_reminder_minutes` INT NOT NULL DEFAULT 15 COMMENT '默认提醒时间(分钟)',
    `default_list_id` CHAR(36) NULL COMMENT '默认清单ID',
    `theme` TINYINT NOT NULL DEFAULT 0 COMMENT '主题设置(0:系统,1:浅色,2:深色)',
    `notification_enabled` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '通知是否启用',
    `sound_enabled` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '声音是否启用',
    `auto_add_to_myday` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '新任务自动加入我的一天',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`default_list_id`) REFERENCES `lists`(`id`) ON DELETE SET NULL,
    UNIQUE KEY `uk_user_settings` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户设置表';

-- 用户会话表
CREATE TABLE `user_sessions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` CHAR(36) NOT NULL COMMENT '用户ID',
    `session_token` VARCHAR(255) NOT NULL UNIQUE COMMENT '会话令牌',
    `refresh_token` VARCHAR(255) NOT NULL UNIQUE COMMENT '刷新令牌',
    `device_type` VARCHAR(50) NOT NULL COMMENT '设备类型(iOS/macOS/web)',
    `device_name` VARCHAR(100) NULL COMMENT '设备名称',
    `ip_address` VARCHAR(45) NULL COMMENT 'IP地址',
    `user_agent` TEXT NULL COMMENT '用户代理',
    `expires_at` TIMESTAMP NOT NULL COMMENT '过期时间',
    `last_used_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '最后使用时间',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    INDEX `idx_session_token` (`session_token`),
    INDEX `idx_user_device` (`user_id`, `device_type`),
    INDEX `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户会话表';

-- ================================================================
-- 2. 清单管理相关表
-- ================================================================

-- 清单表
CREATE TABLE `lists` (
    `id` CHAR(36) NOT NULL PRIMARY KEY COMMENT '清单UUID',
    `user_id` CHAR(36) NOT NULL COMMENT '所属用户ID',
    `name` VARCHAR(255) NOT NULL COMMENT '清单名称',
    `icon` VARCHAR(100) NULL COMMENT '图标名称',
    `color` VARCHAR(7) NULL COMMENT '颜色(hex格式)',
    `is_system` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否系统清单',
    `sort_index` INT NOT NULL DEFAULT 0 COMMENT '排序索引',
    `is_shared` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否共享清单',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    INDEX `idx_user_lists` (`user_id`, `is_system`),
    INDEX `idx_sort_index` (`sort_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='清单表';

-- ================================================================
-- 3. 任务管理相关表
-- ================================================================

-- 任务表
CREATE TABLE `tasks` (
    `id` CHAR(36) NOT NULL PRIMARY KEY COMMENT '任务UUID',
    `user_id` CHAR(36) NOT NULL COMMENT '所属用户ID',
    `list_id` CHAR(36) NOT NULL COMMENT '所属清单ID',
    `title` VARCHAR(500) NOT NULL COMMENT '任务标题',
    `notes` TEXT NULL COMMENT '任务备注',
    `due_date` TIMESTAMP NULL COMMENT '截止日期',
    `reminder_date` TIMESTAMP NULL COMMENT '提醒时间',
    `is_completed` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否完成',
    `completed_at` TIMESTAMP NULL COMMENT '完成时间',
    `is_important` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否重要',
    `is_my_day` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否在我的一天',
    `repeat_rule` JSON NULL COMMENT '重复规则(JSON格式)',
    `sort_index` BIGINT NOT NULL DEFAULT 0 COMMENT '排序索引',
    `parent_task_id` CHAR(36) NULL COMMENT '父任务ID(用于子任务)',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`list_id`) REFERENCES `lists`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`parent_task_id`) REFERENCES `tasks`(`id`) ON DELETE CASCADE,
    INDEX `idx_user_tasks` (`user_id`, `is_completed`),
    INDEX `idx_list_tasks` (`list_id`, `sort_index`),
    INDEX `idx_due_date` (`due_date`),
    INDEX `idx_reminder_date` (`reminder_date`),
    INDEX `idx_important` (`is_important`, `is_completed`),
    INDEX `idx_my_day` (`is_my_day`, `is_completed`),
    INDEX `idx_parent_task` (`parent_task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务表';

-- 子任务/步骤表
CREATE TABLE `task_steps` (
    `id` CHAR(36) NOT NULL PRIMARY KEY COMMENT '步骤UUID',
    `task_id` CHAR(36) NOT NULL COMMENT '所属任务ID',
    `title` VARCHAR(500) NOT NULL COMMENT '步骤标题',
    `is_completed` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否完成',
    `sort_index` INT NOT NULL DEFAULT 0 COMMENT '排序索引',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`task_id`) REFERENCES `tasks`(`id`) ON DELETE CASCADE,
    INDEX `idx_task_steps` (`task_id`, `sort_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务步骤表';

-- ================================================================
-- 4. 标签系统相关表
-- ================================================================

-- 标签表
CREATE TABLE `tags` (
    `id` CHAR(36) NOT NULL PRIMARY KEY COMMENT '标签UUID',
    `user_id` CHAR(36) NOT NULL COMMENT '所属用户ID',
    `name` VARCHAR(100) NOT NULL COMMENT '标签名称',
    `color` VARCHAR(7) NULL COMMENT '标签颜色',
    `usage_count` INT NOT NULL DEFAULT 0 COMMENT '使用次数',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_user_tag` (`user_id`, `name`),
    INDEX `idx_usage_count` (`usage_count` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='标签表';

-- 任务标签关联表
CREATE TABLE `task_tags` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `task_id` CHAR(36) NOT NULL COMMENT '任务ID',
    `tag_id` CHAR(36) NOT NULL COMMENT '标签ID',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`task_id`) REFERENCES `tasks`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`tag_id`) REFERENCES `tags`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_task_tag` (`task_id`, `tag_id`),
    INDEX `idx_tag_tasks` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务标签关联表';

-- ================================================================
-- 5. 通知和提醒相关表
-- ================================================================

-- 通知记录表
CREATE TABLE `notifications` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` CHAR(36) NOT NULL COMMENT '用户ID',
    `task_id` CHAR(36) NULL COMMENT '关联任务ID',
    `type` VARCHAR(50) NOT NULL COMMENT '通知类型(reminder/due/shared等)',
    `title` VARCHAR(255) NOT NULL COMMENT '通知标题',
    `body` TEXT NULL COMMENT '通知内容',
    `scheduled_at` TIMESTAMP NOT NULL COMMENT '计划发送时间',
    `sent_at` TIMESTAMP NULL COMMENT '实际发送时间',
    `status` ENUM('pending', 'sent', 'failed', 'cancelled') NOT NULL DEFAULT 'pending' COMMENT '发送状态',
    `device_tokens` JSON NULL COMMENT '设备推送令牌',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`task_id`) REFERENCES `tasks`(`id`) ON DELETE CASCADE,
    INDEX `idx_user_notifications` (`user_id`, `status`),
    INDEX `idx_scheduled_at` (`scheduled_at`),
    INDEX `idx_task_notifications` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通知记录表';

-- ================================================================
-- 6. 同步和版本控制相关表
-- ================================================================

-- 数据同步日志表
CREATE TABLE `sync_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` CHAR(36) NOT NULL COMMENT '用户ID',
    `entity_type` VARCHAR(50) NOT NULL COMMENT '实体类型(task/list/tag等)',
    `entity_id` CHAR(36) NOT NULL COMMENT '实体ID',
    `action` VARCHAR(20) NOT NULL COMMENT '操作类型(create/update/delete)',
    `device_id` VARCHAR(255) NULL COMMENT '设备标识',
    `sync_version` BIGINT NOT NULL COMMENT '同步版本号',
    `data_snapshot` JSON NULL COMMENT '数据快照',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    INDEX `idx_user_sync` (`user_id`, `sync_version`),
    INDEX `idx_entity_sync` (`entity_type`, `entity_id`),
    INDEX `idx_device_sync` (`device_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='数据同步日志表';

-- 用户同步状态表
CREATE TABLE `user_sync_status` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` CHAR(36) NOT NULL COMMENT '用户ID',
    `device_id` VARCHAR(255) NOT NULL COMMENT '设备标识',
    `last_sync_version` BIGINT NOT NULL DEFAULT 0 COMMENT '最后同步版本',
    `last_sync_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '最后同步时间',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_user_device` (`user_id`, `device_id`),
    INDEX `idx_last_sync` (`last_sync_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户同步状态表';

-- ================================================================
-- 7. 审计和日志相关表
-- ================================================================

-- 操作审计日志表
CREATE TABLE `audit_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` CHAR(36) NULL COMMENT '操作用户ID',
    `action` VARCHAR(100) NOT NULL COMMENT '操作类型',
    `resource_type` VARCHAR(50) NOT NULL COMMENT '资源类型',
    `resource_id` CHAR(36) NULL COMMENT '资源ID',
    `old_values` JSON NULL COMMENT '变更前数据',
    `new_values` JSON NULL COMMENT '变更后数据',
    `ip_address` VARCHAR(45) NULL COMMENT 'IP地址',
    `user_agent` TEXT NULL COMMENT '用户代理',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL,
    INDEX `idx_user_audit` (`user_id`, `created_at`),
    INDEX `idx_resource_audit` (`resource_type`, `resource_id`),
    INDEX `idx_action_audit` (`action`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='操作审计日志表';

-- ================================================================
-- 8. 系统配置和元数据表
-- ================================================================

-- 系统配置表
CREATE TABLE `system_configs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `config_key` VARCHAR(100) NOT NULL UNIQUE COMMENT '配置键',
    `config_value` TEXT NOT NULL COMMENT '配置值',
    `description` VARCHAR(255) NULL COMMENT '配置描述',
    `is_public` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否公开配置',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表';

-- 数据库版本信息表
CREATE TABLE `schema_versions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `version` VARCHAR(20) NOT NULL UNIQUE COMMENT '版本号',
    `description` TEXT NULL COMMENT '版本描述',
    `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '应用时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='数据库版本信息表';

-- ================================================================
-- 9. 创建视图 (Views)
-- ================================================================

-- 用户任务统计视图
CREATE VIEW `v_user_task_stats` AS
SELECT 
    u.id as user_id,
    u.username,
    COUNT(t.id) as total_tasks,
    COUNT(CASE WHEN t.is_completed = 1 THEN 1 END) as completed_tasks,
    COUNT(CASE WHEN t.is_completed = 0 THEN 1 END) as pending_tasks,
    COUNT(CASE WHEN t.is_important = 1 AND t.is_completed = 0 THEN 1 END) as important_pending,
    COUNT(CASE WHEN t.is_my_day = 1 AND t.is_completed = 0 THEN 1 END) as my_day_pending,
    COUNT(CASE WHEN t.due_date IS NOT NULL AND t.is_completed = 0 THEN 1 END) as scheduled_pending,
    COUNT(CASE WHEN t.due_date < NOW() AND t.is_completed = 0 THEN 1 END) as overdue_tasks
FROM users u
LEFT JOIN tasks t ON u.id = t.user_id
GROUP BY u.id, u.username;

-- 清单任务统计视图
CREATE VIEW `v_list_task_stats` AS
SELECT 
    l.id as list_id,
    l.name as list_name,
    l.user_id,
    COUNT(t.id) as total_tasks,
    COUNT(CASE WHEN t.is_completed = 1 THEN 1 END) as completed_tasks,
    COUNT(CASE WHEN t.is_completed = 0 THEN 1 END) as pending_tasks,
    MAX(t.updated_at) as last_activity_at
FROM lists l
LEFT JOIN tasks t ON l.id = t.list_id
GROUP BY l.id, l.name, l.user_id;

-- ================================================================
-- 10. 创建存储过程 (Stored Procedures)
-- ================================================================

DELIMITER //

-- 清理"我的一天"过期任务的存储过程
CREATE PROCEDURE CleanupMyDayTasks()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- 清除昨天及之前标记为"我的一天"的任务
    UPDATE tasks 
    SET is_my_day = FALSE, updated_at = NOW()
    WHERE is_my_day = TRUE 
    AND DATE(updated_at) < CURDATE();
    
    -- 记录审计日志
    INSERT INTO audit_logs (action, resource_type, old_values, new_values, created_at)
    VALUES ('system_cleanup', 'my_day_tasks', 
            JSON_OBJECT('action', 'cleanup_my_day'),
            JSON_OBJECT('affected_rows', ROW_COUNT()),
            NOW());
    
    COMMIT;
END //

-- 删除用户及其所有相关数据的存储过程
CREATE PROCEDURE DeleteUserData(IN target_user_id CHAR(36))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- 删除顺序很重要，先删除子表数据
    DELETE FROM task_tags WHERE task_id IN (SELECT id FROM tasks WHERE user_id = target_user_id);
    DELETE FROM task_steps WHERE task_id IN (SELECT id FROM tasks WHERE user_id = target_user_id);
    DELETE FROM notifications WHERE user_id = target_user_id;
    DELETE FROM sync_logs WHERE user_id = target_user_id;
    DELETE FROM user_sync_status WHERE user_id = target_user_id;
    DELETE FROM audit_logs WHERE user_id = target_user_id;
    DELETE FROM tasks WHERE user_id = target_user_id;
    DELETE FROM tags WHERE user_id = target_user_id;
    DELETE FROM lists WHERE user_id = target_user_id;
    DELETE FROM user_settings WHERE user_id = target_user_id;
    DELETE FROM user_sessions WHERE user_id = target_user_id;
    DELETE FROM users WHERE id = target_user_id;
    
    COMMIT;
END //

DELIMITER ;

-- ================================================================
-- 11. 创建触发器 (Triggers)
-- ================================================================

-- 更新标签使用次数的触发器
DELIMITER //
CREATE TRIGGER tr_task_tags_insert 
AFTER INSERT ON task_tags
FOR EACH ROW
BEGIN
    UPDATE tags SET usage_count = usage_count + 1 WHERE id = NEW.tag_id;
END //

CREATE TRIGGER tr_task_tags_delete
AFTER DELETE ON task_tags  
FOR EACH ROW
BEGIN
    UPDATE tags SET usage_count = usage_count - 1 WHERE id = OLD.tag_id;
END //
DELIMITER ;

-- 任务完成时间自动设置触发器
DELIMITER //
CREATE TRIGGER tr_tasks_update_completed
BEFORE UPDATE ON tasks
FOR EACH ROW
BEGIN
    IF NEW.is_completed = 1 AND OLD.is_completed = 0 THEN
        SET NEW.completed_at = NOW();
    ELSEIF NEW.is_completed = 0 AND OLD.is_completed = 1 THEN
        SET NEW.completed_at = NULL;
    END IF;
END //
DELIMITER ;

-- ================================================================
-- 12. 插入初始数据
-- ================================================================

-- 插入系统配置
INSERT INTO system_configs (config_key, config_value, description, is_public) VALUES
('app_version', '1.0.0', '应用版本号', TRUE),
('max_tasks_per_user', '10000', '每用户最大任务数', FALSE),
('max_lists_per_user', '100', '每用户最大清单数', FALSE),
('notification_batch_size', '1000', '通知批处理大小', FALSE),
('sync_retention_days', '90', '同步日志保留天数', FALSE);

-- 插入数据库版本信息
INSERT INTO schema_versions (version, description) VALUES
('1.0.0', '初始数据库结构');

-- ================================================================
-- 13. 创建定时事件 (Events)
-- ================================================================

-- 启用事件调度器
SET GLOBAL event_scheduler = ON;

-- 每日清理"我的一天"任务的事件
CREATE EVENT IF NOT EXISTS ev_cleanup_my_day
ON SCHEDULE EVERY 1 DAY
STARTS '2024-01-01 00:00:00'
DO
  CALL CleanupMyDayTasks();

-- 每周清理过期会话的事件  
CREATE EVENT IF NOT EXISTS ev_cleanup_expired_sessions
ON SCHEDULE EVERY 1 WEEK
STARTS '2024-01-01 02:00:00'
DO
  DELETE FROM user_sessions WHERE expires_at < NOW();

-- 每月清理旧的同步日志
CREATE EVENT IF NOT EXISTS ev_cleanup_sync_logs
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-01-01 03:00:00'
DO
  DELETE FROM sync_logs 
  WHERE created_at < DATE_SUB(NOW(), INTERVAL (
    SELECT config_value FROM system_configs WHERE config_key = 'sync_retention_days'
  ) DAY);

-- ================================================================
-- 脚本执行完成
-- ================================================================

SET foreign_key_checks = 1;

-- 显示创建结果
SELECT 'Jarvis Todo Database Schema Created Successfully!' as status;
SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = 'jarvis_todo';
