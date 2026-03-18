# Wiki.js 页面导入结构

本文档说明如何将 `/data` 目录下的文件导入到 Wiki.js。

---

## 📁 文件结构映射

### Wiki.js 页面路径规划

```
/ (Wiki.js 根目录)
│
├── 🏠 home (首页)
│   └── 内容：Wiki.js 首页介绍
│
├── 📦 openclaw (OpenClaw 专题)
│   │
│   ├── deployment (部署指南)
│   │   ├── server-deployment (服务端部署 - 带 Nginx)
│   │   ├── subagent-deployment (子节点部署)
│   │   └── wiki-deployment (Wiki.js 部署)
│   │
│   ├── configuration (配置文档)
│   │   ├── gateway-config (Gateway 配置)
│   │   ├── model-config (模型配置 - 阿里云百炼)
│   │   ├── dingtalk-integration (钉钉集成)
│   │   └── subagent-management (子节点管理)
│   │
│   └── troubleshooting (故障排除)
│       ├── ssh-issues (SSH 连接问题)
│       ├── nodejs-install (Node.js 安装)
│       ├── openclaw-issues (OpenClaw 问题)
│       └── gateway-issues (Gateway 问题)
│
├── 📜 scripts (脚本库)
│   │
│   ├── deploy-scripts (部署脚本)
│   │   ├── deploy-nginx-sh (deploy-nginx.sh)
│   │   ├── deploy-subagent-sh (deploy-subagent.sh)
│   │   └── deploy-wiki-sh (deploy-wiki.sh)
│   │
│   ├── config-files (配置文件)
│   │   ├── ip-txt (ip.txt - 服务端列表)
│   │   ├── ip-subagent-txt (ip-subagent.txt)
│   │   └── ip-wiki-txt (ip-wiki.txt)
│   │
│   └── tools (工具脚本)
│       └── set-nginx-password-sh (set-nginx-password.sh)
│
└── 📚 docs (其他文档)
    ├── api-docs (API 文档)
    ├── user-manual (使用手册)
    └── best-practices (最佳实践)
```

---

## 📝 各页面内容来源

### 1. 首页 (/home)

**内容**：Wiki 介绍和导航

```markdown
# OpenClaw Wiki

欢迎来到 OpenClaw 知识库！

## 快速导航

### 📦 OpenClaw 部署
- [服务端部署（带 Nginx）](/openclaw/deployment/server-deployment)
- [子节点部署](/openclaw/deployment/subagent-deployment)
- [Wiki.js 部署](/openclaw/deployment/wiki-deployment)

### ⚙️ 配置文档
- [Gateway 配置](/openclaw/configuration/gateway-config)
- [模型配置](/openclaw/configuration/model-config)
- [钉钉集成](/openclaw/configuration/dingtalk-integration)

### 📜 脚本库
- [部署脚本](/scripts/deploy-scripts/)
- [配置文件](/scripts/config-files/)
- [工具脚本](/scripts/tools/)

### 🔧 故障排除
- [SSH 连接问题](/openclaw/troubleshooting/ssh-issues)
- [Node.js 安装](/openclaw/troubleshooting/nodejs-install)
- [Gateway 问题](/openclaw/troubleshooting/gateway-issues)
```

---

### 2. 服务端部署 (/openclaw/deployment/server-deployment)

**来源文件**：`/data/openclaw/openclaw-deploy/DEPLOYMENT.md`

**内容**：
- 部署方式说明（脚本 vs 手工）
- 服务端部署步骤
- Nginx 配置
- SSL 证书申请
- 故障排除

---

### 3. 子节点部署 (/openclaw/deployment/subagent-deployment)

**来源文件**：`/data/openclaw/openclaw-deploy/DEPLOYMENT.md` + `/data/openclaw/openclaw-deploy/deploy-subagent.sh`

**内容**：
- 子节点部署步骤
- 脚本部署方法
- 手工部署方法
- 模型配置
- 常见问题

---

### 4. Wiki.js 部署 (/openclaw/deployment/wiki-deployment)

**来源文件**：`/data/openclaw/wiki/WIKI-DEPLOYMENT.md`

**内容**：
- Wiki.js 简介
- 脚本部署
- 手工部署
- 初始化配置
- 中文化配置
- 页面组织指南

---

### 5. Gateway 配置 (/openclaw/configuration/gateway-config)

**来源文件**：`/data/openclaw/openclaw-deploy/DEPLOYMENT.md` 配置管理章节

**内容**：
- 配置文件位置
- 关键配置项
- 备份与恢复

---

### 6. 模型配置 (/openclaw/configuration/model-config)

**来源文件**：OpenClaw 配置经验

**内容**：
- 阿里云百炼配置
- API Key 管理
- 模型列表
- 用量查询

---

### 7. 钉钉集成 (/openclaw/configuration/dingtalk-integration)

**来源文件**：OpenClaw 钉钉配置经验

**内容**：
- 钉钉插件安装
- 钉钉应用配置
- OpenClaw 配置
- 测试验证

---

### 8. 故障排除系列

**来源文件**：`/data/openclaw/openclaw-deploy/DEPLOYMENT.md` 常见问题章节

**页面**：
- `/openclaw/troubleshooting/ssh-issues` - SSH 连接问题
- `/openclaw/troubleshooting/nodejs-install` - Node.js 安装
- `/openclaw/troubleshooting/openclaw-issues` - OpenClaw 问题
- `/openclaw/troubleshooting/gateway-issues` - Gateway 问题

---

### 9. 脚本库

**来源文件**：`/data/` 目录下的 `.sh` 脚本文件

**页面**：
- `/scripts/deploy-scripts/deploy-nginx-sh` - 服务端部署脚本
- `/scripts/deploy-scripts/deploy-subagent-sh` - 子节点部署脚本
- `/scripts/deploy-scripts/deploy-wiki-sh` - Wiki.js 部署脚本
- `/scripts/tools/set-nginx-password-sh` - Nginx 密码设置脚本

**内容格式**：
```markdown
# 脚本名称

## 用途

## 依赖

## 使用方法

## 脚本内容

```bash
# 完整脚本内容
```

## 参数说明

## 示例
```

---

### 10. 配置文件

**来源文件**：`/data/` 目录下的 `.txt` 配置文件

**页面**：
- `/scripts/config-files/ip-txt`
- `/scripts/config-files/ip-subagent-txt`
- `/scripts/config-files/ip-wiki-txt`

**内容格式**：
```markdown
# 文件说明

## 用途

## 文件格式

## 示例内容

## 注意事项
```

---

## 📋 导入顺序建议

1. **先创建首页** (`/home`)
2. **创建主要分类** (OpenClaw, Scripts, Docs)
3. **导入部署文档** (3 个部署指南)
4. **导入配置文档** (Gateway, 模型，钉钉)
5. **导入故障排除** (4 个排错文档)
6. **导入脚本库** (所有脚本文件)
7. **配置导航菜单**

---

## 🎯 页面创建模板

### 文档页面模板

```markdown
# 页面标题

## 简介

简短描述本页内容。

## 前置要求

- 要求 1
- 要求 2

## 步骤

### 步骤 1：标题

详细说明...

```bash
# 命令示例
command here
```

### 步骤 2：标题

详细说明...

## 验证

如何验证是否成功。

## 常见问题

### 问题 1

**解决方案**：...

## 相关文档

- [链接 1]()
- [链接 2]()
```

### 脚本页面模板

```markdown
# 脚本名称

## 用途

这个脚本用于...

## 依赖

- 依赖 1
- 依赖 2

## 使用方法

```bash
./script-name.sh [参数]
```

## 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| arg1 | 说明 | value |

## 示例

```bash
# 示例 1
./script-name.sh arg1 arg2
```

## 脚本内容

```bash
# 完整脚本
```

## 故障排除

### 问题 1

**原因**：...

**解决方案**：...
```

---

## ✅ 完成检查清单

- [ ] 首页创建完成
- [ ] OpenClaw 部署文档（3 篇）
- [ ] 配置文档（4 篇）
- [ ] 故障排除文档（4 篇）
- [ ] 脚本库（所有脚本）
- [ ] 配置文件（所有配置）
- [ ] 导航菜单配置
- [ ] 中文语言包下载并启用
- [ ] 所有页面链接测试

---

## 📊 预计页面数量

| 分类 | 页面数 |
|------|--------|
| 首页 | 1 |
| OpenClaw 部署 | 3 |
| 配置文档 | 4 |
| 故障排除 | 4 |
| 脚本库 | 7 |
| **总计** | **19** |
