# Recover / 恢复脚本

> 本目录存放 MySQL 数据库的**恢复与验证**相关脚本，用于数据恢复、备份有效性验证等场景。

## 📄 脚本列表

| 脚本名称             | 用途                   | 状态     | 最后更新   |
| -------------------- | ---------------------- | -------- | ---------- |
| `backup_validate.sh` | 备份恢复自动化验证脚本 | ✅ 已完成 | 2026-06-14 |

## 🚧 待补充脚本

| 脚本名称          | 计划用途               | 优先级 |
| ----------------- | ---------------------- | ------ |
| `pitr_recover.sh` | 时间点恢复（PITR）脚本 | 中     |
| `full_recover.sh` | 全量恢复脚本           | 中     |
| `inc_recover.sh`  | 增量恢复脚本           | 低     |

## 🔧 脚本说明

### backup_validate.sh

- **功能**：验证备份文件的有效性
- **使用方式**：
  ```bash
  chmod +x backup_validate.sh
  ./backup_validate.sh /path/to/backup/dir



## 📊 归档进度

| 脚本               | 状态     | 进度 |
| :----------------- | :------- | :--- |
| backup_validate.sh | ✅ 已完成 | 100% |
| pitr_recover.sh    | 📅 计划中 | 0%   |
| full_recover.sh    | 📅 计划中 | 0%   |



## 🔗 相关文档

- [备份操作步骤](https://../runbook/02-backup-recovery/backup-procedures.md)
- [恢复演练手册](https://../runbook/02-backup-recovery/recovery-playbook.md)