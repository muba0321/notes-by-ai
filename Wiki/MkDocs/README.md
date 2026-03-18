# MkDocs Wiki 部署

> 📚 MkDocs + Material 主题 Wiki 系统部署和维护文档

---

## 📥 快速开始

### 一键部署

```bash
# 1. 编辑部署脚本（可选）
vi deploy-mkdocs-wiki.sh

# 2. 执行部署
chmod +x deploy-mkdocs-wiki.sh
./deploy-mkdocs-wiki.sh
```

### 快速更新文档

```bash
# 更新单个或多个文档
./update-wiki.sh server.md subagent.md

# 或批量更新
./update-wiki.sh *.md
```

---

## 📖 详细文档

| 文档 | 说明 |
|------|------|
| [完整部署指南](./MKDOCS-DEPLOYMENT.md) | 10 章节完整教程 |
| [维护文档](./MKDOCS-MAINTENANCE.md) | 日常维护和故障排除 |
| [说明文档](./README.md) | MkDocs 说明 |

---

## 🛠️ 脚本说明

### deploy-mkdocs-wiki.sh

**功能：**
- ✅ 自动安装 MkDocs 和 Material 主题
- ✅ 创建项目目录结构
- ✅ 配置 Nginx
- ✅ 构建并发布站点

**配置参数：**
```bash
WIKI_DOMAIN="wiki.mubai.top"     # 域名
SITE_NAME="OpenClaw Wiki"        # 站点名称
DEPLOY_DIR="/opt/mkdocs"         # 部署目录
```

### update-wiki.sh

**功能：**
- ✅ 快速上传文档到服务器
- ✅ 自动构建并重新加载

**使用方法：**
```bash
./update-wiki.sh 文件 1.md 文件 2.md
```

---

## 📋 部署步骤摘要

1. **环境准备** - Ubuntu 22.04+, Python 3.10+, Nginx
2. **安装 MkDocs** - `pip3 install mkdocs mkdocs-material`
3. **创建项目** - `mkdocs new .`
4. **配置 Nginx** - 反向代理配置
5. **构建发布** - `mkdocs build --clean`

**预计时间：** 5-10 分钟

---

## 📁 文件说明

| 文件 | 说明 | 大小 |
|------|------|------|
| `deploy-mkdocs-wiki.sh` | 一键部署脚本 | 15KB |
| `update-wiki.sh` | 快速更新脚本 | 1.3KB |
| `MKDOCS-DEPLOYMENT.md` | 完整部署指南 | 12KB |
| `MKDOCS-MAINTENANCE.md` | 维护文档 | 7KB |
| `README.md` | 说明文档 | 4KB |

---

## 🔗 相关资源

| 资源 | 链接 |
|------|------|
| MkDocs 官方 | https://www.mkdocs.org/ |
| Material 主题 | https://squidfunk.github.io/mkdocs-material/ |
| OpenClaw Wiki | http://wiki.mubai.top |

---

**文档版本：** v1.0  
**最后更新：** 2026-03-18
