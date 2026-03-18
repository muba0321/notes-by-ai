# OpenClaw 服务端部署

> 🚀 OpenClaw 服务端一键部署脚本和完整指南

---

## 📥 快速开始

### 一键部署

```bash
# 1. 编辑部署脚本
vi deploy_openclaw_server.sh

# 2. 修改配置（域名、邮箱等）
# 在脚本中修改【配置区域】的参数

# 3. 执行部署
chmod +x deploy_openclaw_server.sh
./deploy_openclaw_server.sh
```

### 配置参数

编辑 `deploy_openclaw_server.sh`，修改以下参数：

```bash
# 必须修改
DOMAIN="your-domain.com"           # 你的域名
ADMIN_EMAIL="your-email@example.com"  # SSL 证书邮箱

# 可选修改
DASHSCOPE_API_KEY="sk-sp-xxx"      # 阿里云 API Key
DEFAULT_MODEL="qwen3.5-plus"       # 默认 AI 模型
ENABLE_BASIC_AUTH="false"          # 是否启用基础认证
```

---

## 📖 详细文档

**[查看完整部署指南](./openclaw 服务端部署 v2.md)**

包含：
- 前置要求检查
- 手工部署步骤
- Nginx + HTTPS 配置
- 服务管理
- 常见问题

---

## 🛠️ 脚本功能

`deploy_openclaw_server.sh` 会自动执行：

1. ✅ 安装系统依赖
2. ✅ 安装 Node.js 22.x
3. ✅ 安装 OpenClaw
4. ✅ 安装 Nginx
5. ✅ 安装 Certbot (SSL)
6. ✅ 创建 OpenClaw 配置
7. ✅ 创建 Nginx 配置
8. ✅ 申请 SSL 证书
9. ✅ 安装 Gateway 服务
10. ✅ 最终验证

**预计时间：** 3-5 分钟

---

## 📋 部署后信息

部署完成后会输出：

```
========================================
  访问信息
========================================

  HTTPS 地址：https://your-domain.com
  直接访问：http://服务器 IP:18789

  Auth Token: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

========================================
```

**立即保存：**
- HTTPS 地址
- Auth Token（登录用）

---

## 🔧 常用命令

```bash
# 查看状态
openclaw gateway status

# 重启服务
systemctl --user restart openclaw-gateway.service

# 查看日志
openclaw logs --follow

# 更新 OpenClaw
npm install -g openclaw@latest
systemctl --user restart openclaw-gateway.service
```

---

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `deploy_openclaw_server.sh` | 一键部署脚本 |
| `openclaw 服务端部署 v2.md` | 完整部署指南 |

---

## 🔗 相关资源

- [子节点部署](../子节点/) - 部署子节点
- [配置模板](../配置/) - 配置文件模板
- [OpenClaw 官方文档](https://docs.openclaw.ai/)

---

**文档版本：** v2.0  
**最后更新：** 2026-03-18
