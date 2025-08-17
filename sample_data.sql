-- ================================================================
-- Jarvis ToDo App - Sample Data Script
-- ================================================================
-- 描述: 为 Jarvis 待办应用插入示例数据
-- 用途: 开发测试、演示用途
-- ================================================================

USE `jarvis_todo`;

-- ================================================================
-- 1. 创建示例用户
-- ================================================================

INSERT INTO `users` (`id`, `email`, `username`, `password_hash`, `avatar_url`, `is_active`, `email_verified`, `timezone`) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'demo@jarvis.com', 'Demo User', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'https://avatar.example.com/demo.jpg', TRUE, TRUE, 'Asia/Shanghai'),
('550e8400-e29b-41d4-a716-446655440002', 'alice@example.com', 'Alice Chen', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, TRUE, TRUE, 'Asia/Shanghai'),
('550e8400-e29b-41d4-a716-446655440003', 'bob@example.com', 'Bob Wilson', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, TRUE, FALSE, 'America/New_York');

-- ================================================================
-- 2. 创建用户设置
-- ================================================================

INSERT INTO `user_settings` (`user_id`, `sync_enabled`, `default_reminder_minutes`, `theme`, `notification_enabled`, `auto_add_to_myday`) VALUES
('550e8400-e29b-41d4-a716-446655440001', TRUE, 15, 0, TRUE, FALSE),
('550e8400-e29b-41d4-a716-446655440002', TRUE, 30, 1, TRUE, TRUE),
('550e8400-e29b-41d4-a716-446655440003', FALSE, 10, 2, FALSE, FALSE);

-- ================================================================
-- 3. 创建示例清单
-- ================================================================

-- Demo User 的清单
INSERT INTO `lists` (`id`, `user_id`, `name`, `icon`, `color`, `is_system`, `sort_index`) VALUES
('650e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Personal', 'person.fill', '#007AFF', FALSE, 1),
('650e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'Work', 'briefcase.fill', '#FF9500', FALSE, 2),
('650e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', 'Shopping', 'cart.fill', '#34C759', FALSE, 3),
('650e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440001', 'Travel Plans', 'airplane', '#AF52DE', FALSE, 4);

-- Alice 的清单
INSERT INTO `lists` (`id`, `user_id`, `name`, `icon`, `color`, `is_system`, `sort_index`) VALUES
('650e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440002', 'Daily Tasks', 'checkmark.circle', '#007AFF', FALSE, 1),
('650e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440002', 'Project Alpha', 'folder.fill', '#FF3B30', FALSE, 2);

-- Bob 的清单
INSERT INTO `lists` (`id`, `user_id`, `name`, `icon`, `color`, `is_system`, `sort_index`) VALUES
('650e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440003', 'Home', 'house.fill', '#8E8E93', FALSE, 1);

-- ================================================================
-- 4. 创建示例标签
-- ================================================================

INSERT INTO `tags` (`id`, `user_id`, `name`, `color`, `usage_count`) VALUES
('750e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'urgent', '#FF3B30', 3),
('750e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'meeting', '#007AFF', 2),
('750e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', 'health', '#34C759', 1),
('750e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440001', 'finance', '#FFD60A', 2),
('750e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440002', 'design', '#AF52DE', 1),
('750e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440002', 'coding', '#007AFF', 3);

-- ================================================================
-- 5. 创建示例任务
-- ================================================================

-- Demo User 的任务
INSERT INTO `tasks` (`id`, `user_id`, `list_id`, `title`, `notes`, `due_date`, `reminder_date`, `is_completed`, `is_important`, `is_my_day`, `repeat_rule`, `sort_index`) VALUES

-- Personal 清单任务
('850e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440001', 
 '晨跑 30 分钟', '在公园跑步，保持健康生活方式', 
 DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 1 DAY) - INTERVAL 30 MINUTE, 
 FALSE, TRUE, TRUE, '{"kind":"daily","weekdays":null,"dayOfMonth":null,"isLastDayOfMonth":null}', 1),

('850e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440001', 
 '阅读技术书籍', '每天阅读 Swift 编程相关书籍 1 小时', 
 NULL, NULL, FALSE, FALSE, FALSE, NULL, 2),

('850e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440001', 
 '整理房间', '周末大扫除，整理衣柜和书桌', 
 DATE_ADD(NOW(), INTERVAL 2 DAY), NULL, FALSE, FALSE, FALSE, NULL, 3),

-- Work 清单任务
('850e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440002', 
 '完成项目报告', '准备季度项目总结报告，包含数据分析和建议', 
 DATE_ADD(NOW(), INTERVAL 3 DAY), DATE_ADD(NOW(), INTERVAL 3 DAY) - INTERVAL 1 HOUR, 
 FALSE, TRUE, TRUE, NULL, 1),

('850e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440002', 
 '团队会议准备', '准备下周一的团队会议材料', 
 DATE_ADD(NOW(), INTERVAL 5 DAY), NULL, FALSE, TRUE, FALSE, NULL, 2),

('850e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440002', 
 '代码审查', '审查新功能的 Pull Request', 
 DATE_ADD(NOW(), INTERVAL 1 DAY), NULL, TRUE, FALSE, FALSE, NULL, 3),

-- Shopping 清单任务
('850e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440003', 
 '买菜', '土豆、胡萝卜、鸡肉、牛奶', NULL, NULL, FALSE, FALSE, FALSE, NULL, 1),

('850e8400-e29b-41d4-a716-446655440022', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440003', 
 '购买生日礼物', '为妈妈挑选生日礼物', 
 DATE_ADD(NOW(), INTERVAL 7 DAY), NULL, FALSE, TRUE, FALSE, NULL, 2),

-- Travel Plans 清单任务
('850e8400-e29b-41d4-a716-446655440031', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440004', 
 '预订机票', '预订去日本的往返机票', 
 DATE_ADD(NOW(), INTERVAL 10 DAY), DATE_ADD(NOW(), INTERVAL 9 DAY), FALSE, TRUE, FALSE, NULL, 1),

('850e8400-e29b-41d4-a716-446655440032', '550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440004', 
 '制定旅行计划', '规划东京 5 天的行程安排', NULL, NULL, FALSE, FALSE, FALSE, NULL, 2);

-- Alice 的任务
INSERT INTO `tasks` (`id`, `user_id`, `list_id`, `title`, `notes`, `due_date`, `is_completed`, `is_important`, `sort_index`) VALUES
('850e8400-e29b-41d4-a716-446655440101', '550e8400-e29b-41d4-a716-446655440002', '650e8400-e29b-41d4-a716-446655440011', 
 '设计新 UI 界面', 'iOS 应用的用户界面重新设计', DATE_ADD(NOW(), INTERVAL 2 DAY), FALSE, TRUE, 1),

('850e8400-e29b-41d4-a716-446655440102', '550e8400-e29b-41d4-a716-446655440002', '650e8400-e29b-41d4-a716-446655440012', 
 '实现用户认证功能', '添加登录注册和密码重置功能', DATE_ADD(NOW(), INTERVAL 5 DAY), FALSE, TRUE, 1);

-- Bob 的任务
INSERT INTO `tasks` (`id`, `user_id`, `list_id`, `title`, `notes`, `is_completed`, `sort_index`) VALUES
('850e8400-e29b-41d4-a716-446655440201', '550e8400-e29b-41d4-a716-446655440003', '650e8400-e29b-41d4-a716-446655440021', 
 '修理水龙头', '厨房水龙头漏水需要修理', TRUE, 1),

('850e8400-e29b-41d4-a716-446655440202', '550e8400-e29b-41d4-a716-446655440003', '650e8400-e29b-41d4-a716-446655440021', 
 '缴纳电费', '本月电费账单', FALSE, 2);

-- ================================================================
-- 6. 创建任务步骤
-- ================================================================

-- 为"完成项目报告"添加步骤
INSERT INTO `task_steps` (`id`, `task_id`, `title`, `is_completed`, `sort_index`) VALUES
('950e8400-e29b-41d4-a716-446655440001', '850e8400-e29b-41d4-a716-446655440011', '收集项目数据', TRUE, 1),
('950e8400-e29b-41d4-a716-446655440002', '850e8400-e29b-41d4-a716-446655440011', '分析数据趋势', FALSE, 2),
('950e8400-e29b-41d4-a716-446655440003', '850e8400-e29b-41d4-a716-446655440011', '撰写总结报告', FALSE, 3),
('950e8400-e29b-41d4-a716-446655440004', '850e8400-e29b-41d4-a716-446655440011', '制作演示文稿', FALSE, 4);

-- 为"制定旅行计划"添加步骤
INSERT INTO `task_steps` (`id`, `task_id`, `title`, `is_completed`, `sort_index`) VALUES
('950e8400-e29b-41d4-a716-446655440011', '850e8400-e29b-41d4-a716-446655440032', '研究东京景点', FALSE, 1),
('950e8400-e29b-41d4-a716-446655440012', '850e8400-e29b-41d4-a716-446655440032', '预订酒店', FALSE, 2),
('950e8400-e29b-41d4-a716-446655440013', '850e8400-e29b-41d4-a716-446655440032', '规划每日行程', FALSE, 3),
('950e8400-e29b-41d4-a716-446655440014', '850e8400-e29b-41d4-a716-446655440032', '准备签证材料', FALSE, 4);

-- 为"买菜"添加步骤
INSERT INTO `task_steps` (`id`, `task_id`, `title`, `is_completed`, `sort_index`) VALUES
('950e8400-e29b-41d4-a716-446655440021', '850e8400-e29b-41d4-a716-446655440021', '土豆 2kg', FALSE, 1),
('950e8400-e29b-41d4-a716-446655440022', '850e8400-e29b-41d4-a716-446655440021', '胡萝卜 1kg', FALSE, 2),
('950e8400-e29b-41d4-a716-446655440023', '850e8400-e29b-41d4-a716-446655440021', '鸡胸肉 500g', FALSE, 3),
('950e8400-e29b-41d4-a716-446655440024', '850e8400-e29b-41d4-a716-446655440021', '牛奶 2L', FALSE, 4);

-- ================================================================
-- 7. 创建任务标签关联
-- ================================================================

INSERT INTO `task_tags` (`task_id`, `tag_id`) VALUES
-- 为"晨跑 30 分钟"添加健康标签
('850e8400-e29b-41d4-a716-446655440001', '750e8400-e29b-41d4-a716-446655440003'),

-- 为"完成项目报告"添加紧急标签
('850e8400-e29b-41d4-a716-446655440011', '750e8400-e29b-41d4-a716-446655440001'),

-- 为"团队会议准备"添加会议标签
('850e8400-e29b-41d4-a716-446655440012', '750e8400-e29b-41d4-a716-446655440002'),

-- 为"购买生日礼物"添加紧急和财务标签
('850e8400-e29b-41d4-a716-446655440022', '750e8400-e29b-41d4-a716-446655440001'),
('850e8400-e29b-41d4-a716-446655440022', '750e8400-e29b-41d4-a716-446655440004'),

-- 为"预订机票"添加紧急和财务标签
('850e8400-e29b-41d4-a716-446655440031', '750e8400-e29b-41d4-a716-446655440001'),
('850e8400-e29b-41d4-a716-446655440031', '750e8400-e29b-41d4-a716-446655440004'),

-- 为 Alice 的任务添加标签
('850e8400-e29b-41d4-a716-446655440101', '750e8400-e29b-41d4-a716-446655440011'),
('850e8400-e29b-41d4-a716-446655440102', '750e8400-e29b-41d4-a716-446655440012');

-- ================================================================
-- 8. 创建示例通知
-- ================================================================

INSERT INTO `notifications` (`user_id`, `task_id`, `type`, `title`, `body`, `scheduled_at`, `status`) VALUES
('550e8400-e29b-41d4-a716-446655440001', '850e8400-e29b-41d4-a716-446655440001', 'reminder', 
 '晨跑提醒', '该去晨跑了！保持健康生活习惯', 
 DATE_ADD(NOW(), INTERVAL 1 DAY) - INTERVAL 30 MINUTE, 'pending'),

('550e8400-e29b-41d4-a716-446655440001', '850e8400-e29b-41d4-a716-446655440011', 'reminder', 
 '项目报告提醒', '项目报告明天截止，记得完成', 
 DATE_ADD(NOW(), INTERVAL 3 DAY) - INTERVAL 1 HOUR, 'pending'),

('550e8400-e29b-41d4-a716-446655440001', '850e8400-e29b-41d4-a716-446655440031', 'due', 
 '预订机票', '别忘记预订去日本的机票', 
 DATE_ADD(NOW(), INTERVAL 9 DAY), 'pending');

-- ================================================================
-- 9. 创建示例同步记录
-- ================================================================

INSERT INTO `sync_logs` (`user_id`, `entity_type`, `entity_id`, `action`, `device_id`, `sync_version`) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'task', '850e8400-e29b-41d4-a716-446655440001', 'create', 'iPhone_Demo_001', 1),
('550e8400-e29b-41d4-a716-446655440001', 'task', '850e8400-e29b-41d4-a716-446655440002', 'create', 'iPhone_Demo_001', 2),
('550e8400-e29b-41d4-a716-446655440001', 'task', '850e8400-e29b-41d4-a716-446655440013', 'update', 'MacBook_Demo_001', 3),
('550e8400-e29b-41d4-a716-446655440002', 'task', '850e8400-e29b-41d4-a716-446655440101', 'create', 'iPad_Alice_001', 1);

-- ================================================================
-- 10. 创建用户同步状态
-- ================================================================

INSERT INTO `user_sync_status` (`user_id`, `device_id`, `last_sync_version`, `last_sync_at`) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'iPhone_Demo_001', 2, NOW() - INTERVAL 1 HOUR),
('550e8400-e29b-41d4-a716-446655440001', 'MacBook_Demo_001', 3, NOW() - INTERVAL 30 MINUTE),
('550e8400-e29b-41d4-a716-446655440002', 'iPad_Alice_001', 1, NOW() - INTERVAL 2 HOUR),
('550e8400-e29b-41d4-a716-446655440003', 'iPhone_Bob_001', 0, NOW() - INTERVAL 1 DAY);

-- ================================================================
-- 示例数据插入完成
-- ================================================================

-- 显示插入结果统计
SELECT 'Sample Data Inserted Successfully!' as status;
SELECT 
    (SELECT COUNT(*) FROM users) as users_count,
    (SELECT COUNT(*) FROM lists) as lists_count,
    (SELECT COUNT(*) FROM tasks) as tasks_count,
    (SELECT COUNT(*) FROM task_steps) as steps_count,
    (SELECT COUNT(*) FROM tags) as tags_count,
    (SELECT COUNT(*) FROM task_tags) as task_tags_count,
    (SELECT COUNT(*) FROM notifications) as notifications_count;
