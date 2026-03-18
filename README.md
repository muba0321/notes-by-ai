# OpenClaw 部署文档库

> 📚 完整的 OpenClaw 部署、配置和维护文档

**版本：** 2.0  
**更新日期：** 2026-03-18  
**维护者：** OpenClaw 团队

---

## 📁 目录结构

```
openclaw-dist/
├── OpenClaw/                    # OpenClaw 相关文档
│   ├── 服务端/                  # 服务端部署
│   │   ├── deploy_openclaw_server.sh    # ⭐ 一键部署脚本
│   │   └── openclaw 服务端部署 v2.md     # ⭐ 部署指南
│   ├── 子节点/                  # 子节点部署
│   │   ├── deploy-subagent.sh           # ⭐ 批量部署脚本
│   │   └── openclaw 子节点部署.md        # ⭐ 部署指南
│   └── 配置/                    # 配置模板
│       └── ip-subagent.txt              # 子节点列表模板
│
├── Wiki/                        # Wiki 系统文档
│   ├── MkDocs/                  # MkDocs Wiki
│   │   ├── deploy-mkdocs-wiki.sh        # ⭐ 一键部署脚本
│   │   ├── update-wiki.sh               # 快速更新脚本
│   │   ├── MKDOCS-DEPLOYMENT.md         # ⭐ 完整部署指南
│   │   ├── MKDOCS-MAINTENANCE.md        # ⭐ 维护文档
│   │   └── README.md                    # 说明文档
│   └── Wiki.js/                 # Wiki.js（旧版）
│       ├── deploy-wiki.sh
│       └── WIKI-*.md
│
├── Nginx/                       # Nginx 相关
│   └── deploy-nginx.sh          # Nginx 部署脚本（旧版）
│
├── 通用/                        # 通用文档
│   └── （空，预留）
│
└── 归档/                        # 旧版文档归档
    ├── DEPLOYMENT.md            # 原始部署文档
    ├── openclaw 服务端部署.md    # 旧版服务端部署
    └── openclaw 子节点部署.md    # 旧版子节点部署
```

---

## 🚀 快速开始

### 部署 OpenClaw 服务端

```bash
# 1. 进入服务端目录
cd OpenClaw/服务端

# 2. 编辑部署脚本（配置域名等）
vi deploy_openclaw_server.sh

# 3. 执行部署
chmod +x deploy_openclaw_server.sh
./deploy_openclaw_server.sh
```

### 部署 OpenClaw 子节点

```bash
# 1. 进入子节点目录
cd OpenClaw/子节点

# 2. 编辑服务器列表
vi ip-subagent.txt

# 3. 执行部署
chmod +x deploy-subagent.sh
./deploy-subagent.sh
```

### 部署 MkDocs Wiki

```bash
# 1. 进入 MkDocs 目录
cd Wiki/MkDocs

# 2. 执行部署
chmod +x deploy-mkdocs-wiki.sh
./deploy-mkdocs-wiki.sh
```

---

## 📖 文档说明

### OpenClaw 部署

| 文档 | 说明 | 适用场景 |
|------|------|----------|
| [服务端部署](./OpenClaw/服务端/openclaw 服务端部署 v2.md) | OpenClaw 主节点部署指南 | 生产环境部署 |
| [子节点部署](./OpenClaw/子节点/openclaw 子节点部署.md) | OpenClaw 子节点部署指南 | 批量部署任务节点 |

### Wiki 部署

| 文档 | 说明 | 适用场景 |
|------|------|----------|
| [MkDocs 部署指南](./Wiki/MkDocs/MKDOCS-DEPLOYMENT.md) | MkDocs + Material 主题完整教程 | 文档系统部署 |
| [MkDocs 维护文档](./Wiki/MkDocs/MKDOCS-MAINTENANCE.md) | 日常维护和故障排除 | 文档系统维护 |

---

## 🛠️ 脚本说明

### 核心脚本（推荐）

| 脚本 | 用途 | 状态 |
|------|------|------|
| `deploy_openclaw_server.sh` | OpenClaw 服务端一键部署 | ⭐ 推荐 |
| `deploy-subagent.sh` | OpenClaw 子节点批量部署 | ⭐ 推荐 |
| `deploy-mkdocs-wiki.sh` | MkDocs Wiki 一键部署 | ⭐ 推荐 |
| `update-wiki.sh` | MkDocs Wiki 快速更新 | ⭐ 推荐 |

### 旧版脚本（归档）

| 脚本 | 用途 | 状态 |
|------|------|------|
| `deploy-nginx.sh` | Nginx 部署 | ⚠️ 已废弃 |
| `deploy-wiki.sh` | Wiki.js 部署 | ⚠️ 已废弃 |

---

## 📋 使用流程

### 新服务器部署

1. **部署 OpenClaw 服务端** → `OpenClaw/服务端/`
2. **配置 Gateway 和模型** → 参考部署文档
3. **部署子节点（可选）** → `OpenClaw/子节点/`
4. **部署 Wiki 文档系统** → `Wiki/MkDocs/`

### 文档更新

1. 编辑文档内容
2. 使用 `update-wiki.sh` 上传
3. 或手动推送到 Wiki 服务器

---

## 📊 文档版本

| 文档 | 版本 | 日期 | 状态 |
|------|------|------|------|
| openclaw 服务端部署 v2.md | v2.0 | 2026-03-18 | ✅ 最新 |
| openclaw 子节点部署.md | v2.0 | 2026-03-18 | ✅ 最新 |
| MKDOCS-DEPLOYMENT.md | v1.0 | 2026-03-17 | ✅ 最新 |
| MKDOCS-MAINTENANCE.md | v1.0 | 2026-03-17 | ✅ 最新 |

---

## 🔗 相关资源

| 资源 | 链接 |
|------|------|
| OpenClaw 官方文档 | https://docs.openclaw.ai/ |
| OpenClaw GitHub | https://github.com/openclaw/openclaw |
| MkDocs 官方文档 | https://www.mkdocs.org/ |
| Material 主题 | https://squidfunk.github.io/mkdocs-material/ |

---

## 📝 更新日志

### v2.0 (2026-03-18)

- ✅ 按工具类型重新分类文档
- ✅ 整理核心部署脚本
- ✅ 归档旧版文档
- ✅ 添加统一 README 说明

### v1.0 (2026-03-17)

- ✅ 初始版本
- ✅ 包含 OpenClaw 和 MkDocs 部署文档

---

**许可证：** MIT  
**联系方式：** OpenClaw Team
