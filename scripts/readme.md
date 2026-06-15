# Scripts / 运维脚本

> 本目录存放 MySQL 数据库的**自动化运维脚本**，涵盖备份、恢复、日常维护等场景。

## 📁 目录结构

```tex
scripts/
├── backup/ # 备份脚本
├── recover/ # 恢复脚本
└── maintenance/ # 日常维护脚本
```

## 🛠️ 模块说明

### Backup（备份脚本）

- **用途**：数据库备份自动化脚本
- **状态**：🚧 维护中
- **计划内容**：
  - 全量备份脚本（mysqldump / Xtrabackup）
  - 增量备份脚本
  - binlog 归档脚本

### Recover（恢复脚本）

- **用途**：数据库恢复与验证脚本
- **状态**：🚧 维护中
- **计划内容**：
  - 备份恢复验证脚本
  - 时间点恢复（PITR）脚本
  - 全量恢复脚本

### Maintenance（日常维护脚本）

- **用途**：日常巡检与维护脚本
- **状态**：🚧 维护中
- **计划内容**：
  - 健康检查脚本
  - 慢查询报告脚本
  - 主从复制监控脚本
  - 磁盘空间监控脚本
  - 死锁监控脚本

## 📊 归档进度

| 模块        | 状态     | 进度 | 预计完成 |
| ----------- | -------- | ---- | -------- |
| backup      | 🚧 维护中 | 10%  | 待定     |
| recover     | 🚧 维护中 | 0%   | 待定     |
| maintenance | 🚧 维护中 | 20%  | 待定     |

## 🔗 相关文档

- [备份操作步骤](../runbook/02-backup-recovery/backup-procedures.md)
- [恢复演练手册](../runbook/02-backup-recovery/recovery-playbook.md)
- [健康检查脚本使用说明](./maintenance/health-check.sh)

---

**最后更新**：2026-06-15
**维护人**：yang-dba