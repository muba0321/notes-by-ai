# OpenClaw 子节点部署

> 📦 OpenClaw 子节点批量部署脚本和指南

---

## 📥 快速开始

### 一键部署

```bash
# 1. 编辑服务器列表
vi ip-subagent.txt

# 2. 添加子节点信息（格式：IP:端口：用户名：密码：主机名）
38.246.245.39:22:root:password123:mubai-subagent1
192.168.1.100:22:admin:secret456:subagent-2

# 3. 执行部署
chmod +x deploy-subagent.sh
./deploy-subagent.sh
```

---

## 📖 详细文档

**[查看完整部署指南](./openclaw 子节点部署.md)**

包含：
- 快速部署步骤
- 批量部署脚本
- 连接主节点配置
- 服务管理
- 常见问题

---

## 🛠️ 脚本功能

`deploy-subagent.sh` 会自动：

1. ✅ SSH 连接到子节点
2. ✅ 安装 Node.js
3. ✅ 安装 OpenClaw
4. ✅ 生成随机 Token
5. ✅ 创建配置
6. ✅ 安装 Gateway 服务
7. ✅ 验证部署

---

## 📋 部署后

每个子节点会输出：

```
========================================
  访问信息
========================================

  主机名：mubai-subagent1
  IP 地址：38.246.245.39
  访问地址：http://38.246.245.39:18789
  Auth Token: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

========================================
```

---

## 🔗 连接主节点

子节点部署完成后，在主节点执行：

```bash
# 查看待配对设备
openclaw devices list

# 批准配对
openclaw devices approve <requestId>

# 验证节点状态
openclaw nodes status
```

---

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `deploy-subagent.sh` | 批量部署脚本 |
| `openclaw 子节点部署.md` | 完整部署指南 |
| `ip-subagent.txt` | 服务器列表模板 |

---

## 🔗 相关资源

- [服务端部署](../服务端/) - 部署主节点
- [配置模板](../配置/) - 配置文件模板

---

**文档版本：** v2.0  
**最后更新：** 2026-03-18
