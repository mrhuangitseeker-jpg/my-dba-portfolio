# 00-installation / 安装部署

> 本目录存放 MySQL 数据库的**安装与部署**相关 SOP（标准操作流程）文档。

## 📄 文档列表

| 文档名称     | 用途                     | 状态     | 最后更新   |
| ------------ | ------------------------ | -------- | ---------- |
| `install.md` | MySQL 二进制安装部署指南 | ✅ 已完成 | 2026-06-14 |

## 🚧 待补充文档

| 文档名称                 | 计划用途                            | 优先级 |
| ------------------------ | ----------------------------------- | ------ |
| `source-install.md`      | MySQL 源码编译安装指南              | 低     |
| `docker-install.md`      | MySQL Docker 容器化部署指南         | 中     |
| `post-install-config.md` | 安装后配置（初始化、密码、systemd） | 中     |
| `multi-instance.md`      | 多实例部署指南                      | 低     |

## 📖 文档说明

### install.md

- **内容**：MySQL 二进制安装完整步骤
- **适用版本**：MySQL 8.0 / 8.4
- **适用系统**：CentOS / Rocky Linux / RHEL
- **涵盖内容**：
  - 环境准备与依赖安装
  - MySQL 二进制包下载与解压
  - my.cnf 配置
  - 初始化数据库
  - systemd 服务配置
  - 启动与密码设置

## 📊 归档进度

| 文档                   | 状态     | 进度 |
| ---------------------- | -------- | ---- |
| install.md             | ✅ 已完成 | 100% |
| docker-install.md      | 📅 计划中 | 0%   |
| post-install-config.md | 📅 计划中 | 0%   |
| source-install.md      | 📅 计划中 | 0%   |

## 🔗 相关文档

- [主从复制搭建指南](../02-backup-recovery/recovery-playbook.md)
- [每日巡检清单](../01-daily-checks/morning-checklist.md)
