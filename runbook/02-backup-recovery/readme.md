# 02-backup-recovery / 备份恢复

> 本目录存放 MySQL 数据库的**备份与恢复**相关 SOP（标准操作流程）文档，涵盖备份操作步骤和恢复演练手册。

## 📄 文档列表

| 文档名称               | 用途         | 状态     | 最后更新   |
| ---------------------- | ------------ | -------- | ---------- |
| `backup-procedures.md` | 备份操作步骤 | ✅ 已完成 | 2026-06-14 |
| `recovery-playbook.md` | 恢复演练手册 | ✅ 已完成 | 2026-06-14 |

## 🚧 待补充文档

| 文档名称               | 计划用途                   | 优先级 |
| ---------------------- | -------------------------- | ------ |
| `pitr-guide.md`        | 时间点恢复（PITR）详细指南 | 中     |
| `backup-validation.md` | 备份验证流程               | 低     |
| `disaster-recovery.md` | 灾难恢复方案               | 低     |

## 📖 文档说明

### backup-procedures.md

- **内容**：数据库备份操作完整步骤
- **涵盖范围**：
  - 逻辑备份（mysqldump）
  - 物理备份（Xtrabackup 全量/增量）
  - binlog 备份与归档
  - 备份策略设计
  - 备份文件管理（压缩、加密、清理）

### recovery-playbook.md

- **内容**：数据库恢复演练手册
- **涵盖范围**：
  - 全量备份恢复
  - 增量备份恢复
  - 时间点恢复（PITR）
  - 表级恢复
  - 恢复验证流程

## 📊 归档进度

| 文档                 | 状态     | 进度 |
| -------------------- | -------- | ---- |
| backup-procedures.md | ✅ 已完成 | 100% |
| recovery-playbook.md | ✅ 已完成 | 100% |
| pitr-guide.md        | 📅 计划中 | 0%   |
| backup-validation.md | 📅 计划中 | 0%   |

## 🔗 相关文档

- [备份脚本](../../scripts/backup/)
- [恢复脚本](../../scripts/recover/)
- [P0 故障应急手册](../03-incident-response/p0-runbook.md)
