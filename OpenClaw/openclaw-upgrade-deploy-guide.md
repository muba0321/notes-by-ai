# OpenClaw 升级与部署文档

_主节点/子节点升级方案 + 新机器独立部署_

**创建日期：** 2026-03-24  
**版本：** 1.0

---

## 📊 版本对比

| 节点 | 升级前 | 升级后 | 状态 |
|------|--------|--------|------|
| **堡垒机** | - | 2026.3.22 | ✅ 最新 |
| **子节点 1** | 2026.3.13 | 2026.3.23-1 | ✅ 已升级 |
| **主节点** | 2026.3.13 | 2026.3.23-1 | ✅ 已升级 |
| **新机器** | - | 2026.3.23-1 | ✅ 新部署 |

---

## 📋 升级方案

### 一、升级前准备

#### 1. 备份配置

```bash
# 备份 openclaw.json
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak

# 备份 workspace（可选）
tar czf /tmp/workspace-backup.tar.gz ~/.openclaw/workspace/
```

#### 2. 记录当前版本

```bash
openclaw --version
openclaw gateway status
```

#### 3. 通知用户（如有）

如有其他用户在使用，提前通知升级窗口时间。

---

### 二、升级步骤

#### 步骤 1：执行升级

```bash
npm install -g openclaw@latest
```

**预计时间：** 2-3 分钟

#### 步骤 2：验证版本

```bash
openclaw --version
```

**预期输出：** `OpenClaw 2026.3.23-1`

#### 步骤 3：重启 Gateway

```bash
# 方法 1：使用 openclaw 命令
openclaw gateway restart

# 方法 2：使用 systemctl
systemctl --user restart openclaw-gateway.service
```

#### 步骤 4：验证 Gateway

```bash
openclaw gateway status
```

**检查项：**
- Runtime: running
- RPC probe: ok
- Listening: *:18789

#### 步骤 5：验证 Skills

```bash
ls /usr/lib/node_modules/openclaw/skills/
```

如 Skills 丢失，从备份恢复或重新安装。

---

### 三、升级风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| **配置丢失** | 低 | 中 | 升级前备份 openclaw.json |
| **Skills 丢失** | 中 | 中 | 从其他节点复制或重新安装 |
| **Gateway 启动失败** | 低 | 高 | 查看日志，回滚版本 |
| **数据不兼容** | 低 | 高 | 查看 CHANGELOG，测试环境先升级 |
| **服务中断** | 中 | 中 | 选择低峰期升级，预计中断 5 分钟 |

---

### 四、升级问题处理

#### 问题 1：Gateway 无法启动

**症状：**
```
Gateway port 18789 is not listening
```

**解决：**
```bash
# 查看日志
cat /tmp/openclaw/openclaw-*.log | tail -50

# 检查配置
cat ~/.openclaw/openclaw.json

# 重新安装
npm install -g openclaw@latest --force
openclaw gateway install
```

#### 问题 2：Skills 丢失

**症状：**
```
ls /usr/lib/node_modules/openclaw/skills/ 为空
```

**解决：**
```bash
# 从其他节点复制
ssh root@other-node "tar czf - -C /usr/lib/node_modules/openclaw/skills skill-vetter self-improving-agent" | tar xzf - -C /usr/lib/node_modules/openclaw/skills/
```

#### 问题 3：版本回滚

```bash
# 安装特定版本
npm install -g openclaw@2026.3.13

# 重启 Gateway
openclaw gateway restart
```

---

## 🚀 新机器独立部署方案

### 一、环境要求

| 要求 | 说明 |
|------|------|
| **操作系统** | Ubuntu 22.04+ |
| **CPU** | 2 核+ |
| **内存** | 2GB+ |
| **磁盘** | 10GB+ |
| **网络** | 公网 IP（可选） |

### 二、部署步骤

#### 步骤 1：安装 Node.js

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
```

#### 步骤 2：安装 OpenClaw

```bash
npm install -g openclaw@latest
```

#### 步骤 3：配置 openclaw.json

```bash
mkdir -p ~/.openclaw
cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan",
    "controlUi": {
      "enabled": true,
      "allowedOrigins": ["*"],
      "allowInsecureAuth": true,
      "dangerouslyDisableDeviceAuth": true
    },
    "auth": {
      "mode": "token",
      "token": "your-secure-token"
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "bailian": {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "sk-sp-7e6f845b069f486d9b18aa8366579f1e",
        "api": "openai-completions",
        "models": [
          {
            "id": "qwen3.5-plus",
            "name": "qwen3.5-plus",
            "reasoning": false,
            "input": ["text", "image"],
            "contextWindow": 1000000,
            "maxTokens": 65536
          }
        ]
      }
    }
  }
}
EOF
```

#### 步骤 4：安装并启动 Gateway

```bash
openclaw gateway install
systemctl --user start openclaw-gateway.service
```

#### 步骤 5：安装 Nginx

```bash
apt install -y nginx
```

#### 步骤 6：配置 Nginx 反向代理

```bash
cat > /etc/nginx/conf.d/openclaw-proxy.conf << 'EOF'
server {
    listen 80;
    server_name oclwz.mubai.top;
    
    location / {
        proxy_pass http://localhost:18789;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
}
EOF

nginx -t && systemctl restart nginx
```

#### 步骤 7：验证部署

```bash
openclaw --version
openclaw gateway status
curl -I http://localhost:18789/
```

---

### 三、独立部署注意事项

| 事项 | 说明 |
|------|------|
| **不共享记忆文件** | 新机器使用独立的 workspace |
| **不共享 Skills** | 按需安装 Skills |
| **使用相同 API Key** | 共享阿里云百炼 API Key |
| **独立 Token** | 每个节点使用不同的 gateway token |
| **Nginx 配置** | 配置域名代理以便外部访问 |

---

## 📝 部署验证清单

### 升级验证

- [ ] 版本号正确
- [ ] Gateway 运行正常
- [ ] RPC 探测成功
- [ ] Skills 存在
- [ ] 记忆文件完整
- [ ] 可以正常对话

### 新部署验证

- [ ] Node.js 版本正确
- [ ] OpenClaw 安装成功
- [ ] Gateway 启动成功
- [ ] Nginx 配置正确
- [ ] 域名可以访问
- [ ] Token 认证正常

---

## 🔗 相关文档

- [OpenClaw 官方文档](https://docs.openclaw.ai/)
- [升级日志](https://github.com/openclaw/openclaw/blob/main/CHANGELOG.md)
- [故障排除](https://docs.openclaw.ai/troubleshooting)

---

**维护者：** OpenClaw 团队  
**最后更新：** 2026-03-24
