# Backup / 备份脚本

> 本目录存放 MySQL 数据库的**备份**相关脚本，用于全量备份、增量备份、binlog 归档等场景。

## 📄 脚本列表

| 脚本名称            | 用途                                   | 状态     | 最后更新 |
| ------------------- | -------------------------------------- | -------- | -------- |
| `full_backup.sh`    | 全量备份脚本（mysqldump / Xtrabackup） | 📅 计划中 | —        |
| `inc_backup.sh`     | 增量备份脚本                           | 📅 计划中 | —        |
| `binlog_backup.sh`  | binlog 归档脚本                        | 📅 计划中 | —        |
| `backup_cleanup.sh` | 过期备份清理脚本                       | 📅 计划中 | —        |

## 🚧 待补充脚本

| 脚本名称            | 计划用途                                 | 优先级 |
| ------------------- | ---------------------------------------- | ------ |
| `full_backup.sh`    | 全量备份（支持 mysqldump 和 Xtrabackup） | 高     |
| `inc_backup.sh`     | Xtrabackup 增量备份                      | 中     |
| `binlog_backup.sh`  | binlog 实时/定时归档                     | 中     |
| `backup_cleanup.sh` | 按保留策略清理过期备份                   | 低     |

## 🔧 脚本设计说明

### 通用特性

- **备份类型**：逻辑备份（mysqldump）/ 物理备份（Xtrabackup）
- **压缩方式**：gzip / zstd
- **命名规范**：`{类型}_{数据库名}_{日期}.sql.gz`
- **保留策略**：全量保留 30 天，增量保留 7 天，binlog 保留 7 天

### 全量备份脚本（计划）

```bash
# 示例执行方式
./full_backup.sh --type=xtrabackup --target-dir=/backup/mysql
./full_backup.sh --type=mysqldump --database=myapp
```

### 增量备份脚本（计划）

bash

```
# 示例执行方式
./inc_backup.sh --basedir=/backup/mysql/full_20260615 --target-dir=/backup/mysql/inc_20260616
```



### binlog 归档脚本（计划）

bash

```
# 示例执行方式
./binlog_backup.sh --binlog-dir=/data/mysql/binlog --backup-dir=/backup/binlog
```



## 📊 归档进度

| 脚本              | 状态     | 进度 |
| :---------------- | :------- | :--- |
| full_backup.sh    | 📅 计划中 | 0%   |
| inc_backup.sh     | 📅 计划中 | 0%   |
| binlog_backup.sh  | 📅 计划中 | 0%   |
| backup_cleanup.sh | 📅 计划中 | 0%   |

## 🔗 相关文档

- [备份操作步骤](https://../runbook/02-backup-recovery/backup-procedures.md)
- [恢复演练手册](https://../runbook/02-backup-recovery/recovery-playbook.md)