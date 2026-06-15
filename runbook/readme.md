# Runbook / 运维操作手册

> 本目录存放 MySQL 数据库的**标准化运维操作手册（SOP）**，
>
> 涵盖安装部署、日常巡检、备份恢复、故障应急、性能优化、变更管理等全流程。

## 📁 目录结构

```bash
runbook/
├── 00-installation/ # 安装部署
├── 01-daily-checks/ # 日常巡检
├── 02-backup-recovery/ # 备份恢复
├── 03-incident-response/ # 故障应急
├── 04-performance/ # 性能优化
└── 05-change-management/ # 变更管理
```

## 🛠️ 模块说明

### 00-installation（安装部署）

- **用途**：MySQL 安装、配置、初始化相关 SOP
- **状态**：🚧 维护中
- **计划内容**：
  - MySQL 二进制安装步骤
  - 安装后配置（初始化、密码、systemd）
  - 多实例部署指南

### 01-daily-checks（日常巡检）

- **用途**：每日/每周巡检清单与操作步骤
- **状态**：🚧 维护中
- **计划内容**：
  - 每日早晨巡检清单
  - 监控阈值参考表
  - 巡检脚本使用说明

### 02-backup-recovery（备份恢复）

- **用途**：备份与恢复操作 SOP
- **状态**：🚧 维护中
- **计划内容**：
  - mysqldump 备份步骤
  - Xtrabackup 全量/增量备份恢复
  - 时间点恢复（PITR）流程

### 03-incident-response（故障应急）

- **用途**：故障应急处理手册
- **状态**：🚧 维护中
- **计划内容**：
  - P0/P1 故障应急手册
  - 故障升级矩阵
  - 常见故障排查流程

### 04-performance（性能优化）

- **用途**：SQL 优化、索引设计、参数调优指南
- **状态**：🚧 维护中
- **计划内容**：
  - 慢查询分析步骤
  - 调优检查清单
  - 复合索引设计法则

### 05-change-management（变更管理）

- **用途**：数据库变更管理规范
- **状态**：🚧 维护中
- **计划内容**：
  - DDL 变更评审标准
  - 发布操作模板
  - 回滚方案模板

## 📊 归档进度

| 模块                 | 状态     | 进度 | 预计完成 |
| -------------------- | -------- | ---- | -------- |
| 00-installation      | 🚧 维护中 | 10%  | 待定     |
| 01-daily-checks      | 🚧 维护中 | 20%  | 待定     |
| 02-backup-recovery   | 🚧 维护中 | 15%  | 待定     |
| 03-incident-response | 🚧 维护中 | 10%  | 待定     |
| 04-performance       | 🚧 维护中 | 15%  | 待定     |
| 05-change-management | 🚧 维护中 | 5%   | 待定     |

## 🔗 相关文档

- [MySQL 二进制安装指南](./00-installation/mysql-binary-install.md)
- [每日巡检清单](./01-daily-checks/morning-checklist.md)
- [监控阈值参考表](./04-performance/monitoring-thresholds.md)
- [P0 故障应急手册](./03-incident-response/p0-runbook.md)
- [故障升级矩阵](./03-incident-response/escalation-matrix.md)

