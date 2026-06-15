# 05-change-management / 变更管理

> 本目录存放 MySQL 数据库的**变更管理**相关 SOP（标准操作流程）文档，涵盖 DDL 变更评审标准和发布操作模板。

## 📄 文档列表

| 文档名称                  | 用途             | 状态     | 最后更新   |
| ------------------------- | ---------------- | -------- | ---------- |
| `ddl-review-checklist.md` | DDL 变更评审标准 | 🚧 维护中 | 2026-06-14 |
| `deployment-template.md`  | 发布操作模板     | 🚧 维护中 | 2026-06-14 |

## 🚧 待补充文档

| 文档名称                | 计划用途           | 优先级 |
| ----------------------- | ------------------ | ------ |
| `rollback-template.md`  | 回滚方案模板       | 中     |
| `sql-review-rules.md`   | SQL 评审规则       | 中     |
| `version-management.md` | 数据库版本管理规范 | 低     |

## 📖 文档说明

### ddl-review-checklist.md

- **内容**：DDL 变更评审标准
- **当前状态**：🚧 维护中，内容待补充
- **计划涵盖**：
  - 变更分类（表结构变更、索引变更、权限变更等）
  - 评审要点（影响评估、回滚方案、执行窗口）
  - 审批流程
  - 变更记录模板

### deployment-template.md

- **内容**：发布操作模板
- **当前状态**：🚧 维护中，内容待补充
- **计划涵盖**：
  - 发布前检查清单
  - 发布执行步骤
  - 验证测试步骤
  - 回滚方案
  - 发布后观察项

## 📊 归档进度

| 文档                    | 状态     | 进度 |
| ----------------------- | -------- | ---- |
| ddl-review-checklist.md | 🚧 维护中 | 5%   |
| deployment-template.md  | 🚧 维护中 | 5%   |
| rollback-template.md    | 📅 计划中 | 0%   |
| sql-review-rules.md     | 📅 计划中 | 0%   |

## 🔗 相关文档

- [安装部署指南](../00-installation/install.md)
- [备份恢复手册](../02-backup-recovery/recovery-playbook.md)
- [故障应急手册](../03-incident-response/p0-runbook.md)
