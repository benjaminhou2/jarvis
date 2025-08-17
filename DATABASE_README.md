# Jarvis ToDo App - 数据库部署指南 🗄️

本目录包含了 Jarvis 待办应用的完整 MySQL 数据库解决方案，包括表结构设计、示例数据和自动化部署脚本。

## 📁 文件说明

| 文件名 | 描述 |
|--------|------|
| `database_schema.sql` | **核心数据库表结构** - 完整的 MySQL 建表脚本 |
| `sample_data.sql` | **示例数据** - 用于开发测试的演示数据 |
| `deploy_database.sh` | **自动化部署脚本** - 一键部署数据库环境 |
| `DATABASE_DESIGN.md` | **详细设计文档** - 完整的数据库设计说明 |
| `DATABASE_README.md` | **快速开始指南** - 本文件 |

## 🚀 快速部署

### 方法一：使用自动化脚本（推荐）

```bash
# 1. 基础部署（不含示例数据）
./deploy_database.sh

# 2. 包含示例数据的部署
./deploy_database.sh --with-sample-data

# 3. 自定义配置部署
./deploy_database.sh \
    --host localhost \
    --port 3306 \
    --database jarvis_todo \
    --app-user jarvis_app \
    --with-sample-data
```

### 方法二：手动执行 SQL

```bash
# 1. 连接到 MySQL
mysql -u root -p

# 2. 执行建表脚本
mysql -u root -p < database_schema.sql

# 3. （可选）插入示例数据
mysql -u root -p jarvis_todo < sample_data.sql
```

## ⚙️ 环境要求

### 系统要求
- **MySQL**: 8.0+ 
- **操作系统**: Linux/macOS/Windows
- **内存**: 最少 2GB RAM
- **存储**: 最少 10GB 可用空间

### 前置条件
```bash
# 确保 MySQL 服务运行
# Linux/macOS
sudo systemctl start mysql
# 或
brew services start mysql

# Windows
net start mysql
```

## 🔧 配置说明

### 环境变量
```bash
export DB_HOST="localhost"
export DB_PORT="3306"
export DB_NAME="jarvis_todo"
export DB_APP_USER="jarvis_app"
export DB_APP_PASSWORD="your_secure_password"
export MYSQL_ROOT_PASSWORD="your_root_password"
```

### 脚本参数
```bash
./deploy_database.sh --help

选项:
  --with-sample-data     安装示例数据
  --host HOST           数据库主机 (默认: localhost)
  --port PORT           数据库端口 (默认: 3306)
  --database NAME       数据库名称 (默认: jarvis_todo)
  --app-user USER       应用用户名 (默认: jarvis_app)
  --app-password PASS   应用用户密码 (默认: 自动生成)
  --help                显示帮助信息
```

## 📊 数据库结构概览

### 核心表（14个）
```
用户管理模块:
├── users              # 用户基本信息
├── user_settings      # 用户设置
└── user_sessions      # 登录会话

任务管理模块:
├── lists              # 清单/分类
├── tasks              # 任务主表
├── task_steps         # 任务子步骤
├── tags               # 标签
└── task_tags          # 任务标签关联

系统功能模块:
├── notifications      # 通知记录
├── sync_logs          # 同步日志
├── user_sync_status   # 同步状态
├── audit_logs         # 审计日志
├── system_configs     # 系统配置
└── schema_versions    # 版本信息
```

### 关键特性
✅ **多用户支持** - 完整的用户注册登录系统  
✅ **智能列表** - 我的一天、已计划、重要、已完成  
✅ **丰富任务属性** - 截止日期、提醒、重复规则、子任务  
✅ **标签系统** - 支持 #标签 自动提取和管理  
✅ **多设备同步** - 完整的数据同步机制  
✅ **通知系统** - 支持各种类型的推送通知  
✅ **审计日志** - 完整的操作记录和追踪  

## 🔍 示例数据说明

`sample_data.sql` 包含以下测试数据：

### 测试用户
```
demo@jarvis.com     - Demo User    (完整功能演示)
alice@example.com   - Alice Chen   (设计师用户)
bob@example.com     - Bob Wilson   (普通用户)
```

### 测试数据统计
- **3个用户** + 配置设置
- **7个清单** (Personal, Work, Shopping等)
- **12个任务** (包含各种状态和属性)
- **16个子任务步骤**
- **6个标签** (#urgent, #meeting等)
- **8个标签关联**
- **3个通知记录**
- **完整同步日志**

## 💡 使用示例

### 连接数据库
```bash
# 使用应用用户连接
mysql -h localhost -u jarvis_app -p jarvis_todo

# 查看所有表
SHOW TABLES;

# 查看用户任务统计
SELECT * FROM v_user_task_stats;
```

### 常用查询
```sql
-- 查看用户的所有任务
SELECT t.title, l.name as list_name, t.is_completed 
FROM tasks t 
JOIN lists l ON t.list_id = l.id 
WHERE t.user_id = '550e8400-e29b-41d4-a716-446655440001';

-- 查看今日待办（我的一天）
SELECT title, due_date FROM tasks 
WHERE is_my_day = TRUE AND is_completed = FALSE;

-- 查看逾期任务
SELECT title, due_date FROM tasks 
WHERE due_date < NOW() AND is_completed = FALSE;
```

## 🛠️ 维护操作

### 日常维护
```sql
-- 清理"我的一天"过期任务
CALL CleanupMyDayTasks();

-- 清理过期会话
DELETE FROM user_sessions WHERE expires_at < NOW();

-- 清理旧同步日志（保留90天）
DELETE FROM sync_logs 
WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY);
```

### 性能优化
```sql
-- 查看表大小
SELECT 
    table_name,
    table_rows,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.tables 
WHERE table_schema = 'jarvis_todo';

-- 重建索引
OPTIMIZE TABLE tasks;
ANALYZE TABLE tasks, lists, tags;
```

### 备份恢复
```bash
# 全量备份
mysqldump --single-transaction jarvis_todo > backup_$(date +%Y%m%d).sql

# 恢复备份
mysql -u root -p jarvis_todo < backup_20240817.sql

# 只备份结构
mysqldump --no-data jarvis_todo > schema_only.sql
```

## 🔒 安全配置

### 生产环境建议
1. **修改默认密码**
   ```sql
   ALTER USER 'jarvis_app'@'%' IDENTIFIED BY 'complex_secure_password';
   ```

2. **限制用户权限**
   ```sql
   -- 移除危险权限
   REVOKE CREATE, DROP, ALTER ON jarvis_todo.* FROM 'jarvis_app'@'%';
   ```

3. **启用 SSL 连接**
   ```sql
   ALTER USER 'jarvis_app'@'%' REQUIRE SSL;
   ```

4. **配置防火墙**
   ```bash
   # 只允许应用服务器连接
   ufw allow from 192.168.1.100 to any port 3306
   ```

## 📈 监控指标

### 关键监控项
```sql
-- 活跃用户数
SELECT COUNT(DISTINCT user_id) as active_users
FROM user_sessions 
WHERE last_used_at > DATE_SUB(NOW(), INTERVAL 24 HOUR);

-- 任务创建趋势
SELECT DATE(created_at) as date, COUNT(*) as daily_tasks
FROM tasks 
WHERE created_at > DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(created_at);

-- 数据库连接数
SHOW STATUS LIKE 'Threads_connected';

-- 慢查询
SHOW VARIABLES LIKE 'slow_query_log';
```

## 🚨 故障排除

### 常见问题

#### 1. 连接被拒绝
```bash
# 检查 MySQL 服务状态
systemctl status mysql

# 检查端口是否开放
netstat -tlnp | grep 3306

# 检查用户权限
mysql -u root -p -e "SELECT user,host FROM mysql.user WHERE user='jarvis_app';"
```

#### 2. 权限不足
```sql
-- 重新授权
GRANT SELECT, INSERT, UPDATE, DELETE ON jarvis_todo.* TO 'jarvis_app'@'%';
FLUSH PRIVILEGES;
```

#### 3. 字符集问题
```sql
-- 检查字符集
SHOW CREATE DATABASE jarvis_todo;
SHOW CREATE TABLE tasks;

-- 修复字符集
ALTER DATABASE jarvis_todo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

#### 4. 性能问题
```sql
-- 查看慢查询
SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;

-- 分析查询计划
EXPLAIN SELECT * FROM tasks WHERE user_id = '...' AND is_completed = FALSE;
```

## 📞 技术支持

### 获取帮助
- **文档**: 查看 `DATABASE_DESIGN.md` 获取详细设计文档
- **日志**: 检查 MySQL 错误日志获取详细错误信息
- **社区**: 提交 Issue 到项目仓库

### 版本更新
```sql
-- 检查当前数据库版本
SELECT version, applied_at FROM schema_versions 
ORDER BY applied_at DESC LIMIT 1;
```

---

**部署完成后，您将拥有一个功能完整、性能优化、安全可靠的 Jarvis 待办应用数据库！** 🎉

如需帮助，请查看详细设计文档或联系技术支持团队。
