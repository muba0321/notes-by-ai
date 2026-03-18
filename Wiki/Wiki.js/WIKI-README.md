# OpenClaw Wiki 部署文档索引

**更新日期：** 2026-03-17  
**文档版本：** v2.0

---

## 📚 文档列表

### 服务端部署

| 文档 | 说明 | 适用场景 |
|------|------|----------|
| [openclaw 服务端部署 v2.md](./openclaw%20 服务端部署 v2.md) | **推荐** - 最新部署指南 | 生产环境、首次部署 |
| [WIKI-DEPLOYMENT.md](./WIKI-DEPLOYMENT.md) | 原始部署文档 | 参考 |

### 子节点部署

| 文档 | 说明 | 适用场景 |
|------|------|----------|
| [openclaw 子节点部署.md](./openclaw%20 子节点部署.md) | **推荐** - 子节点部署指南 | 内部任务节点、批量部署 |

### 数据导入

| 文档 | 说明 |
|------|------|
| [WIKI-IMPORT-GUIDE.md](./WIKI-IMPORT-GUIDE.md) | 导入指南 |
| [WIKI-IMPORT-STRUCTURE.md](./WIKI-IMPORT-STRUCTURE.md) | 导入结构 |
| [WIKI-IMPORT-COMPLETE.md](./WIKI-IMPORT-COMPLETE.md) | 导入完成报告 |

---

## 🛠️ 部署脚本

| 脚本 | 说明 |
|------|------|
| [deploy_openclaw_server.sh](./deploy_openclaw_server.sh) | **推荐** - 一键部署服务端 |
| [deploy-wiki.sh](./deploy-wiki.sh) | Wiki 部署脚本 |

---

## 🚀 快速开始

### 部署服务端

```bash
# 1. 编辑脚本配置
vi deploy_openclaw_server.sh

# 2. 执行部署
chmod +x deploy_openclaw_server.sh
./deploy_openclaw_server.sh
```

### 部署子节点

参考 [openclaw 子节点部署.md](./openclaw%20 子节点部署.md)

---

## 📋 更新日志

### v2.0 (2026-03-17)

- ✅ 新增一键部署脚本 `deploy_openclaw_server.sh`
- ✅ 更新服务端部署文档（更适合小白）
- ✅ 新增子节点部署文档
- ✅ 移除 Nginx 基础认证（默认只用 Token）
- ✅ 完善日志记录和验证步骤

---

**维护者：** OpenClaw 部署团队  
**仓库：** `/data/openclaw/wiki/`
