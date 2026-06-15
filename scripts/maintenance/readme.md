# Maintenance / 日常维护脚本

> 本目录存放 MySQL 数据库的**日常维护与监控**脚本，涵盖健康检查、慢查询分析、主从复制监控等场景。

## 📄 脚本列表

| 脚本名称               | 用途                                  | 状态     | 最后更新   |
| ---------------------- | ------------------------------------- | -------- | ---------- |
| `mysql_healthcheck.sh` | MySQL DBA 日常速查清单/自动化巡检报告 | ✅ 已完成 | 2026-06-15 |
| `slow-query-report.sh` | 慢查询定期巡检脚本                    | ✅ 已完成 | 2026-06-15 |
| `replica_monitor.sh`   | 主从复制故障自动化监控脚本            | ✅ 已完成 | 2026-06-14 |

---

## 🔧 脚本说明

### 1. mysql_healthcheck.sh

**描述**：

- MySQL DBA 日常速查清单 / 自动化巡检报告脚本。
- 采集实例健康、
- 性能指标、
- 安全检查、
- 备份状态、
- 复制状态等五大维度信息，生成结构化报告。

**使用说明：**

##### 1.1 修改配置

打开脚本，修改开头的连接信息（或通过命令行参数传入）：

```bash
MYSQL_USER="root"
MYSQL_PASS="你的密码"
```

##### 1.2 添加执行权限

```bash
chmod +x mysql_healthcheck.sh
```

##### 1.3 执行脚本

```bash
# 使用默认配置
./mysql_healthcheck.sh

# 指定连接参数
./mysql_healthcheck.sh -h 192.168.1.100 -P 3306 -u dba_user -p 'password'

# 使用环境变量
export MYSQL_HOST=192.168.1.100
export MYSQL_USER=dba
export MYSQL_PASS=password
./mysql_healthcheck.sh
```

##### 1.4 输出示例

```text
╔════════════════════════════════════════════════════════════════════════════════════╗
║                         MySQL 自动化巡检报告                                        ║
╠════════════════════════════════════════════════════════════════════════════════════╣
║  巡检时间：2026-06-15 10:30:00                                                      ║
║  目标主机：127.0.0.1:3306                                                          ║
║  报告文件：/tmp/mysql_healthcheck/report_20260615_103000.txt                       ║
╚════════════════════════════════════════════════════════════════════════════════════╝

✅ 连接成功
...
【巡检总结】
巡检完成！
  ⚡ 警告项：2
  ❌ 严重项：0
```

##### 1.5 定时巡检配置（Cron）

```bash
# 每日巡检（早上 7 点执行，邮件发送报告）
0 7 * * * /opt/scripts/mysql_healthcheck.sh \
  -h 127.0.0.1 -u monitor -p 'MonPass!' \
  2>&1 | mail -s "MySQL 日巡检报告 $(date +\%F)" dba@example.com

# 每周深度巡检（周一 6 点）
0 6 * * 1 /usr/bin/python3 /opt/scripts/mysql_inspector.py \
  >> /var/log/mysql_inspection.log 2>&1

# 巡检报告保留 90 天
0 3 * * * find /tmp/mysql_healthcheck -name "*.txt" -mtime +90 -delete
```

##### 1.6 巡检报告归档策略

```text
巡检报告管理策略：
  ├── 日报（每日）
  │   ├── 文本报告 → 邮件发送 + 本地保留 30 天
  │   └── JSON 报告 → 写入数据库，用于趋势分析
  ├── 周报（每周一）
  │   ├── 包含本周趋势对比
  │   └── 标注新增/解决的告警项
  └── 月报（每月 1 日）
      ├── 容量规划建议
      ├── 性能趋势图
      └── 安全合规检查清单
```

---

### 2. slow-query-report.sh

**描述**：慢查询定期巡检脚本。自动分析慢查询日志，生成慢查询报告，帮助定位性能瓶颈。

**使用说明：**

```bash
# 添加执行权限
chmod +x slow-query-report.sh

# 执行脚本
./slow-query-report.sh

# 配合 crontab 每日执行
0 8 * * * /path/to/slow-query-report.sh >> /var/log/slow_query_report.log 2>&1
```

**依赖工具**：`pt-query-digest`（Percona Toolkit）

---

### 3. replica_monitor.sh

**描述**：主从复制故障自动化监控脚本。周期性检查 `SHOW REPLICA STATUS`，判断 `Replica_IO_Running` 和 `Replica_SQL_Running` 状态，异常时发送告警。

**使用说明：**

```bash
# 添加执行权限
chmod +x replica_monitor.sh

# 手动执行测试
./replica_monitor.sh

# crontab 配置（每分钟检查一次）
* * * * * /opt/scripts/replica_monitor.sh || /opt/scripts/send_alert.sh "MySQL 复制异常"
```

**监控指标**：
- `Replica_IO_Running`：IO 线程状态
- `Replica_SQL_Running`：SQL 线程状态
- `Seconds_Behind_Source`：主从延迟秒数

---

## 📊 归档进度

| 脚本                 | 状态     | 进度 |
| -------------------- | -------- | ---- |
| mysql_healthcheck.sh | ✅ 已完成 | 100% |
| slow-query-report.sh | ✅ 已完成 | 100% |
| replica_monitor.sh   | ✅ 已完成 | 100% |

## 🔗 相关文档

- [监控阈值参考表](../../runbook/04-performance/monitoring-thresholds.md)
- [每日巡检清单](../../runbook/01-daily-checks/morning-checklist.md)
- [主从复制故障排查](../../runbook/03-incident-response/p0-runbook.md)

