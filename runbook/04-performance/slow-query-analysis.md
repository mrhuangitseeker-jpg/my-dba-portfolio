# 慢查询分析

## Mysql

### 0.慢查询治理流程

```bash
1. 发现慢查询
   └→ pt-query-digest 周报/日报
   └→ 监控告警（慢查询数量突增）

2. 排序优先级
   ├→ 总耗时最高的（影响最大）
   ├→ 执行次数最多的（优化收益最大）
   └→ 平均耗时最长的（单次最慢）

3. 分析原因
   ├→ EXPLAIN 查看执行计划
   ├→ EXPLAIN ANALYZE 查看实际耗时
   ├→ 检查索引是否合理
   └→ 检查统计信息是否准确

4. 实施优化
   ├→ 添加/调整索引
   ├→ 改写 SQL
   ├→ 调整参数
   └→ 架构优化（缓存/读写分离）

5. 验证效果
   ├→ 对比优化前后的 EXPLAIN
   ├→ 观察慢查询日志是否减少
   └→ 持续监控 P95/P99 耗时
```

### 1.mysqldumpslow 分析

```bash
# 按查询时间降序，显示前 10 条
mysqldumpslow -s t -t 10 /var/log/mysql/slow.log

# 按执行次数降序
mysqldumpslow -s c -t 10 /var/log/mysql/slow.log

# 按平均查询时间降序
mysqldumpslow -s at -t 10 /var/log/mysql/slow.log

# 按扫描行数降序
mysqldumpslow -s r -t 10 /var/log/mysql/slow.log
```

输出示列

```bash
Count: 1523  Time=2.35s (3581s)  Lock=0.00s (0s)  Rows=10.0 (15230), app_user[app_user]@web-server
  SELECT * FROM orders WHERE status = 'S' AND created_at > 'S' ORDER BY amount DESC LIMIT N;

解读：
  Count: 1523    → 该查询模式执行了 1523 次
  Time=2.35s     → 平均耗时 2.35 秒
  (3581s)        → 总耗时 3581 秒
  Rows=10.0      → 平均返回 10 行
  'S' 和 N       → 字符串和数字被参数化
```



### 2.pt-query-digest 深度分析

安装

```bash
# Debian/Ubuntu
apt-get install percona-toolkit

# CentOS/RHEL
yum install percona-toolkit

# 或直接下载单文件
wget https://raw.githubusercontent.com/percona/percona-toolkit/3.x/bin/pt-query-digest
chmod +x pt-query-digest
```

**基本用法**

```bash
# 分析慢查询日志
pt-query-digest /var/log/mysql/slow.log

# 只分析最近 24 小时
pt-query-digest --since '24h' /var/log/mysql/slow.log

# 输出到文件
pt-query-digest /var/log/mysql/slow.log > /tmp/slow-report.txt

# 只显示前 20 个查询
pt-query-digest --limit 20 /var/log/mysql/slow.log

# 过滤特定数据库
pt-query-digest --filter '$event->{db} eq "mydb"' /var/log/mysql/slow.log
```

关键指标：

- **95%**：P95 耗时，95% 的查询在此时间内完成
- **Rows examine / Rows sent 比值**：越大越需要优化
- **Response time**：该查询模式的总耗时和占比
- **R/Call**：每次调用的平均耗时
- **V/M**：方差/均值比（越大说明性能波动越大）

**高级用法**

```bash
# 对比两个时间段的慢查询
pt-query-digest --since '2024-06-14' --until '2024-06-15' /var/log/mysql/slow.log > day1.txt
pt-query-digest --since '2024-06-15' --until '2024-06-16' /var/log/mysql/slow.log > day2.txt

# 只看执行超过 5 秒的查询
pt-query-digest --filter '$event->{Query_time} > 5' /var/log/mysql/slow.log

# 只看扫描行数超过 10 万的查询
pt-query-digest --filter '$event->{Rows_examined} > 100000' /var/log/mysql/slow.log

# 输出为 JSON 格式
pt-query-digest --output json /var/log/mysql/slow.log

# 从 PROCESSLIST 实时分析（不依赖慢查询日志）
pt-query-digest --processlist h=127.0.0.1 --interval 1
```

### 3.实时慢查询监控

通过 Performance Schema 监控

```bash
-- 启用 events_statements 消费者（通常默认开启）
UPDATE performance_schema.setup_consumers
SET ENABLED = 'YES'
WHERE NAME = 'events_statements_history_long';

-- 查看当前最慢的 TOP 10 SQL（按总耗时）
SELECT
  DIGEST_TEXT,
  COUNT_STAR AS exec_count,
  ROUND(SUM_TIMER_WAIT / 1e12, 2) AS total_sec,
  ROUND(AVG_TIMER_WAIT / 1e12, 4) AS avg_sec,
  SUM_ROWS_EXAMINED,
  SUM_ROWS_SENT,
  FIRST_SEEN,
  LAST_SEEN
FROM performance_schema.events_statements_summary_by_digest
ORDER BY SUM_TIMER_WAIT DESC
LIMIT 10;
```

通过 sys Schema 快速查询

```bash
-- 最耗时的 SQL
SELECT * FROM sys.statements_with_runtimes_in_95th_percentile LIMIT 10;

-- 全表扫描的 SQL
SELECT * FROM sys.statements_with_full_table_scans LIMIT 10;

-- 使用临时表的 SQL
SELECT * FROM sys.statements_with_temp_tables LIMIT 10;

-- 排序量大的 SQL
SELECT * FROM sys.statements_with_sorting LIMIT 10;
```









## Oracle

## 达梦
