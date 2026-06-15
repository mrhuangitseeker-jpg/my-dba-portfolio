# 04-performance / 性能优化

> 本目录存放 MySQL 数据库的**性能优化**相关 SOP（标准操作流程）文档，涵盖慢查询分析、调优检查清单等内容。

## 📄 文档列表

| 文档名称                 | 用途           | 状态     | 最后更新   |
| ------------------------ | -------------- | -------- | ---------- |
| `slow-query-analysis.md` | 慢查询分析步骤 | ✅ 已完成 | 2026-06-15 |
| `tuning-checklist.md`    | 调优检查清单   | 🚧 维护中 | 2026-06-14 |

## 🚧 待补充文档

| 文档名称                       | 计划用途                 | 优先级 |
| ------------------------------ | ------------------------ | ------ |
| `index-design-guide.md`        | 复合索引设计法则         | 高     |
| `sql-optimization-examples.md` | SQL 优化案例汇总         | 中     |
| `parameter-tuning.md`          | MySQL 核心参数调优指南   | 中     |
| `explain-guide.md`             | EXPLAIN 执行计划解读指南 | 中     |

## 📖 文档说明

### slow-query-analysis.md

- **内容**：慢查询分析与优化完整流程
- **涵盖范围**：
  - 慢查询日志配置与开启
  - 慢查询日志格式解读
  - mysqldumpslow 使用
  - pt-query-digest 深度分析
  - 慢查询治理流程（发现→分析→优化→验证）
  - 实时慢查询监控

### tuning-checklist.md

- **内容**：数据库性能调优检查清单
- **当前状态**：🚧 维护中，内容待补充
- **计划涵盖**：
  - 索引设计检查
  - SQL 语句优化检查
  - 参数配置检查
  - 硬件资源检查

## 📊 归档进度

| 文档                   | 状态     | 进度 |
| ---------------------- | -------- | ---- |
| slow-query-analysis.md | ✅ 已完成 | 100% |
| index-design-guide.md  | 📅 计划中 | 0%   |
| tuning-checklist.md    | 🚧 维护中 | 10%  |
| parameter-tuning.md    | 📅 计划中 | 0%   |

## 🔗 相关文档

- [巡检脚本](../../scripts/maintenance/mysql_healthcheck.sh)
- [故障应急手册](../03-incident-response/p0-runbook.md)