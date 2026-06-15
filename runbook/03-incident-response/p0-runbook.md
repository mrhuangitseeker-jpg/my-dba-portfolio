# P0 故障应急手册

## Mysql 应急手册

### 故障排查方法论

#### RCCA 四步法

```sql
面对任何故障，按照 RCCA 四步法系统排查：

  R — Restore（恢复）
    第一要务是恢复业务，不是找根因
    先止血，后查因
    能重启解决的先重启，能切主的先切主

  C — Collect（收集）
    在恢复的同时或之后，立即收集证据
    error log、slow log、processlist、InnoDB status
    OS 级指标（CPU、内存、IO、网络）
    不要急着清理现场

  C — Cause（定因）
    基于收集到的证据分析根因
    时间线还原：故障发生前后各发生了什么
    排除法：逐一排除可能的原因

  A — Action（行动）
    制定和实施修复方案
    验证修复效果
    更新运维文档和监控告警

关键原则：
  ① 先恢复后分析（MTTR 比 MTBF 更重要）
  ② 不要在生产环境做实验
  ③ 变更前先备份
  ④ 每次故障都写 Post-Mortem
```

#### 第一响应清单

```bash
收到告警后的标准动作（60 秒内完成）：

  # 1. MySQL 是否还活着？
  mysqladmin -h 127.0.0.1 -u root -p ping
  # 或
  mysql -e "SELECT 1"

  # 2. 系统资源概览
  top -bn1 | head -20        # CPU/内存
  iostat -x 1 3              # 磁盘 IO
  df -h                      # 磁盘空间
  free -h                    # 内存

  # 3. MySQL 进程状态
  mysql -e "SHOW PROCESSLIST" | head -30
  mysql -e "SHOW GLOBAL STATUS LIKE 'Threads%'"
  mysql -e "SHOW GLOBAL STATUS LIKE 'Connections'"

  # 4. InnoDB 状态
  mysql -e "SHOW ENGINE INNODB STATUS\G" > /tmp/innodb_status_$(date +%s).txt

  # 5. 错误日志最后 50 行
  tail -50 /var/log/mysql/error.log

  # 6. 慢查询日志最近的条目
  tail -20 /var/log/mysql/slow.log
```



#### 常用诊断命令速查

```sql
-- 连接与线程
SHOW PROCESSLIST;
SHOW GLOBAL STATUS LIKE 'Threads%';
SHOW GLOBAL STATUS LIKE 'Max_used_connections';
SHOW GLOBAL STATUS LIKE 'Aborted%';

-- 锁与事务
SHOW ENGINE INNODB STATUS\G
SELECT * FROM information_schema.INNODB_TRX;
SELECT * FROM performance_schema.data_locks;
SELECT * FROM performance_schema.data_lock_waits;

-- 性能指标
SHOW GLOBAL STATUS LIKE 'Questions';
SHOW GLOBAL STATUS LIKE 'Com_select';
SHOW GLOBAL STATUS LIKE 'Com_insert';
SHOW GLOBAL STATUS LIKE 'Slow_queries';
SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool%';
SHOW GLOBAL STATUS LIKE 'Innodb_row_lock%';

-- 复制状态
SHOW REPLICA STATUS\G
SHOW BINARY LOGS;
SHOW MASTER STATUS;

-- 空间使用
SELECT table_schema, ROUND(SUM(data_length+index_length)/1024/1024/1024,2) AS gb
FROM information_schema.tables GROUP BY table_schema ORDER BY gb DESC;

-- 表分析
SHOW TABLE STATUS FROM mydb LIKE 'table_name'\G
ANALYZE TABLE mydb.table_name;
```

#### Post-Mortem 模板

每次生产故障后必须填写 Post-Mortem：

```sql
# 故障报告：[故障简述]
## 基本信息
- 发生时间：2024-06-15 03:25 UTC+8
- 持续时间：45 分钟
- 影响范围：订单服务写入不可用
- 严重等级：P1

## 时间线
- 03:25  监控告警：MySQL CPU 100%
- 03:28  DBA 响应，登录检查
- 03:30  发现大量 Sending data 状态的查询
- 03:32  定位到问题 SQL（缺失索引导致全表扫描）
- 03:35  KILL 问题查询，添加索引
- 03:40  CPU 降至正常，业务恢复
- 04:10  完成后续监控确认

## 根因分析
上线发布引入了新的查询 SQL，该 SQL 的 WHERE 条件缺少合适索引，
在高并发下导致大量全表扫描，CPU 打满。

## 修复措施
1. 紧急添加缺失索引
2. 优化 SQL 语句

## 后续改进
1. CI/CD 增加 SQL 审核流程（上线前 EXPLAIN 检查）
2. 增加 CPU 使用率 > 70% 的早期告警
3. 完善慢查询自动报告机制

## 教训
发布流程缺少 SQL 质量检查环节，新增的 SQL 应纳入 Review。
```







### 主从复制故障排查与修复

#### IO 线程故障排查

第一步：检查 网络连通性

第二步：用复制账户验证

第三步：检查 binlog 是否被清理

第四步：检查 SSL/TLS 配置是否匹配

> [!important]
>
> **第一步：检查 网络连通性**
>
> ```shell
> ping 192.168.1.100			# 在从库上测试能否连通主库
> telnet 192.168.1.100 3306	# 测试 3306 端口是否可达
> nc -zv 192.168.1.100 3306	# 或者用 nc
> ```
>
> > 如果 ping 不通或端口不通，先查防火墙和安全组
> >
> > （`iptables -L -n | grep 3306`、`firewall-cmd --list-ports`，云服务器查控制台安全组规则）
>
> **第二步：用复制账户验证**
>
> ```shell
> # 在从库上用复制账户直接连主库试试
> mysql -h 192.168.1.100 -u repl -p'Repl_P@ss123' -e "SELECT 1"
> # ERROR 1045 对应的是密码错误
> # Host 'xxx is not allowed` 则是 host 不对
> ```
>
> **第三步：检查 binlog 是否被清理**
>
> ```shell
> # 错误编码
> error 1236 
> 
> # 排查
> SHOW BINARY LOGS;	# -- 在主库上查看当前可用的 binlog
> SHOW REPLICA STATUS\G	# 在从库上查看它需要的位点（ 看 Source_Log_File 和 Read_Source_Log_Pos ）
> 
> # 如果从库需要的 binlog 确实没了，没法跳过，只能重建从库
> # 后续，设置合理的 binlog 过期时间预防这个问题
> -- MySQL 8.0+
> SET GLOBAL binlog_expire_logs_seconds = 604800;  -- 7 天
> -- MySQL 5.7
> SET GLOBAL expire_logs_days = 7;
> ```
>
> **第四步：检查 SSL/TLS 配置是否匹配**
>
> ```shell
> 如果主库开启了 `require_secure_transport = ON`，但从库连接时没配 SSL，也会被拒绝：
> -- 从库配置 SSL 连接
> STOP REPLICA;
> CHANGE REPLICATION SOURCE TO
>   SOURCE_SSL = 1,
>   SOURCE_SSL_CA = '/etc/mysql/ssl/ca.pem',
>   SOURCE_SSL_CERT = '/etc/mysql/ssl/client-cert.pem',
>   SOURCE_SSL_KEY = '/etc/mysql/ssl/client-key.pem';
> START REPLICA;
> ```



#### SQL 线程故障排查

1. Error 1062：主键冲突
2. Error 1032：记录不存在
3. DDL 冲突

> [!important]
>
> 1. **Error 1062：主键冲突**
>
>    > [!tip]
>    >
>    > **原因**：从库上已经存在这条记录了。最常见的原因是有人在从库上做了写操作
>    >
>    > **排查：**-- 查看冲突的记录 （ 在主库执行同样的查询 ）
>    >
>    > - `SELECT * FROM db_name.table_name WHERE id = 12345;`
>    >
>    > **处理：**删除从库上冲突的记录，让复制重新回放
>    >
>    > - `DELETE FROM db_name.table_name WHERE id = 12345;`
>    > - `START REPLICA;`
>
> 2. **Error 1032：记录不存在**
>
>    > [!tip]
>    >
>    > **原因**：主库上执行了 UPDATE 或 DELETE，但从库上这条记录不存在。说明之前某个时刻从库丢了数据。
>    >
>    > **处理方案**：
>    >
>    > - -- 查看主库上这条记录的完整数据
>    >   `SELECT * FROM db_name.table_name WHERE id = 12345;`
>    > - -- 在从库上手动补回来
>    >   `INSERT INTO db_name.table_name VALUES (...);`
>    >   `START REPLICA;`
>
> 3. **DDL 冲突**
>
>    > [!tip]
>    >
>    > **原因**：主库执行了`CREATE TABLE`但从库上表已存在（或反过来，主库 `DROP TABLE` 但从库上表不存在）。
>    >
>    > **处理方案**：根据实际情况调整从库的表结构，使其与主库一致后重新启动复制。



#### 主从数据一致性校验工具

pt-table-checksum 工具

Percona Toolkit 提供的 `pt-table-checksum` 是业界标准的一致性校验工具。

```shell
# ===============================================
# 安装
# ===============================================
yum install -y percona-toolkit    # CentOS/RHEL
apt-get install -y percona-toolkit # Ubuntu/Debian
pt-table-checksum --version        # 验证

# ===============================================
# 使用
# ===============================================
# 1. 先创建校验账户
CREATE USER 'checksum_user'@'%' IDENTIFIED BY 'Check_P@ss123';
GRANT SELECT, PROCESS, SUPER, REPLICATION SLAVE ON *.* TO 'checksum_user'@'%';
GRANT ALL PRIVILEGES ON percona.* TO 'checksum_user'@'%';

# 2. 在主库上执行校验
pt-table-checksum \
  --host=127.0.0.1 --port=3306 \
  --user=checksum_user --password='Check_P@ss123' \
  --databases=mydb \
  --replicate=percona.checksums \
  --no-check-binlog-format \
  --recursion-method=processlist
# 常用参数：--tables（指定表）、--chunk-size（chunk 行数，默认 1000）

# 3. 结果分析
            TS ERRORS  DIFFS     ROWS  DIFF_ROWS  CHUNKS SKIPPED    TIME TABLE
03-15T10:05:00      0      0    10000          0       10       0   0.512 mydb.users
03-15T10:05:01      0      2     5000        156        5       0   0.308 mydb.orders
03-15T10:05:01      0      0      200          0        1       0   0.105 mydb.config

| 列        | 含义                                   
| ERRORS    | 执行错误数                             
| DIFFS     | 有差异的 chunk 数。**非 0 就是有问题
| ROWS      | 表的总行数                             
| DIFF_ROWS | 预估不一致的行数                      
| CHUNKS    | 分成了多少个 chunk                     
| SKIPPED   | 跳过的 chunk 数      
```

> [!warning]
>
> - `pt-table-checksum` 在主库上执行时会短暂加锁，对线上业务有一定影响。
> - 建议在业务低峰期执行，或使用 `--chunk-time=0.5` 控制每个 chunk 的执行时间。

#### 数据不一致修复

1 小范围修复：pt-table-sync

2 小范围修复：手动补数据

3 大范围不一致：重建从库

> [!important]
>
> ```shell
> pt-table-sync  可以修复 pt-table-checksum 发现的不一致数据。
> ```
>
> 1. **小范围修复：pt-table-sync、手动补数据**
>
>    pt-table-sync 可以修复 pt-table-checksum  发现的不一致数据。
>
>    ```shell
>    # 先预览要修复的内容（--print 只打印不执行）
>    pt-table-sync \
>      --replicate=percona.checksums \
>      --sync-to-master \
>      h=192.168.1.101,u=checksum_user,p='Check_P@ss123' \
>      --databases=mydb \
>      --tables=orders \
>      --print
>
>    # 确认无误后执行修复（--execute）
>    pt-table-sync \
>      --replicate=percona.checksums \
>      --sync-to-master \
>      h=192.168.1.101,u=checksum_user,p='Check_P@ss123' \
>      --databases=mydb \
>      --tables=orders \
>      --execute
>    ```
>
>    如果只是少量几条记录，手动处理更可控：
>
>    ```shell
>    -- 在主库上导出缺失的数据
>    SELECT * FROM mydb.orders WHERE id IN (101, 102, 103) 
>    INTO OUTFILE '/tmp/fix_data.csv';
>
>    -- 通过复制自动同步到从库（推荐，在主库执行）
>    REPLACE INTO mydb.orders SELECT * FROM mydb.orders WHERE id IN (101, 102, 103);
>    -- REPLACE 会覆盖已存在的记录，不存在的就插入
>    ```
>
> 2. **大范围不一致：重建从库**
>
>    如果不一致的数据量很大（几十张表、几万行），修修补补不现实，直接重建从库更快更可靠。
>
>    **重建步骤（使用 Xtrabackup）**：
>
>    ```bash
>    # 第一步：在主库上做全量备份
>    xtrabackup --backup --user=xtrabackup --password='Xtra_Str0ng!' \
>      --target-dir=/backup/rebuild --parallel=4
>          
>    # 第二步：传输到从库
>    rsync -avP /backup/rebuild/ slave_host:/backup/rebuild/
>          
>    # 第三步：在从库上 prepare
>    xtrabackup --prepare --target-dir=/backup/rebuild
>          
>    # 第四步：停止从库 MySQL，替换数据目录
>    systemctl stop mysqld
>    mv /var/lib/mysql /var/lib/mysql.bak
>    xtrabackup --move-back --target-dir=/backup/rebuild
>    chown -R mysql:mysql /var/lib/mysql
>          
>    # 第五步：启动并查看位点信息
>    systemctl start mysqld
>    cat /backup/rebuild/xtrabackup_binlog_info
>    # 输出类似：mysql-bin.000015  12345  3E11FA47-...:1-100
>          
>    # 第六步： 配置复制（二选一）
>    -- GTID 模式配置复制
>    RESET MASTER;
>    SET GLOBAL gtid_purged = '3E11FA47-71CA-11E1-9E33-C80AA9429562:1-100';
>    CHANGE REPLICATION SOURCE TO SOURCE_HOST='192.168.1.100', SOURCE_USER='repl',
>      SOURCE_PASSWORD='Repl_P@ss123', SOURCE_AUTO_POSITION=1;
>    START REPLICA;
>          
>    -- 传统模式配置复制
>    CHANGE REPLICATION SOURCE TO SOURCE_HOST='192.168.1.100', SOURCE_USER='repl',
>      SOURCE_PASSWORD='Repl_P@ss123', SOURCE_LOG_FILE='mysql-bin.000015',
>      SOURCE_LOG_POS=12345;
>    START REPLICA;
>    SHOW REPLICA STATUS\G
>    ```
>
> 

#### 复制延迟分析解决

复制没断，但 `Seconds_Behind_Source` 一直在涨——这说明从库的回放速度跟不上主库的写入速度。

Seconds_Behind_Source有局限性：不精确、大事物会失真、IO线程断了显示NULL

更准确的延迟监控方式是 `pt-heartbeat`：

```shell
# 在主库上启动心跳写入（每秒写一次）
pt-heartbeat --update --host=127.0.0.1 --user=heartbeat_user \
  --password='Hb_P@ss123' --database=percona --create-table --daemonize

# 在从库上监控延迟
pt-heartbeat --monitor --host=127.0.0.1 --user=heartbeat_user \
  --password='Hb_P@ss123' --database=percona
# 输出：0.00s [ 0.00s, 0.00s, 0.00s ]
#       当前延迟  1m平均  5m平均  15m平均
```

**复制延迟的主要原因:**MySQL 默认单线程回放 relay log

**解决措施：**开启并行复制可以大幅缓解

```shell
# my.cnf（从库）
[mysqld]
slave_parallel_workers = 8          # 并行线程数，建议 CPU 核数的一半
slave_parallel_type = LOGICAL_CLOCK  # 基于逻辑时钟的并行策略
slave_preserve_commit_order = ON     # 保持提交顺序
# MySQL 8.0.27+ 参数名变更为 replica_parallel_workers 等，功能一样

# 或者在线修改（无需重启）
STOP REPLICA;
SET GLOBAL slave_parallel_workers = 8;
SET GLOBAL slave_parallel_type = 'LOGICAL_CLOCK';
SET GLOBAL slave_preserve_commit_order = ON;
START REPLICA;

# 并行模式选择：
1. DATABASE			# 不同库的事务可以并行，适用于库架构
2. LOGICAL_CLOCK` 	# 同一组 commit 的事务可以并行，推荐，适合大多数场景
```



#### 大事物拆分

在主库上把大事务拆成小批次：

```shell
-- 不要这样：DELETE FROM logs WHERE create_time < '2024-01-01';
-- 这样做：分批删除
DELIMITER //
CREATE PROCEDURE batch_delete()
BEGIN
  DECLARE rows_affected INT DEFAULT 1;
  WHILE rows_affected > 0 DO
    DELETE FROM logs WHERE create_time < '2024-01-01' LIMIT 1000;
    SET rows_affected = ROW_COUNT();
    DO SLEEP(0.1);  -- 每批之间给从库喘息时间
  END WHILE;
END//
DELIMITER ;
CALL batch_delete();
```



### 1.启动故障

故障现象：mysqld 启动失败或启动后立即退出

排查步骤：

##### 步骤 1：查看错误日志

```bash
tail -100 /var/log/mysql/error.log
# 或
journalctl -u mysqld --no-pager -n 100
```

##### 步骤 2：根据错误信息分类处理

###### ── 错误：`InnoDB: Unable to lock ./ibdata1` ──

> [!tip]
>
> 原因：另一个 mysqld 进程占用了数据文件
> 处理：
>
> ```bash
> - ps aux | grep mysqld           # 确认是否有残留进程
> - kill <pid>                     # 杀掉残留进程
> - rm /var/lib/mysql/mysql.sock   # 清理 socket 文件
> - systemctl start mysqld
> ```

###### ── 错误：`Table 'mysql.user' doesn't exist` ──

> [!tip]
>
> 原因：系统表损坏或数据目录不完整
> 处理：
>
> ```bash
> mysqld --initialize --user=mysql --datadir=/var/lib/mysql
> # 会生成新的 root 临时密码，查看 error.log
> ```

###### ── 错误：`InnoDB: Corruption in redo log` ──

> [!tip]
>
> 原因：redo log 文件损坏（通常是非正常关机导致）
> 处理：
>
> ```bash
> # 危险操作！仅在无备份可恢复时使用
> mysqld --innodb-force-recovery=1  # 逐级提高 1-6
> # 启动后立即 mysqldump 导出数据
> # 然后重建实例导入
> ```
>
> 

###### ── 错误：`Can't open the mysql.plugin table` ──

> [!tip]
>
> 原因：mysql 系统库损坏
> 处理：
>
> ```bash
> mysql_upgrade --force
> ```

###### ── 错误：`Fatal error: Can't open and lock privilege tables` ──

> [!tip]
>
> 原因：权限表损坏
>
> 处理：
>
> ```bash
> mysqld --skip-grant-tables --skip-networking &
> mysql_upgrade --force
> # 然后正常重启
> ```
>
> 

── 错误：`InnoDB: Operating system error number 28` ──

> [!tip]
>
> 原因：磁盘空间满
> 处理：见下方「磁盘空间满」

##### innodb_force_recovery 级别说明：

  1 — 跳过损坏页（SRV_FORCE_IGNORE_CORRUPT）
  2 — 阻止后台操作运行（SRV_FORCE_NO_BACKGROUND）
  3 — 不做事务回滚（SRV_FORCE_NO_TRX_UNDO）
  4 — 不加载 insert buffer（SRV_FORCE_NO_IBUF_MERGE）
  5 — 不做 undo log 检查（SRV_FORCE_NO_UNDO_LOG_SCAN）
  6 — 不做 redo log 前滚（SRV_FORCE_NO_LOG_REDO）
  → 从 1 开始逐级尝试，能启动就立即导出数据



### 2.性能突降

##### 快速诊断

> [!important]
>
> 性能突降的排查流程（5 分钟内定位方向）：

```tex
┌──────────────────────────┐
  │ 性能突降告警             │
  └──────────┬───────────────┘
             │
  ┌──────────┴───────────────┐
  │ CPU 使用率 > 80%？        │
  ├── 是 → 查看 PROCESSLIST  │
  │        找到大量相同 SQL   │──→ 慢 SQL / 缺失索引
  │        找到大量锁等待     │──→ 死锁 / 长事务
  ├── 否 ↓                   │
  └──────────────────────────┘
  ┌──────────────────────────┐
  │ IO 使用率 > 80%？        │
  ├── 是 → iostat 确认       │
  │        随机读高           │──→ Buffer Pool 不足
  │        顺序写高           │──→ binlog/redo 写入风暴
  ├── 否 ↓                   │
  └──────────────────────────┘
  ┌──────────────────────────┐
  │ 连接数接近上限？          │
  ├── 是 → 大量 Sleep 连接   │──→ 连接池配置问题
  │        大量 active 连接   │──→ 慢 SQL 堆积
  ├── 否 ↓                   │
  └──────────────────────────┘
  ┌──────────────────────────┐
  │ 复制延迟 > 5s？          │
  ├── 是 → 主库写入暴增      │──→ 大批量 DML / DDL
  │        从库 IO 瓶颈       │──→ 从库磁盘性能不足
  ├── 否 ↓                   │
  └──────────────────────────┘
  │ 检查最近变更（发布、DDL） │──→ 回滚变更
```

快速诊断 SQL：

```sql
-- Top 10 当前活跃查询（按执行时间排序）
SELECT id, user, host, db, command, time, state,
  LEFT(info, 200) AS query
FROM information_schema.processlist
WHERE command != 'Sleep' AND info IS NOT NULL
ORDER BY time DESC
LIMIT 10;

-- Top 10 锁等待（MySQL 8.0 使用 performance_schema.data_lock_waits）
-- 注意：information_schema.innodb_lock_waits 已在 MySQL 8.0 中移除
SELECT
 waiting.trx_id AS waiting_trx,
 waiting.trx_mysql_thread_id AS waiting_pid,
 LEFT(waiting.trx_query, 100) AS waiting_query,
 blocking.trx_id AS blocking_trx,
 blocking.trx_mysql_thread_id AS blocking_pid,
 LEFT(blocking.trx_query, 100) AS blocking_query,
 TIMESTAMPDIFF(SECOND, waiting.trx_wait_started, NOW()) AS wait_seconds
FROM performance_schema.data_lock_waits w
JOIN information_schema.innodb_trx waiting ON w.REQUESTING_ENGINE_TRANSACTION_ID = waiting.trx_id
JOIN information_schema.innodb_trx blocking ON w.BLOCKING_ENGINE_TRANSACTION_ID = blocking.trx_id
ORDER BY wait_seconds DESC;

-- Buffer Pool 命中率
SELECT
    (1 - Innodb_buffer_pool_reads / Innodb_buffer_pool_read_requests) * 100
    AS hit_rate_pct
FROM (
    SELECT
      VARIABLE_VALUE AS Innodb_buffer_pool_reads
    FROM performance_schema.global_status
    WHERE VARIABLE_NAME = 'Innodb_buffer_pool_reads'
  ) a, (
    SELECT
      VARIABLE_VALUE AS Innodb_buffer_pool_read_requests
    FROM performance_schema.global_status
    WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests'
  ) b;
```

##### 慢 SQL 紧急处理

```sql
当某条 SQL 导致整个数据库卡住时的紧急处理：

  步骤 1：找到问题 SQL
    SHOW FULL PROCESSLIST;
    -- 找到 Time 值很大、State 为 Sending data 或 Sorting 的查询

  步骤 2：KILL 掉问题查询
    KILL <thread_id>;

  步骤 3：如果 KILL 无效（常见于大事务回滚）
    -- 检查是否在回滚中
    SHOW ENGINE INNODB STATUS\G
    -- 查看 TRANSACTIONS 部分的 "rolling back" 信息
    -- 回滚中的事务不能 KILL，只能等待

  步骤 4：防止问题 SQL 再次执行
    -- 临时方案：设置执行时间限制
    SET GLOBAL max_execution_time = 30000;  -- 30 秒超时

    -- 或通过 ProxySQL 规则拦截
    INSERT INTO mysql_query_rules (rule_id, match_pattern, error_msg)
    VALUES (999, 'SELECT.*FROM huge_table.*WHERE.*type', 'Query blocked by DBA');

  步骤 5：后续优化
    EXPLAIN 分析执行计划
    补充缺失索引
    改写 SQL
```



### 3.复制中断

常见复制故障:

##### 故障一：SQL 线程报错停止

```sql
SHOW REPLICA STATUS\G
  # Last_SQL_Error: Error 'Duplicate entry...' on query...
  # Replica_SQL_Running: No

处理方案：

    方案 A：跳过错误（数据可能不一致）
      SET GLOBAL sql_slave_skip_counter = 1;
      START REPLICA;

    方案 B：GTID 模式下跳过
      SET GTID_NEXT = 'xxxx-xxxx:N';  -- 填入出错的 GTID
      BEGIN; COMMIT;                   -- 创建空事务
      SET GTID_NEXT = 'AUTOMATIC';
      START REPLICA;

    方案 C：重建从库（推荐，确保数据一致）
      mysqldump --single-transaction --master-data=2 全库导出
      在从库恢复后重新配置复制
```

##### 故障二：IO 线程断开

```sql
# Last_IO_Error: Got fatal error 1236 from master...
# Replica_IO_Running: No

常见原因：
    主库 binlog 被 purge → 从库需要的 binlog 已不存在
    网络中断 → 检查网络连通性
    认证失败 → 检查复制用户密码

处理：
    -- 检查主库 binlog 列表
    SHOW BINARY LOGS;

    -- 如果需要的 binlog 已被 purge
    -- 必须重建从库（全量 + 增量）

    -- 如果是网络问题，恢复网络后
    START REPLICA;
```

##### 故障三：复制延迟持续增大



```bash
# Seconds_Behind_Source: 3600（延迟 1 小时）

排查：
    -- 检查从库 SQL 线程在执行什么
    SHOW REPLICA STATUS\G
    # 查看 Relay_Master_Log_File 和 Exec_Master_Log_Pos

    -- 检查是否有大事务在回放
    -- 检查从库 IO 是否瓶颈
    iostat -x 1 5

处理：
    -- 开启并行复制
    SET GLOBAL replica_parallel_workers = 8;
    SET GLOBAL replica_parallel_type = 'LOGICAL_CLOCK';
    STOP REPLICA; START REPLICA;

    -- 如果是大事务导致的
    -- 等待当前事务回放完成，然后优化源头的大事务
```





### 4.磁盘空间满

磁盘满是最常见也最紧急的故障之一

现象：

```bash
  MySQL 无法写入，报错 Error number 28 (No space left on device)
  INSERT/UPDATE 全部失败
  可能导致表损坏
```

紧急处理（5 分钟内释放空间）：

##### 1.确认哪个分区满了

使用命令：`df -h`

##### 2.快速释放空间的方法（按优先级）

```bash
# 方法 A：清理 binlog（效果最大，通常 GB 级）
  mysql -e "PURGE BINARY LOGS BEFORE NOW() - INTERVAL 1 DAY;"
  # 或
  mysql -e "PURGE BINARY LOGS TO 'mysql-bin.000050';"
  
  # 方法 B：清理慢查询日志
  > /var/log/mysql/slow.log    # 清空文件但不删除
  mysql -e "FLUSH SLOW LOGS;"  # 重新打开日志文件
  
  # 方法 C：清理错误日志
  > /var/log/mysql/error.log
  mysql -e "FLUSH ERROR LOGS;"
  
  # 方法 D：清理临时文件
  ls -lhS /tmp/                # 查看大文件
  rm /tmp/MLz*                 # 清理 MySQL 临时文件
  
  # 方法 E：删除不需要的大表（谨慎）
  DROP TABLE IF EXISTS debug_log_backup;
```

##### 3.确认空间已释放

使用命令：` df -h`

##### 4.MySQL 恢复后验证

```sql
  mysql -e "SELECT 1"
  mysql -e "INSERT INTO test_table VALUES (1)"  # 测试写入
```

##### 根因分析：

```bash
# 查看空间占用分布
  SELECT
    table_schema AS db,
    ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) AS size_gb
  FROM information_schema.tables
  GROUP BY table_schema
  ORDER BY size_gb DESC;
  # 查看最大的表
  SELECT table_schema, table_name,
    ROUND(data_length / 1024 / 1024 / 1024, 2) AS data_gb,
    ROUND(index_length / 1024 / 1024 / 1024, 2) AS index_gb,
    table_rows
  FROM information_schema.tables
  ORDER BY data_length + index_length DESC
  LIMIT 20;
```

##### 长期方案：

- 设置 binlog_expire_logs_seconds = 604800（7 天）
- 配置磁盘使用率告警（> 80% 告警）
- 制定数据归档策略
- 定期清理无用的大表和索引





### 5.OOM（内存溢出）

**现象：**

```bash
mysqld 被 OOM Killer 杀死
dmesg 或 /var/log/messages 中看到 "Out of memory: Kill process"
```

**确认 OOM：**

```bash
# 查看系统日志
  dmesg | grep -i "oom\|kill" | tail -20
# 或
  grep -i "oom\|kill" /var/log/messages | tail -20
  
# 查看 MySQL 是否被 OOM Kill
  grep mysqld /var/log/messages | grep -i kill
```

常见原因和处理如下：

##### 原因一：innodb_buffer_pool_size 设置过大

```bash
处理：
      # 查看当前设置
      mysql -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size'"
      
      # 调整为物理内存的 60-70%（给 OS 和其他进程留余量）
      SET GLOBAL innodb_buffer_pool_size = 12G;  -- 在线调整（8.0）
      
      # 同时修改 my.cnf 持久化
```

##### 原因二：大量连接各自消耗内存

每个连接约消耗：
      sort_buffer_size（默认 256KB）
      join_buffer_size（默认 256KB）
      read_buffer_size（默认 128KB）
      read_rnd_buffer_size（默认 256KB）
      thread_stack（默认 256KB）
      net_buffer_length（默认 16KB）
    → 500 个连接额外消耗约 500 × 1MB ≈ 500MB

```bash
# 处理：
     减少 max_connections
     减小 per-connection buffer 大小
     优化连接池，减少空闲连接
```

##### 原因三：临时表过大

大量 ORDER BY / GROUP BY 导致磁盘临时表tmp_table_size 和 max_heap_table_size 设置过大

```sql
# 处理：
SET GLOBAL tmp_table_size = 64M;
SET GLOBAL max_heap_table_size = 64M;
```

##### 原因四：Performance Schema 消耗过多

```sql
处理：
      # 关闭不需要的 instrument
      UPDATE performance_schema.setup_instruments
      SET ENABLED = 'NO', TIMED = 'NO'
      WHERE NAME LIKE 'wait/synch/%';
```



**内存使用估算公式：**

> [!note]
>
> ```bash
>   总内存 ≈ innodb_buffer_pool_size
>          + innodb_log_buffer_size
>          + key_buffer_size
>          + max_connections × (sort_buffer + join_buffer + read_buffer + thread_stack)
>          + tmp_table_size（可能多个）
>          + performance_schema 内存
>          + OS 需要 1-2GB
> ```



### 6.死锁处理

死锁检测与处理：

```bash
# 1. 查看最近的死锁信息
  SHOW ENGINE INNODB STATUS\G
# 找到 "LATEST DETECTED DEADLOCK" 部分

# 2. 开启死锁日志（记录所有死锁，不仅是最后一次）
  SET GLOBAL innodb_print_all_deadlocks = ON;
# 死锁信息会写入 error log

# 3. 解读死锁日志
  # 关键信息：
  #   TRANSACTION 1：持有锁 A，等待锁 B
  #   TRANSACTION 2：持有锁 B，等待锁 A
  #   WE ROLL BACK TRANSACTION 2（MySQL 自动回滚代价较小的事务）
```

死锁常见模式和解决：

```bash
 模式一：两个事务交叉更新
    TX1: UPDATE t SET a=1 WHERE id=1; UPDATE t SET a=2 WHERE id=2;
    TX2: UPDATE t SET a=3 WHERE id=2; UPDATE t SET a=4 WHERE id=1;
    → 解决：统一按 id 升序更新

  模式二：间隙锁冲突
    TX1: SELECT * FROM t WHERE id > 10 FOR UPDATE;（加间隙锁）
    TX2: INSERT INTO t (id) VALUES (15);（等待间隙锁）
    → 解决：缩小锁范围，使用精确条件

  模式三：唯一索引 + INSERT
    TX1: INSERT INTO t (unique_col) VALUES ('a');
    TX2: INSERT INTO t (unique_col) VALUES ('a');
    → 解决：使用 INSERT ... ON DUPLICATE KEY UPDATE
```

通用预防措施：

```bash
    事务尽可能短小
    按固定顺序访问表和行
    使用合理的索引减少锁范围
    避免大范围的 FOR UPDATE
    设置合理的 innodb_lock_wait_timeout（默认 50 秒）
```

### 7.连接问题

##### 连接数耗尽

现象：`Too many connections`

紧急处理：

```bash
# 1. 用超级用户连接（max_connections + 1 保留给 SUPER 用户）
    mysql -u root -p

# 2. 查看连接分布
    SELECT user, host, db, command, COUNT(*) AS cnt
    FROM information_schema.processlist
    GROUP BY user, host, db, command
    ORDER BY cnt DESC;

# 3. 杀掉空闲连接
    SELECT CONCAT('KILL ', id, ';')
    FROM information_schema.processlist
    WHERE command = 'Sleep' AND time > 300;  -- 空闲超过 5 分钟
    -- 复制输出执行

# 4. 临时增大连接数
    SET GLOBAL max_connections = 2000;

# 5. 降低空闲超时
    SET GLOBAL wait_timeout = 300;
    SET GLOBAL interactive_timeout = 300;
```

**根因分析：**

- 应用连接池配置不当（maxPoolSize 过大）
- 连接泄漏（获取连接后未释放）
- 慢查询堆积导致连接排队

##### 连接超时

现象：`Can't connect to MySQL server / Connection timed out`

排查步骤：

```bash
    # 1. MySQL 进程是否存在
    ps aux | grep mysqld
    systemctl status mysqld
    
    # 2. 端口是否监听
    ss -tlnp | grep 3306
    netstat -tlnp | grep 3306
    
    # 3. 网络是否连通
    telnet db_host 3306
    nc -zv db_host 3306
    
    # 4. 防火墙规则
    iptables -L -n | grep 3306
    # 云服务器检查安全组
    
    # 5. MySQL 是否绑定了 127.0.0.1
    mysql -e "SHOW VARIABLES LIKE 'bind_address'"
    # 如果是 127.0.0.1，需要改为 0.0.0.0
    
    # 6. 用户权限是否允许远程连接
    SELECT user, host FROM mysql.user WHERE user = 'app_user';
    # host 如果是 localhost，无法远程连接
    # 需要 GRANT ... TO 'app_user'@'%'
```



### 8.数据损坏

关于表损坏检测与修复，InnoDB 表损坏（较少见但影响大）：

检测：

```sql
CHECK TABLE mydb.damaged_table;
# 或批量检查
mysqlcheck --check --all-databases -u root -p
```

修复方案（按严重程度递进）：

```sql
  级别一：优化表修复
    OPTIMIZE TABLE mydb.damaged_table;
    # 重建表，修复碎片和轻微损坏
    
  级别二：ALTER TABLE 重建
    ALTER TABLE mydb.damaged_table ENGINE=InnoDB;
    # 完全重建表结构和数据
    
  级别三：导出导入
    mysqldump mydb damaged_table > /tmp/repair.sql
    DROP TABLE damaged_table;
    mysql mydb < /tmp/repair.sql
    
  级别四：innodb_force_recovery 抢救
    # 见启动故障章节
    # 以 force_recovery 模式启动
    # 导出所有能导出的数据
    # 重建实例后导入
```

MyISAM 表修复（如果还有 MyISAM 表）：

```bash
REPAIR TABLE myisam_table;
# 或
myisamchk --recover /var/lib/mysql/mydb/myisam_table
```







## Oracle 应急手册

## 达梦 应急手册