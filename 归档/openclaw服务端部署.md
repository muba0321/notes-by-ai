# OpenClaw 服务端部署指南 v2.0

**更新日期：** 2026-03-17  
**适用版本：** OpenClaw 2026.3.13+  
**文档类型：** 生产环境部署

---

## 📋 目录

1. [快速部署（推荐）](#1-快速部署推荐)
2. [手工部署（详细步骤）](#2-手工部署详细步骤)
3. [Nginx + HTTPS 配置](#3-nginx--https-配置)
4. [服务管理](#4-服务管理)
5. [常见问题](#5-常见问题)

---

## 1. 快速部署（推荐）

### 1.1 前置要求

- Ubuntu 22.04+ 服务器
- 域名已解析到服务器 IP
- 80/443 端口开放
- root 权限

### 1.2 一键部署脚本

```bash
# 设置变量
DOMAIN="your-domain.com"
EMAIL="admin@your-domain.com"

# 1. 安装 Node.js 22.x
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

# 2. 安装 OpenClaw
npm install -g openclaw@latest --no-fund --no-audit

# 3. 安装 Nginx 和 Certbot
apt install -y nginx certbot python3-certbot-nginx

# 4. 生成随机 Token
AUTH_TOKEN=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
echo "Your Auth Token: $AUTH_TOKEN"

# 5. 创建 OpenClaw 配置
mkdir -p ~/.openclaw
cat > ~/.openclaw/openclaw.json << EOF
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
      "token": "$AUTH_TOKEN"
    }
  }
}
EOF

# 6. 安装并启动 Gateway 服务
openclaw gateway install
systemctl --user daemon-reload
systemctl --user enable openclaw-gateway.service
systemctl --user start openclaw-gateway.service

# 7. 等待服务启动
sleep 5
openclaw gateway status
```

### 1.3 验证部署

```bash
# 检查 Gateway 状态
openclaw gateway status

# 检查端口监听
ss -tlnp | grep 18789

# 测试本地访问
curl http://127.0.0.1:18789 | head -5
```

---

## 2. 手工部署（详细步骤）

### 2.1 安装 Node.js

```bash
# 添加 NodeSource 仓库
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -

# 安装 Node.js
apt install -y nodejs

# 验证
node --version  # 应输出 v22.x.x
npm --version
```

### 2.2 安装 OpenClaw

```bash
# 全局安装
npm install -g openclaw@latest --no-fund --no-audit

# 验证
openclaw --version
```

### 2.3 创建配置

```bash
# 创建配置目录
mkdir -p ~/.openclaw

# 生成随机 Token
AUTH_TOKEN=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
echo "保存此 Token: $AUTH_TOKEN"

# 创建配置文件
cat > ~/.openclaw/openclaw.json << EOF
{
  "meta": {
    "lastTouchedVersion": "2026.3.13",
    "lastTouchedAt": "$(date -Iseconds)"
  },
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
      "token": "$AUTH_TOKEN"
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "bailian": {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "sk-sp-YOUR-API-KEY",
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
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "bailian/qwen3.5-plus"
      }
    }
  }
}
EOF

# 验证 JSON 格式
cat ~/.openclaw/openclaw.json | python3 -m json.tool > /dev/null && echo "Config valid"
```

### 2.4 安装 Gateway 服务

```bash
# 安装 systemd 服务
openclaw gateway install

# 重新加载 systemd
systemctl --user daemon-reload

# 启用服务（开机自启）
systemctl --user enable openclaw-gateway.service

# 启动服务
systemctl --user start openclaw-gateway.service

# 等待启动
sleep 5

# 验证状态
systemctl --user status openclaw-gateway.service
openclaw gateway status
```

---

## 3. Nginx + HTTPS 配置

### 3.1 安装 Nginx 和 Certbot

```bash
apt update
apt install -y nginx certbot python3-certbot-nginx
```

### 3.2 创建 Nginx 配置

```bash
DOMAIN="your-domain.com"

cat > /etc/nginx/sites-available/$DOMAIN << EOF
# HTTP - 强制跳转 HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS 配置
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN;

    # SSL 证书（Certbot 自动填充）
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # 反向代理到 OpenClaw Gateway
    location / {
        proxy_pass http://127.0.0.1:18789;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_buffering off;
    }

    # 日志
    access_log /var/log/nginx/${DOMAIN}_access.log;
    error_log /var/log/nginx/${DOMAIN}_error.log;
}
EOF
```

### 3.3 启用站点

```bash
# 创建软链接
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# 删除默认站点
rm -f /etc/nginx/sites-enabled/default

# 测试配置
nginx -t

# 重新加载
systemctl reload nginx
```

### 3.4 申请 SSL 证书

```bash
DOMAIN="your-domain.com"
EMAIL="admin@your-domain.com"

certbot certonly --nginx -d $DOMAIN \
  --non-interactive \
  --agree-tos \
  --email $EMAIL

# 重新加载 Nginx 以应用证书
systemctl reload nginx
```

### 3.5 验证 HTTPS

```bash
# 测试 HTTP 跳转
curl -I http://$DOMAIN

# 测试 HTTPS
curl -k -I https://$DOMAIN

# 应该返回 HTTP/2 200
```

---

## 4. 服务管理

### 4.1 常用命令

```bash
# 查看状态
openclaw gateway status
systemctl --user status openclaw-gateway.service

# 启动
systemctl --user start openclaw-gateway.service

# 停止
systemctl --user stop openclaw-gateway.service

# 重启
systemctl --user restart openclaw-gateway.service

# 查看日志
openclaw logs --follow
journalctl --user -u openclaw-gateway.service -f

# 查看最近 50 行日志
journalctl --user -u openclaw-gateway.service -n 50 --no-pager
```

### 4.2 开机自启

```bash
# 启用开机自启
systemctl --user enable openclaw-gateway.service

# 验证
systemctl --user is-enabled openclaw-gateway.service
```

### 4.3 更新 OpenClaw

```bash
# 更新到最新版
npm install -g openclaw@latest --no-fund --no-audit

# 重启服务
systemctl --user restart openclaw-gateway.service

# 验证版本
openclaw --version
```

---

## 5. 常见问题

### 5.1 Gateway 无法启动

**症状：**
```
Gateway failed to start: gateway already running
```

**解决：**
```bash
# 1. 停止所有 OpenClaw 进程
pkill -9 -f openclaw

# 2. 清理锁文件
rm -rf ~/.openclaw/agents/main/sessions/*.lock

# 3. 重启服务
systemctl --user restart openclaw-gateway.service

# 4. 验证
openclaw gateway status
```

---

### 5.2 端口被占用

**症状：**
```
Port 18789 is already in use
```

**解决：**
```bash
# 查看占用端口的进程
ss -tlnp | grep 18789

# 杀掉占用进程
kill -9 <PID>

# 或使用 fuser
fuser -k 18789/tcp

# 重启服务
systemctl --user restart openclaw-gateway.service
```

---

### 5.3 Nginx 502 错误

**症状：**
```
HTTP/2 502
```

**原因：** Gateway 未启动或崩溃

**解决：**
```bash
# 1. 检查 Gateway 状态
openclaw gateway status

# 2. 检查端口监听
ss -tlnp | grep 18789

# 3. 查看 Gateway 日志
tail -50 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log

# 4. 重启 Gateway
systemctl --user restart openclaw-gateway.service

# 5. 等待 5 秒后验证
sleep 5
curl -k -I https://your-domain.com
```

---

### 5.4 SSL 证书续期

Certbot 会自动续期，但需要验证：

```bash
# 查看证书过期时间
certbot certificates

# 手动续期
certbot renew --dry-run

# 强制续期
certbot renew --force-renewal

# 续期后重新加载 Nginx
systemctl reload nginx
```

---

### 5.5 认证失败

**症状：**
```
unauthorized: too many failed authentication attempts
```

**解决：**
1. 等待 5-10 分钟让认证限制解除
2. 清除浏览器缓存或使用无痕模式
3. 确认 Token 正确（查看配置文件）

```bash
# 查看当前 Token
cat ~/.openclaw/openclaw.json | grep -A1 '"token"'

# 如需重置 Token
NEW_TOKEN=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
echo "New Token: $NEW_TOKEN"

# 编辑配置文件替换 Token
vi ~/.openclaw/openclaw.json

# 重启 Gateway
systemctl --user restart openclaw-gateway.service
```

---

### 5.6 WebSocket 连接失败

**症状：**
```
gateway closed (1006 abnormal closure)
```

**原因：** Nginx 未正确配置 WebSocket 升级

**解决：** 确保 Nginx 配置包含：
```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

---

## 📝 部署检查清单

部署完成后逐项检查：

- [ ] Node.js 已安装 (`node --version`)
- [ ] OpenClaw 已安装 (`openclaw --version`)
- [ ] 配置文件有效 (`python3 -m json.tool`)
- [ ] Gateway 服务运行中 (`openclaw gateway status`)
- [ ] 端口 18789 监听 (`ss -tlnp | grep 18789`)
- [ ] Nginx 配置正确 (`nginx -t`)
- [ ] SSL 证书有效 (`certbot certificates`)
- [ ] HTTPS 访问正常 (`curl -k -I https://domain`)
- [ ] Token 已安全保存

---

## 🔐 安全建议

1. **Token 安全**
   - 使用随机 Token（不要用可预测的值）
   - 定期更换 Token
   - 不要将 Token 提交到版本控制

2. **防火墙**
   ```bash
   # 只开放必要端口
   ufw allow 80/tcp
   ufw allow 443/tcp
   ufw enable
   ```

3. **监控**
   - 定期检查服务状态
   - 监控日志文件
   - 设置证书续期提醒

4. **备份**
   ```bash
   # 备份配置
   cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak.$(date +%Y%m%d)
   
   # 备份 Nginx 配置
   cp /etc/nginx/sites-available/your-domain.com /etc/nginx/sites-available/your-domain.com.bak.$(date +%Y%m%d)
   ```

---

## 📞 支持资源

| 资源 | 链接 |
|------|------|
| 官方文档 | https://docs.openclaw.ai/ |
| GitHub | https://github.com/openclaw/openclaw |
| 故障排除 | https://docs.openclaw.ai/troubleshooting |
| 社区 | https://discord.com/invite/clawd |

---

**文档版本：** 2.0  
**最后更新：** 2026-03-17  
**维护者：** OpenClaw 部署团队
