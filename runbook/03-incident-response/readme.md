# 03-incident-response / 故障应急

> 本目录存放 MySQL 数据库的**故障应急**相关 SOP（标准操作流程）文档，涵盖 P0 故障应急手册和故障升级矩阵。

## 📄 文档列表

| 文档名称               | 用途            | 状态     | 最后更新   |
| ---------------------- | --------------- | -------- | ---------- |
| `p0-runbook.md`        | P0 故障应急手册 | ✅ 已完成 | 2026-06-15 |
| `escalation-matrix.md` | 故障升级矩阵    | ✅ 已完成 | 2026-06-14 |

## 🚧 待补充文档

| 文档名称                  | 计划用途             | 优先级 |
| ------------------------- | -------------------- | ------ |
| `post-mortem-template.md` | 故障复盘报告模板     | 低     |
| `common-errors.md`        | 常见错误码与解决方案 | 中     |
| `rollback-procedures.md`  | 紧急回滚操作指南     | 低     |

## 📖 文档说明

### p0-runbook.md

- **内容**：P0 级别故障应急处理手册
- **涵盖范围**：
  - 数据库宕机处理
  - 主从复制中断排查
  - 连接数爆满处理
  - 数据误删除恢复
  - 磁盘空间满处理
  - 性能突降排查
  - 死锁处理

### escalation-matrix.md

- **内容**：故障升级矩阵
- **涵盖范围**：
  - 故障等级定义（P0/P1/P2/P3）
  - 升级路径与时间线
  - 联系人矩阵
  - 故障上报模板
  - 常见故障参考

## 📊 归档进度

| 文档                    | 状态     | 进度 |
| ----------------------- | -------- | ---- |
| p0-runbook.md           | ✅ 已完成 | 100% |
| escalation-matrix.md    | ✅ 已完成 | 100% |
| common-errors.md        | 📅 计划中 | 0%   |
| post-mortem-template.md | 📅 计划中 | 0%   |

## 🔗 相关文档

- [巡检脚本](../../scripts/maintenance/mysql_healthcheck.sh)
- [备份恢复手册](../02-backup-recovery/recovery-playbook.md)
- [监控阈值参考表](../04-performance/monitoring-thresholds.md)
