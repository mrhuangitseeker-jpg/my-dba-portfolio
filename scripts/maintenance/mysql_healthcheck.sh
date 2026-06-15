#!/bin/bash
# ============================================
# 脚本名称: mysql_healthcheck.sh
# 描述: MySQL 自动化巡检脚本 - 五大维度全面检查
# 用法: ./mysql_healthcheck.sh [-h host] [-P port] [-u user] [-p password]
# 输出: 控制台 + 报告文件 (/tmp/mysql_healthcheck/report_YYYYMMDD_HHMMSS.txt)
# ============================================

set -euo pipefail

# ============================================
# 颜色定义
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================
# 默认参数
# ============================================
MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-}"
REPORT_DIR="/tmp/mysql_healthcheck"
REPORT_DATE=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/report_${REPORT_DATE}.txt"

# ============================================
# 解析命令行参数
# ============================================
usage() {
    echo "Usage: $0 [-h host] [-P port] [-u user] [-p password]"
    exit 1
}

while getopts "h:P:u:p:" opt; do
    case $opt in
        h) MYSQL_HOST="$OPTARG" ;;
        P) MYSQL_PORT="$OPTARG" ;;
        u) MYSQL_USER="$OPTARG" ;;
        p) MYSQL_PASS="$OPTARG" ;;
        *) usage ;;
    esac
done

# 创建报告目录
mkdir -p "$REPORT_DIR"

# ============================================
# MySQL 执行函数
# ============================================
mysql_exec() {
    local sql="$1"
    local pass_opt=""
    [ -n "$MYSQL_PASS" ] && pass_opt="-p${MYSQL_PASS}"
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" $pass_opt \
        -N -e "$sql" 2>/dev/null
}

mysql_exec_table() {
    local sql="$1"
    local pass_opt=""
    [ -n "$MYSQL_PASS" ] && pass_opt="-p${MYSQL_PASS}"
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" $pass_opt \
        -e "$sql" 2>/dev/null
}

# ============================================
# 报告输出函数
# ============================================
report() {
    echo -e "$1" | tee -a "$REPORT_FILE"
}

report_color() {
    echo -e "$1" | tee -a "$REPORT_FILE"
}

separator() {
    report "════════════════════════════════════════════════════════════════════════════════════"
}

separator_small() {
    report "────────────────────────────────────────────────────────────────────────────────────"
}

# ============================================
# 1. 实例健康检查
# ============================================
check_instance_health() {
    separator
    report_color "${BLUE}【一、实例健康检查】${NC}"
    separator
    
    # MySQL 版本
    local version
    version=$(mysql_exec "SELECT VERSION()")
    report "✅ MySQL 版本：${version}"
    
    # 运行时间
    local uptime
    uptime=$(mysql_exec "SHOW GLOBAL STATUS LIKE 'Uptime'" | awk '{print $2}')
    local days=$((uptime / 86400))
    local hours=$(((uptime % 86400) / 3600))
    local minutes=$(((uptime % 3600) / 60))
    report "✅ 运行时间：${days} 天 ${hours} 小时 ${minutes} 分钟"
    
    # 数据目录磁盘使用
    local datadir
    datadir=$(mysql_exec "SELECT @@datadir")
    local disk_usage
    disk_usage=$(df -h "$datadir" 2>/dev/null | tail -1 | awk '{print $5}')
    local disk_used
    disk_used=$(df -h "$datadir" 2>/dev/null | tail -1 | awk '{print $3}')
    local disk_total
    disk_total=$(df -h "$datadir" 2>/dev/null | tail -1 | awk '{print $2}')
    report "✅ 数据目录：${datadir}"
    report "✅ 磁盘使用：${disk_used}/${disk_total} (${disk_usage})"
    
    local disk_pct=${disk_usage%\%}
    if [ "$disk_pct" -gt 85 ]; then
        report_color "${RED}⚠️ 警告：磁盘使用率超过 85%！${NC}"
    elif [ "$disk_pct" -gt 70 ]; then
        report_color "${YELLOW}⚡ 注意：磁盘使用率超过 70%${NC}"
    else
        report_color "${GREEN}✅ 磁盘空间正常${NC}"
    fi
    
    # 数据库总大小
    local db_size
    db_size=$(mysql_exec "
        SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) 
        FROM information_schema.tables
    ")
    report "✅ 数据库总大小：${db_size} GB"
    
    # InnoDB Buffer Pool 大小
    local bp_size
    bp_size=$(mysql_exec "SELECT @@innodb_buffer_pool_size")
    bp_size_mb=$((bp_size / 1024 / 1024))
    report "✅ InnoDB Buffer Pool：${bp_size_mb} MB"
    
    report ""
}

# ============================================
# 2. 性能指标检查
# ============================================
check_performance() {
    separator
    report_color "${BLUE}【二、性能指标检查】${NC}"
    separator
    
    # 连接数
    local threads_connected max_conn
    threads_connected=$(mysql_exec "SHOW GLOBAL STATUS LIKE 'Threads_connected'" | awk '{print $2}')
    max_conn=$(mysql_exec "SHOW GLOBAL VARIABLES LIKE 'max_connections'" | awk '{print $2}')
    local conn_pct=$((threads_connected * 100 / max_conn))
    report "📊 连接使用率：${threads_connected}/${max_conn} (${conn_pct}%)"
    if [ "$conn_pct" -gt 85 ]; then
        report_color "${RED}⚠️ 警告：连接使用率超过 85%！${NC}"
    elif [ "$conn_pct" -gt 70 ]; then
        report_color "${YELLOW}⚡ 注意：连接使用率超过 70%${NC}"
    else
        report_color "${GREEN}✅ 连接使用正常${NC}"
    fi
    
    # 活跃线程
    local threads_running
    threads_running=$(mysql_exec "SHOW GLOBAL STATUS LIKE 'Threads_running'" | awk '{print $2}')
    report "📊 活跃线程数：${threads_running}"
    [ "$threads_running" -gt 50 ] && report_color "${YELLOW}⚡ 注意：活跃线程超过 50${NC}"
    
    # QPS 估算
    local questions uptime
    questions=$(mysql_exec "SHOW GLOBAL STATUS LIKE 'Questions'" | awk '{print $2}')
    uptime=$(mysql_exec "SHOW GLOBAL STATUS LIKE 'Uptime'" | awk '{print $2}')
    if [ "$uptime" -gt 0 ]; then
        local qps=$((questions / uptime))
        report "📊 QPS（平均）：${qps}"
    fi
    
    # Buffer Pool 命中率
    local bp_reads bp_requests
    bp_reads=$(mysql_exec "SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_reads'" | awk '{print $2}')
    bp_requests=$(mysql_exec "SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_read_requests'" | awk '{print $2}')
    if [ "$bp_requests" -gt 0 ]; then
        local hit_rate
        hit_rate=$(echo "scale=2; (1 - $bp_reads / $bp_requests) * 100" | bc)
        report "📊 Buffer Pool 命中率：${hit_rate}%"
        local hit_int=${hit_rate%.*}
        if [ "${hit_int:-0}" -lt 95 ]; then
            report_color "${RED}⚠️ 警告：Buffer Pool 命中率低于 95%！${NC}"
        elif [ "${hit_int:-0}" -lt 98 ]; then
            report_color "${YELLOW}⚡ 注意：Buffer Pool 命中率低于 98%${NC}"
        else
            report_color "${GREEN}✅ Buffer Pool 命中率正常${NC}"
        fi
    fi
    
    # 慢查询
    local slow_queries
    slow_queries=$(mysql_exec "SHOW GLOBAL STATUS LIKE 'Slow_queries'" | awk '{print $2}')
    report "📊 慢查询总数（累计）：${slow_queries}"
    
    # 行锁等待
    local lock_waits lock_time_avg
    lock_waits=$(mysql_exec "SHOW GLOBAL STATUS LIKE 'Innodb_row_lock_waits'" | awk '{print $2}')
    lock_time_avg=$(mysql_exec "SHOW GLOBAL STATUS LIKE 'Innodb_row_lock_time_avg'" | awk '{print $2}')
    report "📊 行锁等待次数：${lock_waits}"
    report "📊 行锁平均等待：${lock_time_avg} ms"
    
    # 临时表
    local tmp_tables tmp_disk_tables
    tmp_tables=$(mysql_exec "SHOW GLOBAL STATUS LIKE 'Created_tmp_tables'" | awk '{print $2}')
    tmp_disk_tables=$(mysql_exec "SHOW GLOBAL STATUS LIKE 'Created_tmp_disk_tables'" | awk '{print $2}')
    if [ "$tmp_tables" -gt 0 ]; then
        local tmp_pct=$((tmp_disk_tables * 100 / tmp_tables))
        report "📊 磁盘临时表比例：${tmp_pct}%"
        if [ "$tmp_pct" -gt 25 ]; then
            report_color "${YELLOW}⚡ 注意：磁盘临时表比例过高${NC}"
        fi
    fi
    
    # InnoDB 行锁当前等待
    local current_lock_waits
    current_lock_waits=$(mysql_exec "SELECT COUNT(*) FROM information_schema.INNODB_LOCK_WAITS" 2>/dev/null || echo "0")
    if [ "$current_lock_waits" -gt 0 ]; then
        report_color "${RED}⚠️ 当前存在行锁等待！数量：${current_lock_waits}${NC}"
    fi
    
    report ""
}

# ============================================
# 3. 安全检查
# ============================================
check_security() {
    separator
    report_color "${BLUE}【三、安全检查】${NC}"
    separator
    
    # 空密码用户
    local empty_pass
    empty_pass=$(mysql_exec "
        SELECT CONCAT(user, '@', host) 
        FROM mysql.user 
        WHERE authentication_string = '' OR authentication_string IS NULL
    ")
    if [ -z "$empty_pass" ]; then
        report_color "${GREEN}✅ 无空密码用户${NC}"
    else
        report_color "${RED}⚠️ 发现空密码用户：${NC}"
        echo "$empty_pass" | while read -r line; do
            report "   - $line"
        done
    fi
    
    # 可远程登录的 root
    local remote_root
    remote_root=$(mysql_exec "
        SELECT CONCAT(user, '@', host) 
        FROM mysql.user 
        WHERE user = 'root' AND host NOT IN ('localhost', '127.0.0.1', '::1')
    ")
    if [ -z "$remote_root" ]; then
        report_color "${GREEN}✅ root 仅允许本地登录${NC}"
    else
        report_color "${RED}⚠️ root 可远程登录：${NC}"
        echo "$remote_root" | while read -r line; do
            report "   - $line"
        done
    fi
    
    # 拥有 ALL PRIVILEGES 的用户
    local all_priv_users
    all_priv_users=$(mysql_exec "
        SELECT GRANTEE FROM information_schema.USER_PRIVILEGES
        WHERE PRIVILEGE_TYPE = 'SUPER' OR PRIVILEGE_TYPE = 'ALL'
        GROUP BY GRANTEE
        LIMIT 10
    " 2>/dev/null)
    if [ -n "$all_priv_users" ]; then
        report "📊 拥有 SUPER/ALL 权限的用户（TOP 10）："
        echo "$all_priv_users" | while read -r line; do
            report "   - $line"
        done
    fi
    
    # SSL 状态
    local ssl_status
    ssl_status=$(mysql_exec "SHOW GLOBAL VARIABLES LIKE 'have_ssl'" | awk '{print $2}')
    if [ "$ssl_status" = "YES" ]; then
        report_color "${GREEN}✅ SSL 状态：已开启${NC}"
    else
        report_color "${YELLOW}⚡ SSL 状态：未开启${NC}"
    fi
    
    # 密码验证插件
    local validate_pass
    validate_pass=$(mysql_exec "SHOW VARIABLES LIKE 'validate_password%'" 2>/dev/null | head -1)
    if [ -n "$validate_pass" ]; then
        report_color "${GREEN}✅ 密码验证插件已启用${NC}"
    else
        report_color "${YELLOW}⚡ 密码验证插件未启用${NC}"
    fi
    
    report ""
}

# ============================================
# 4. 备份状态检查
# ============================================
check_backup() {
    separator
    report_color "${BLUE}【四、备份状态检查】${NC}"
    separator
    
    # Binlog 开启状态
    local log_bin
    log_bin=$(mysql_exec "SELECT @@log_bin")
    if [ "$log_bin" = "1" ]; then
        report_color "${GREEN}✅ Binlog 状态：已开启${NC}"
    else
        report_color "${YELLOW}⚡ Binlog 状态：未开启${NC}"
    fi
    
    # Binlog 总大小
    local binlog_size
    binlog_size=$(mysql_exec "
        SHOW BINARY LOGS
    " 2>/dev/null | awk '{sum += $2} END {printf "%.2f", sum/1024/1024/1024}')
    if [ -n "$binlog_size" ]; then
        report "📊 Binlog 总大小：${binlog_size} GB"
    fi
    
    # Binlog 保留时间
    local expire
    expire=$(mysql_exec "SELECT @@binlog_expire_logs_seconds")
    report "📊 Binlog 保留时间：$((expire / 86400)) 天"
    
    # 检查本地备份文件（可选，需配置备份目录）
    local backup_dir="/backup/mysql"
    if [ -d "$backup_dir" ]; then
        local latest_backup
        latest_backup=$(ls -t "$backup_dir"/*.sql.gz 2>/dev/null | head -1)
        if [ -n "$latest_backup" ]; then
            local backup_time=$(stat -c %Y "$latest_backup" 2>/dev/null || stat -f %c "$latest_backup" 2>/dev/null)
            local now_time=$(date +%s)
            local backup_age=$(( (now_time - backup_time) / 3600 ))
            report "📊 最新备份：$(basename "$latest_backup")"
            if [ "$backup_age" -gt 48 ]; then
                report_color "${YELLOW}⚡ 注意：最新备份已超过 48 小时${NC}"
            else
                report_color "${GREEN}✅ 备份文件正常${NC}"
            fi
        fi
    fi
    
    report ""
}

# ============================================
# 5. 复制状态检查
# ============================================
check_replication() {
    separator
    report_color "${BLUE}【五、复制状态检查】${NC}"
    separator
    
    local slave_status
    slave_status=$(mysql_exec "SHOW REPLICA STATUS\G" 2>/dev/null)
    
    if [ -z "$slave_status" ]; then
        report "当前实例非从库（或未配置复制）"
    else
        local io_running sql_running lag
        io_running=$(echo "$slave_status" | grep "Replica_IO_Running:" | awk '{print $2}')
        sql_running=$(echo "$slave_status" | grep "Replica_SQL_Running:" | awk '{print $2}')
        lag=$(echo "$slave_status" | grep "Seconds_Behind_Source:" | awk '{print $2}')
        
        report "📊 IO 线程：${io_running}"
        report "📊 SQL 线程：${sql_running}"
        report "📊 延迟：${lag} 秒"
        
        if [ "$io_running" = "Yes" ] && [ "$sql_running" = "Yes" ]; then
            report_color "${GREEN}✅ 复制状态正常${NC}"
        else
            report_color "${RED}❌ 复制状态异常！${NC}"
            # 显示错误信息
            local last_error
            last_error=$(echo "$slave_status" | grep "Last_Error:" | cut -d: -f2-)
            if [ -n "$last_error" ]; then
                report "   错误信息：${last_error}"
            fi
        fi
        
        if [ "$lag" != "NULL" ] && [ -n "$lag" ] && [ "$lag" -gt 60 ] 2>/dev/null; then
            report_color "${YELLOW}⚡ 注意：复制延迟超过 60 秒！${NC}"
        fi
    fi
    report ""
}

# ============================================
# 6. 慢查询快速查看
# ============================================
check_slow_queries() {
    separator
    report_color "${BLUE}【六、慢查询速查】${NC}"
    separator
    
    # 尝试使用 sys schema
    local have_sys
    have_sys=$(mysql_exec "SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='sys'" 2>/dev/null)
    
    if [ "$have_sys" -gt 0 ]; then
        report "📊 慢 SQL TOP 5（按P95耗时排序）："
        mysql_exec_table "
            SELECT 
                query,
                exec_count,
                format_pico_time(avg_latency) AS avg_latency,
                rows_examined_avg
            FROM sys.statements_with_runtimes_in_95th_percentile 
            LIMIT 5;
        " 2>/dev/null || report "   sys schema 查询失败"
        
        report ""
        report "📊 全表扫描 TOP 5："
        mysql_exec_table "
            SELECT 
                query,
                exec_count,
                no_index_used_pct,
                rows_examined_avg
            FROM sys.statements_with_full_table_scans
            ORDER BY no_index_used_count DESC 
            LIMIT 5;
        " 2>/dev/null || report "   sys schema 查询失败"
    else
        report "⚠️ sys schema 未启用，跳过慢查询分析"
        report "   可执行以下命令启用："
        report "   mysql -u root -p < /usr/share/mysql-8.0/sys_57.sql"
    fi
    
    report ""
}

# ============================================
# 7. 表空间检查
# ============================================
check_tablespace() {
    separator
    report_color "${BLUE}【七、表空间检查】${NC}"
    separator
    
    report "📊 表大小 TOP 10："
    mysql_exec_table "
        SELECT 
            TABLE_SCHEMA AS '数据库',
            TABLE_NAME AS '表名',
            ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS '大小(MB)',
            TABLE_ROWS AS '行数'
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA NOT IN ('mysql','sys','performance_schema','information_schema')
        ORDER BY DATA_LENGTH + INDEX_LENGTH DESC 
        LIMIT 10;
    " 2>/dev/null
    
    report ""
}

# ============================================
# 主程序
# ============================================
main() {
    # 生成报告头
    report "╔════════════════════════════════════════════════════════════════════════════════════╗"
    report "║                         MySQL 自动化巡检报告                                        ║"
    report "╠════════════════════════════════════════════════════════════════════════════════════╣"
    report "║  巡检时间：$(date '+%Y-%m-%d %H:%M:%S')                                             ║"
    report "║  目标主机：${MYSQL_HOST}:${MYSQL_PORT}                                                   ║"
    report "║  报告文件：${REPORT_FILE}                                                          ║"
    report "╚════════════════════════════════════════════════════════════════════════════════════╝"
    report ""
    
    # 连接测试
    if ! mysql_exec "SELECT 1" > /dev/null 2>&1; then
        report_color "${RED}❌ 无法连接到 MySQL！${NC}"
        report "请检查："
        report "  1. MySQL 是否运行"
        report "  2. 主机/端口是否正确"
        report "  3. 用户名/密码是否正确"
        exit 1
    fi
    report_color "${GREEN}✅ 连接成功${NC}"
    report ""
    
    # 执行各项检查
    check_instance_health
    check_performance
    check_security
    check_backup
    check_replication
    check_slow_queries
    check_tablespace
    
    # 汇总
    separator
    report_color "${BLUE}【巡检总结】${NC}"
    separator
    
    local warnings errors
    warnings=$(grep -c "⚠️" "$REPORT_FILE" 2>/dev/null || echo "0")
    errors=$(grep -c "❌" "$REPORT_FILE" 2>/dev/null || echo "0")
    
    report "巡检完成！"
    report "  ⚡ 警告项：${warnings}"
    report "  ❌ 严重项：${errors}"
    report "  📄 详细报告：${REPORT_FILE}"
    
    separator
    report "提示："
    report "  - ⚡ 表示需要关注，建议优化"
    report "  - ❌ 表示严重问题，需要立即处理"
    report "  - ✅ 表示检查通过"
    report ""
}

# 运行主程序
main "$@"
