#!/bin/bash

# ================================================================
# Jarvis ToDo App - Database Deployment Script
# ================================================================
# 描述: 自动化部署 Jarvis 待办应用数据库
# 用途: 快速部署开发/测试/生产环境
# 版本: 1.0
# ================================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 配置变量
DB_HOST=${DB_HOST:-"localhost"}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-"jarvis_todo"}
DB_ROOT_USER=${DB_ROOT_USER:-"root"}
DB_APP_USER=${DB_APP_USER:-"jarvis_app"}
DB_APP_PASSWORD=${DB_APP_PASSWORD:-""}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-""}
INSTALL_SAMPLE_DATA=${INSTALL_SAMPLE_DATA:-"false"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 显示配置信息
show_config() {
    log_info "=== Jarvis ToDo Database Deployment ==="
    echo "数据库主机: $DB_HOST:$DB_PORT"
    echo "数据库名称: $DB_NAME"
    echo "Root 用户: $DB_ROOT_USER"
    echo "应用用户: $DB_APP_USER"
    echo "安装示例数据: $INSTALL_SAMPLE_DATA"
    echo "脚本目录: $SCRIPT_DIR"
    echo "========================================="
}

# 检查必需的文件
check_files() {
    log_info "检查必需的文件..."
    
    local required_files=("database_schema.sql")
    local optional_files=("sample_data.sql")
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
            log_error "缺少必需文件: $file"
            exit 1
        fi
    done
    
    for file in "${optional_files[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
            log_warning "缺少可选文件: $file (将跳过示例数据安装)"
            INSTALL_SAMPLE_DATA="false"
        fi
    done
    
    log_success "文件检查完成"
}

# 检查 MySQL 连接
check_mysql() {
    log_info "检查 MySQL 连接..."
    
    # 检查 MySQL 是否安装
    if ! command -v mysql &> /dev/null; then
        log_error "MySQL 客户端未安装"
        exit 1
    fi
    
    # 提示输入密码（如果未设置）
    if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
        read -s -p "请输入 MySQL root 密码: " MYSQL_ROOT_PASSWORD
        echo
    fi
    
    # 测试连接
    if ! mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_ROOT_USER" -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;" &> /dev/null; then
        log_error "无法连接到 MySQL 服务器"
        exit 1
    fi
    
    log_success "MySQL 连接正常"
}

# 创建应用用户密码
generate_app_password() {
    if [[ -z "$DB_APP_PASSWORD" ]]; then
        log_info "生成应用用户密码..."
        DB_APP_PASSWORD=$(openssl rand -base64 16)
        log_info "生成的应用用户密码: $DB_APP_PASSWORD"
        echo "请保存此密码用于应用配置！"
    fi
}

# 检查数据库是否存在
check_database_exists() {
    local exists
    exists=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_ROOT_USER" -p"$MYSQL_ROOT_PASSWORD" \
        -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$DB_NAME';" \
        --batch --skip-column-names 2>/dev/null | wc -l)
    
    if [[ $exists -gt 0 ]]; then
        log_warning "数据库 '$DB_NAME' 已存在"
        read -p "是否要删除并重新创建? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "删除现有数据库..."
            mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_ROOT_USER" -p"$MYSQL_ROOT_PASSWORD" \
                -e "DROP DATABASE IF EXISTS \`$DB_NAME\`;"
            log_success "数据库已删除"
        else
            log_error "部署已取消"
            exit 1
        fi
    fi
}

# 创建数据库和表结构
create_database() {
    log_info "创建数据库和表结构..."
    
    # 执行主要的数据库创建脚本
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_ROOT_USER" -p"$MYSQL_ROOT_PASSWORD" \
        < "$SCRIPT_DIR/database_schema.sql"
    
    log_success "数据库结构创建完成"
}

# 创建应用用户
create_app_user() {
    log_info "创建应用用户..."
    
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_ROOT_USER" -p"$MYSQL_ROOT_PASSWORD" <<EOF
-- 删除已存在的用户（如果有）
DROP USER IF EXISTS '$DB_APP_USER'@'%';
DROP USER IF EXISTS '$DB_APP_USER'@'localhost';

-- 创建新用户
CREATE USER '$DB_APP_USER'@'%' IDENTIFIED BY '$DB_APP_PASSWORD';
CREATE USER '$DB_APP_USER'@'localhost' IDENTIFIED BY '$DB_APP_PASSWORD';

-- 授予权限
GRANT SELECT, INSERT, UPDATE, DELETE ON \`$DB_NAME\`.* TO '$DB_APP_USER'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON \`$DB_NAME\`.* TO '$DB_APP_USER'@'localhost';

-- 授予执行存储过程的权限
GRANT EXECUTE ON \`$DB_NAME\`.* TO '$DB_APP_USER'@'%';
GRANT EXECUTE ON \`$DB_NAME\`.* TO '$DB_APP_USER'@'localhost';

-- 刷新权限
FLUSH PRIVILEGES;
EOF
    
    log_success "应用用户创建完成"
}

# 安装示例数据
install_sample_data() {
    if [[ "$INSTALL_SAMPLE_DATA" == "true" && -f "$SCRIPT_DIR/sample_data.sql" ]]; then
        log_info "安装示例数据..."
        
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_ROOT_USER" -p"$MYSQL_ROOT_PASSWORD" \
            "$DB_NAME" < "$SCRIPT_DIR/sample_data.sql"
        
        log_success "示例数据安装完成"
    else
        log_info "跳过示例数据安装"
    fi
}

# 验证部署
verify_deployment() {
    log_info "验证部署..."
    
    # 检查表是否创建成功
    local table_count
    table_count=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_ROOT_USER" -p"$MYSQL_ROOT_PASSWORD" \
        -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$DB_NAME';" \
        --batch --skip-column-names)
    
    log_info "已创建 $table_count 个表"
    
    # 测试应用用户连接
    if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_APP_USER" -p"$DB_APP_PASSWORD" \
        -e "SELECT 'Connection successful' as status;" "$DB_NAME" &> /dev/null; then
        log_success "应用用户连接测试成功"
    else
        log_error "应用用户连接测试失败"
        exit 1
    fi
    
    # 显示数据库统计
    log_info "数据库统计信息:"
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_APP_USER" -p"$DB_APP_PASSWORD" \
        "$DB_NAME" <<EOF
SELECT 
    'users' as table_name, COUNT(*) as record_count FROM users
UNION ALL
SELECT 'lists', COUNT(*) FROM lists
UNION ALL
SELECT 'tasks', COUNT(*) FROM tasks
UNION ALL
SELECT 'task_steps', COUNT(*) FROM task_steps
UNION ALL
SELECT 'tags', COUNT(*) FROM tags
UNION ALL
SELECT 'task_tags', COUNT(*) FROM task_tags;
EOF
}

# 生成配置文件
generate_config() {
    log_info "生成应用配置文件..."
    
    cat > "$SCRIPT_DIR/database_config.env" <<EOF
# Jarvis ToDo App Database Configuration
# Generated on $(date)

# Database Connection
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USERNAME=$DB_APP_USER
DB_PASSWORD=$DB_APP_PASSWORD

# Connection Pool Settings (recommended)
DB_POOL_MIN_CONNECTIONS=5
DB_POOL_MAX_CONNECTIONS=20
DB_POOL_MAX_IDLE_TIME=300

# SSL Settings (enable in production)
DB_SSL_MODE=PREFERRED

# Timezone
DB_TIMEZONE=UTC
EOF
    
    cat > "$SCRIPT_DIR/database_config.json" <<EOF
{
  "database": {
    "host": "$DB_HOST",
    "port": $DB_PORT,
    "database": "$DB_NAME",
    "username": "$DB_APP_USER",
    "password": "$DB_APP_PASSWORD",
    "charset": "utf8mb4",
    "collation": "utf8mb4_unicode_ci",
    "pool": {
      "min_connections": 5,
      "max_connections": 20,
      "max_idle_time": 300
    },
    "ssl": {
      "mode": "PREFERRED"
    }
  }
}
EOF
    
    log_success "配置文件已生成:"
    echo "  - database_config.env"
    echo "  - database_config.json"
}

# 显示完成信息
show_completion() {
    log_success "=== 部署完成 ==="
    echo
    echo "数据库信息:"
    echo "  主机: $DB_HOST:$DB_PORT"
    echo "  数据库: $DB_NAME"
    echo "  应用用户: $DB_APP_USER"
    echo "  应用密码: $DB_APP_PASSWORD"
    echo
    echo "下一步:"
    echo "  1. 将生成的配置文件添加到您的应用中"
    echo "  2. 确保应用可以连接到数据库"
    echo "  3. 考虑设置 SSL 连接（生产环境）"
    echo "  4. 配置定期备份任务"
    echo
    echo "管理命令:"
    echo "  连接数据库: mysql -h$DB_HOST -P$DB_PORT -u$DB_APP_USER -p$DB_PASSWORD $DB_NAME"
    echo "  清理我的一天: mysql -u$DB_APP_USER -p$DB_PASSWORD $DB_NAME -e \"CALL CleanupMyDayTasks();\""
    echo
    log_warning "请妥善保管数据库密码！"
}

# 清理函数
cleanup() {
    log_info "清理临时文件..."
    # 这里可以添加清理逻辑
}

# 主函数
main() {
    trap cleanup EXIT
    
    show_config
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --with-sample-data)
                INSTALL_SAMPLE_DATA="true"
                shift
                ;;
            --host)
                DB_HOST="$2"
                shift 2
                ;;
            --port)
                DB_PORT="$2"
                shift 2
                ;;
            --database)
                DB_NAME="$2"
                shift 2
                ;;
            --app-user)
                DB_APP_USER="$2"
                shift 2
                ;;
            --app-password)
                DB_APP_PASSWORD="$2"
                shift 2
                ;;
            --help)
                echo "用法: $0 [选项]"
                echo
                echo "选项:"
                echo "  --with-sample-data     安装示例数据"
                echo "  --host HOST           数据库主机 (默认: localhost)"
                echo "  --port PORT           数据库端口 (默认: 3306)"
                echo "  --database NAME       数据库名称 (默认: jarvis_todo)"
                echo "  --app-user USER       应用用户名 (默认: jarvis_app)"
                echo "  --app-password PASS   应用用户密码 (默认: 自动生成)"
                echo "  --help                显示此帮助信息"
                echo
                echo "环境变量:"
                echo "  MYSQL_ROOT_PASSWORD   MySQL root 密码"
                echo "  DB_HOST, DB_PORT, DB_NAME, DB_APP_USER, DB_APP_PASSWORD"
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                echo "使用 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done
    
    # 执行部署步骤
    check_files
    check_mysql
    generate_app_password
    check_database_exists
    create_database
    create_app_user
    install_sample_data
    verify_deployment
    generate_config
    show_completion
    
    log_success "Jarvis ToDo 数据库部署完成！"
}

# 执行主函数
main "$@"
