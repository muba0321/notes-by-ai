# OpenClaw 升级与部署完整指南

_主节点/子节点升级方案 + 新机器独立部署_

**创建日期：** 2026-03-24  
**版本：** 1.0  
**升级版本：** 2026.3.13 → 2026.3.23-1

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

# 记录当前版本
openclaw --version
openclaw gateway status
```

#### 2. 通知用户

如有其他用户在使用，提前通知升级窗口时间（预计中断 5-10 分钟）。

#### 3. 检查系统状态

```bash
# 检查磁盘空间
df -h

# 检查内存
free -h

# 检查 Gateway 状态
openclaw gateway status
```

---

### 二、升级步骤（主节点/子节点通用）

#### 步骤 1：执行升级

```bash
npm install -g openclaw@latest
```

**输出示例：**
```
npm warn deprecated node-domexception@1.0.0
added 27 packages, removed 107 packages, and changed 432 packages in 2m
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
- ✅ Runtime: running
- ✅ RPC probe: ok
- ✅ Listening: *:18789

#### 步骤 5：验证 Skills

```bash
ls /usr/lib/node_modules/openclaw/skills/ | grep -E 'skill-vetter|self-improving'
```

如 Skills 丢失，从其他节点复制：
```bash
ssh root@other-node "tar czf - -C /usr/lib/node_modules/openclaw/skills skill-vetter self-improving-agent" | tar xzf - -C /usr/lib/node_modules/openclaw/skills/
```

#### 步骤 6：验证记忆文件

```bash
ls ~/.openclaw/workspace/memory/
```

**预期输出：**
```
MEMORY.md
TOOLS.md
lessons.md
projects.md
```

---

### 三、主从节点升级影响

#### 主节点升级影响

| 影响项 | 说明 | 缓解措施 |
|--------|------|---------|
| **Git 推送中断** | 升级期间无法推送 | 选择低峰期升级 |
| **文档归档暂停** | 子节点文档暂存 | 升级后手动同步 |
| **服务中断** | 约 5-10 分钟 | 提前通知用户 |

#### 子节点升级影响

| 影响项 | 说明 | 缓解措施 |
|--------|------|---------|
| **产品设计暂停** | 无法生成新文档 | 提前保存草稿 |
| **Gateway 中断** | WebSocket 断开 | 自动重连 |
| **Skills 暂停** | 自改进功能暂停 | 升级后恢复 |

#### 同时升级 vs 分步升级

| 方式 | 优点 | 缺点 | 建议 |
|------|------|------|------|
| **同时升级** | 快速完成 | 服务完全中断 | 测试环境 |
| **分步升级** | 服务部分可用 | 耗时较长 | ✅ 生产环境 |

**推荐：** 先升级子节点，验证成功后再升级主节点。

---

### 四、升级过程记录

#### 子节点 1 升级记录

```bash
# 升级前
OpenClaw 2026.3.13 (61d171a)

# 备份
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak

# 升级
npm install -g openclaw@latest

# 升级后
OpenClaw 2026.3.23-1

# 重启 Gateway
systemctl --user restart openclaw-gateway.service

# 验证
openclaw gateway status
# Runtime: running (pid 243763, state active, sub running)
# RPC probe: ok
```

**升级时间：** 2026-03-24 01:42 UTC  
**升级耗时：** 约 3 分钟  
**问题：** Skills 丢失（已恢复）

---

#### 主节点升级记录

```bash
# 升级前
OpenClaw 2026.3.13 (61d171a)

# 备份
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak

# 升级
npm install -g openclaw@latest

# 升级后
OpenClaw 2026.3.23-1

# 重启 Gateway
openclaw gateway restart

# 验证
openclaw gateway status
# Runtime: running
# RPC probe: ok
```

**升级时间：** 2026-03-24 01:51 UTC  
**升级耗时：** 约 3 分钟  
**问题：** 无

---

### 五、升级风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| **配置丢失** | 低 | 中 | ✅ 升级前备份 openclaw.json |
| **Skills 丢失** | 中 | 中 | ✅ 从其他节点复制 |
| **Gateway 启动失败** | 低 | 高 | ✅ 查看日志，重新安装 |
| **数据不兼容** | 低 | 高 | ✅ 查看 CHANGELOG |
| **服务中断** | 中 | 中 | ✅ 选择低峰期升级 |
| **npm 网络问题** | 中 | 低 | ✅ 使用镜像源 |

---

### 六、升级问题处理

#### 问题 1：Gateway 无法启动

**症状：**
```
Gateway port 18789 is not listening
Runtime: stopped
```

**排查步骤：**
```bash
# 1. 查看日志
cat /tmp/openclaw/openclaw-*.log | tail -50

# 2. 检查配置
cat ~/.openclaw/openclaw.json

# 3. 检查端口占用
ss -tlnp | grep 18789

# 4. 重新安装
npm install -g openclaw@latest --force
openclaw gateway install
systemctl --user restart openclaw-gateway.service
```

**常见原因：**
- 配置文件错误
- 端口被占用
- 权限问题

---

#### 问题 2：Skills 丢失

**症状：**
```bash
ls /usr/lib/node_modules/openclaw/skills/
# 空目录或没有自定义 Skills
```

**解决方案：**
```bash
# 从其他节点复制
ssh root@38.246.245.39 "tar czf - -C /usr/lib/node_modules/openclaw/skills skill-vetter self-improving-agent" | tar xzf - -C /usr/lib/node_modules/openclaw/skills/

# 验证
ls /usr/lib/node_modules/openclaw/skills/ | grep -E 'skill-vetter|self-improving'
```

---

#### 问题 3：RPC 探测失败

**症状：**
```
RPC probe: failed
gateway closed (1006 abnormal closure)
```

**解决方案：**
```bash
# 1. 等待 30 秒（Gateway 启动需要时间）
sleep 30

# 2. 检查日志
cat /tmp/openclaw/openclaw-*.log | tail -30

# 3. 重启 Gateway
systemctl --user restart openclaw-gateway.service

# 4. 验证
openclaw gateway status
```

---

#### 问题 4：版本回滚

**如需回滚到旧版本：**

```bash
# 卸载当前版本
npm uninstall -g openclaw

# 安装指定版本
npm install -g openclaw@2026.3.13

# 恢复配置
cp ~/.openclaw/openclaw.json.bak ~/.openclaw/openclaw.json

# 重启 Gateway
openclaw gateway restart
```

---

#### 问题 5：npm 安装失败

**症状：**
```
npm ERR! network timeout
npm ERR! code ETIMEDOUT
```

**解决方案：**
```bash
# 使用国内镜像
npm config set registry https://registry.npmmirror.com

# 重新安装
npm install -g openclaw@latest

# 恢复默认（可选）
npm config set registry https://registry.npmjs.org
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
node --version
npm --version
```

#### 步骤 2：安装 OpenClaw

```bash
npm install -g openclaw@latest
openclaw --version
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
openclaw gateway status
```

#### 步骤 5：安装 Nginx

```bash
apt install -y nginx
systemctl status nginx
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
# 验证 OpenClaw
openclaw --version
openclaw gateway status

# 验证 Nginx
curl -I http://localhost:18789/
curl -I http://oclwz.mubai.top/
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

- [ ] 版本号正确（2026.3.23-1）
- [ ] Gateway 运行正常
- [ ] RPC 探测成功
- [ ] Skills 存在（skill-vetter, self-improving-agent）
- [ ] 记忆文件完整（projects.md, lessons.md 等）
- [ ] 可以正常对话

### 新部署验证

- [ ] Node.js 版本正确（v22.x）
- [ ] OpenClaw 安装成功
- [ ] Gateway 启动成功
- [ ] Nginx 配置正确
- [ ] 域名可以访问
- [ ] Token 认证正常

---

## 📊 升级时间线

| 时间 | 节点 | 操作 | 状态 |
|------|------|------|------|
| 01:41 UTC | 子节点 1 | 开始升级 | ✅ |
| 01:42 UTC | 子节点 1 | 升级完成 | ✅ |
| 01:42 UTC | 子节点 1 | Gateway 重启 | ✅ |
| 01:45 UTC | 子节点 1 | Skills 恢复 | ✅ |
| 01:51 UTC | 主节点 | 开始升级 | ✅ |
| 01:52 UTC | 主节点 | 升级完成 | ✅ |
| 01:52 UTC | 主节点 | Gateway 重启 | ✅ |
| 02:00 UTC | 新机器 | 开始部署 | ✅ |
| 02:06 UTC | 新机器 | Gateway 启动 | ✅ |
| 02:07 UTC | 新机器 | Nginx 配置 | ✅ |

**总耗时：** 约 26 分钟

---

## 🔗 相关文档

- [OpenClaw 官方文档](https://docs.openclaw.ai/)
- [升级日志](https://github.com/openclaw/openclaw/blob/main/CHANGELOG.md)
- [故障排除](https://docs.openclaw.ai/troubleshooting)
- [记忆文件](../memory/projects.md)

---

**维护者：** OpenClaw 团队  
**最后更新：** 2026-03-24  
**下次审查：** 2026-04-24
