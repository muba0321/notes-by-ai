# OpenClaw 部署文档（完整版）

本文档包含 OpenClaw 服务端和子节点的**脚本部署**和**手工部署**两种方式的完整指南。

---

## 📋 目录

1. [部署方式说明](#部署方式说明)
2. [服务端部署（带 Nginx 反向代理）](#2-服务端部署带-nginx-反向代理)
3. [子节点部署（纯任务执行节点）](#3-子节点部署纯任务执行节点)
4. [常见问题与解决方案](#4-常见问题与解决方案)
5. [配置管理](#5-配置管理)
6. [维护与监控](#6-维护与监控)

---

## 部署方式说明

### 脚本部署 vs 手工部署

| 方式 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **脚本部署** | 快速、自动化、减少人为错误 | 需要理解脚本逻辑 | 批量部署、重复部署 |
| **手工部署** | 灵活、可定制、便于调试 | 步骤繁琐、易出错 | 首次学习、故障排查、特殊配置 |

**建议**：
- 首次部署建议**先手工操作一遍**，理解每个步骤
- 批量部署时使用**脚本**提高效率
- 故障排查时参考**手工步骤**定位问题

---

## 2. 服务端部署（带 Nginx 反向代理）

### 2.1 适用场景

- 对外提供服务的 OpenClaw 主节点
- 需要域名和 HTTPS 访问
- 需要基础认证保护

### 2.2 前置要求

- 已配置 SSH 密钥免密登录
- 域名已解析到服务器 IP
- 服务器 80/443 端口开放

---

### 2.3 方式 A：脚本部署

#### 步骤 1：准备服务器列表

```bash
# 编辑服务器列表
vi /data/ip.txt

# 格式：IP:端口：用户名（支持 SSH 密钥）
# 示例：
192.168.1.100
10.0.0.50:2222
```

#### 步骤 2：执行部署

```bash
# 使用默认域名
cd /data
./deploy-nginx.sh

# 或指定域名
./deploy-nginx.sh your-domain.com
```

#### 步骤 3：设置访问密码

```bash
./set-nginx-password.sh admin yourpassword123
```

---

### 2.4 方式 B：手工部署

#### 步骤 1：SSH 登录服务器

```bash
ssh root@your-server-ip
```

#### 步骤 2：安装 Nginx

```bash
# 更新包索引
apt update

# 安装 Nginx
apt install -y nginx

# 验证安装
nginx -v
systemctl status nginx
```

#### 步骤 3：安装 Certbot（SSL 证书工具）

```bash
# 安装 Certbot 和 Nginx 插件
apt install -y certbot python3-certbot-nginx

# 验证安装
certbot --version
```

#### 步骤 4：创建 Nginx 配置文件

```bash
# 创建配置文件
cat > /etc/nginx/sites-available/openclaw.mubai.top << 'EOF'
# HTTP 强制跳转 HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name openclaw.mubai.top;
    return 301 https://$server_name$request_uri;
}

# HTTPS 配置
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name openclaw.mubai.top;

    # SSL 证书路径
    ssl_certificate /etc/letsencrypt/live/openclaw.mubai.top/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/openclaw.mubai.top/privkey.pem;

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

    # 基础认证
    location / {
        auth_basic "OpenClaw Admin";
        auth_basic_user_file /etc/nginx/.htpasswd;

        # 反向代理到 OpenClaw Gateway
        proxy_pass http://127.0.0.1:18789;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_buffering off;
    }

    # 日志
    access_log /var/log/nginx/openclaw_access.log;
    error_log /var/log/nginx/openclaw_error.log;
}
EOF
```

**配置说明**：
- `proxy_pass http://127.0.0.1:18789` - 反向代理到本地 OpenClaw Gateway
- `proxy_set_header Upgrade $http_upgrade` - 支持 WebSocket（OpenClaw 需要）
- `auth_basic` - HTTP 基础认证
- `ssl_certificate` - Let's Encrypt SSL 证书路径

#### 步骤 5：启用站点配置

```bash
# 创建软链接启用站点
ln -sf /etc/nginx/sites-available/openclaw.mubai.top /etc/nginx/sites-enabled/

# 删除默认站点
rm -f /etc/nginx/sites-enabled/default

# 测试 Nginx 配置
nginx -t

# 重载 Nginx
systemctl reload nginx
```

#### 步骤 6：申请 SSL 证书

```bash
# 自动申请并配置 SSL 证书
certbot --nginx -d openclaw.mubai.top --non-interactive --agree-tos --email admin@your-domain.com

# 或手动申请
certbot certonly --nginx -d openclaw.mubai.top
```

#### 步骤 7：设置基础认证密码

```bash
# 创建密码文件（首次）
htpasswd -cb /etc/nginx/.htpasswd admin yourpassword123

# 添加更多用户
htpasswd -b /etc/nginx/.htpasswd user2 password2
```

#### 步骤 8：验证部署

```bash
# 检查 Nginx 状态
systemctl status nginx

# 检查端口监听
netstat -tlnp | grep -E '80|443'

# 测试访问
curl -I https://openclaw.mubai.top
```

---

## 3. 子节点部署（纯任务执行节点）

### 3.1 适用场景

- 内部任务执行节点
- 无需域名和 Nginx
- 由主节点统一调度

### 3.2 前置要求

- 已安装 `sshpass` 工具（用于密码登录）
- 知道目标服务器的账号密码
- 服务器 18789 端口开放

---

### 3.3 方式 A：脚本部署

#### 步骤 1：安装 sshpass（本地机器）

```bash
apt install -y sshpass
```

#### 步骤 2：编辑子节点列表

```bash
vi /data/ip-subagent.txt

# 格式：IP:SSH 端口：用户名：密码：主机名
# 示例：
38.246.245.39:22:root:Huanxin0321:mubai-subagent1
192.168.1.100:22:admin:secret123:subagent-2
```

#### 步骤 3：（可选）配置模型

```bash
# 设置环境变量启用模型配置
export CONFIGURE_MODELS=true
export DASHSCOPE_API_KEY="sk-sp-your-api-key"
```

#### 步骤 4：执行部署

```bash
cd /data
./deploy-subagent.sh
```

---

### 3.4 方式 B：手工部署

#### 步骤 1：SSH 登录子节点

```bash
ssh root@38.246.245.39
# 或使用密码
sshpass -p "Huanxin0321" ssh root@38.246.245.39
```

#### 步骤 2：设置主机名（可选但推荐）

```bash
# 设置主机名
hostnamectl set-hostname mubai-subagent1

# 写入默认配置
echo 'HOSTNAME=mubai-subagent1' >> /etc/default/locale

# 验证
hostname
# 应该输出：mubai-subagent1
```

#### 步骤 3：检查并安装 Node.js

```bash
# 检查是否已安装
node --version

# 如果未安装，安装 Node.js 22.x
# 添加 NodeSource 仓库
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -

# 安装 Node.js
apt install -y nodejs

# 验证安装
node --version  # 应该输出 v22.x.x
npm --version
```

**国内网络环境（如 NodeSource 访问慢）**：
```bash
# 使用清华大学镜像
curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/nodesource/deb/setup_22.x | bash -
apt install -y nodejs
```

#### 步骤 4：安装 OpenClaw

```bash
# 全局安装 OpenClaw（最新版）
npm install -g openclaw@latest --no-fund --no-audit --loglevel=error

# 验证安装
openclaw --version
```

**国内网络环境（如 npm 访问慢）**：
```bash
# 使用淘宝镜像
NPM_CONFIG_REGISTRY=https://registry.npmmirror.com npm install -g openclaw@latest

# 或永久配置
npm config set registry https://registry.npmmirror.com
```

#### 步骤 5：创建配置目录和文件

```bash
# 创建配置目录
mkdir -p ~/.openclaw

# 生成随机 Token（用于认证）
AUTH_TOKEN=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
echo "生成的 Token: $AUTH_TOKEN"

# 创建配置文件
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
```

**配置说明**：
- `"port": 18789` - Gateway 监听端口
- `"bind": "lan"` - 绑定局域网（0.0.0.0），允许远程访问
- `"allowedOrigins": ["*"]` - 允许任何来源访问 Control UI
- `"dangerouslyDisableDeviceAuth": true` - 禁用设备身份验证（非 HTTPS 环境必需）
- `"token"` - 访问令牌，用于登录 Control UI

#### 步骤 6：（可选）配置阿里云百炼模型

```bash
# 编辑配置文件，添加模型配置
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
      "token": "your-auth-token"
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "bailian": {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "sk-sp-your-api-key",
        "api": "openai-completions",
        "models": [
          {
            "id": "qwen3.5-plus",
            "name": "qwen3.5-plus",
            "reasoning": false,
            "input": ["text", "image"],
            "contextWindow": 1000000,
            "maxTokens": 65536
          },
          {
            "id": "qwen3-max-2026-01-23",
            "name": "qwen3-max-2026-01-23",
            "reasoning": false,
            "input": ["text"],
            "contextWindow": 262144,
            "maxTokens": 65536
          },
          {
            "id": "qwen3-coder-next",
            "name": "qwen3-coder-next",
            "reasoning": false,
            "input": ["text"],
            "contextWindow": 262144,
            "maxTokens": 65536
          },
          {
            "id": "qwen3-coder-plus",
            "name": "qwen3-coder-plus",
            "reasoning": false,
            "input": ["text"],
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
```

**模型配置说明**：
- `baseUrl` - 阿里云百炼 API 端点
- `apiKey` - 你的阿里云 API Key（sk-sp-开头）
- `models` - 可用的模型列表
- `primary` - 默认使用的模型

#### 步骤 7：安装并启动 Gateway 服务

```bash
# 安装 systemd 服务
openclaw gateway install

# 重新加载 systemd 配置
systemctl --user daemon-reload

# 启用服务（开机自启）
systemctl --user enable openclaw-gateway.service

# 启动服务
systemctl --user start openclaw-gateway.service

# 等待 2 秒
sleep 2

# 验证服务状态
systemctl --user status openclaw-gateway.service
```

**服务文件位置**：
```
~/.config/systemd/user/openclaw-gateway.service
```

#### 步骤 8：验证部署

```bash
# 检查 Gateway 状态
openclaw gateway status

# 检查进程
ps aux | grep openclaw

# 检查端口监听
netstat -tlnp | grep 18789
# 或
ss -tlnp | grep 18789

# 应该显示：*:18789 或 0.0.0.0:18789

# 测试本地访问
curl http://127.0.0.1:18789

# 查看日志
openclaw logs --follow
```

#### 步骤 9：配置防火墙（如需要）

```bash
# Ubuntu UFW
ufw allow 18789/tcp
ufw status

# CentOS firewall
firewall-cmd --add-port=18789/tcp --permanent
firewall-cmd --reload
firewall-cmd --list-all

# 云服务器安全组
# 登录阿里云/腾讯云控制台，在安全组中开放 18789 端口
```

---

### 3.5 访问子节点 Control UI

#### 获取访问信息

```bash
# 查看配置文件获取 Token
cat ~/.openclaw/openclaw.json | grep -A2 '"token"'

# 或使用 openclaw 命令
openclaw gateway status
```

#### 访问步骤

1. 打开浏览器访问：`http://<子节点 IP>:18789`
2. 输入配置文件中的 `token` 值
3. 点击登录

---

## 4. 常见问题与解决方案

### 4.1 SSH 连接问题

#### 问题 1：SSH 连接失败

```
ssh: connect to host <IP> port 22: Connection refused
```

**原因**：
- 网络不通
- SSH 服务未启动
- 防火墙阻止
- 账号密码错误

**解决方案**：
```bash
# 1. 测试网络连通性
ping -c 3 <IP 地址>

# 2. 测试 SSH 连接
ssh -v root@<IP 地址>

# 3. 检查 SSH 服务（在目标机器）
systemctl status sshd
systemctl restart sshd

# 4. 检查防火墙
ufw status
# 或
firewall-cmd --list-all

# 5. 检查 SSH 配置
cat /etc/ssh/sshd_config | grep -E 'Port|PermitRootLogin'
```

---

#### 问题 2：sshpass 未找到

```
sshpass: command not found
```

**解决方案**：
```bash
# Ubuntu/Debian
apt install -y sshpass

# CentOS/RHEL
yum install -y sshpass

# macOS
brew install hudochenkov/sshpass/sshpass
```

---

### 4.2 Node.js 安装问题

#### 问题 1：Node.js 安装失败

```
curl: (6) Could not resolve host: deb.nodesource.com
```

**原因**：DNS 解析失败或网络问题

**解决方案**：
```bash
# 方案 A：使用国内镜像
curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/nodesource/deb/setup_22.x | bash -
apt install -y nodejs

# 方案 B：检查 DNS
cat /etc/resolv.conf
# 添加 nameserver 8.8.8.8

# 方案 C：手动下载二进制
cd /tmp
wget https://nodejs.org/dist/v22.22.1/node-v22.22.1-linux-x64.tar.xz
tar -xf node-v22.22.1-linux-x64.tar.xz
cp -r node-v22.22.1-linux-x64/* /usr/local/
node --version
```

---

#### 问题 2：Node.js 版本不兼容

```
OpenClaw requires Node.js >= 18
```

**解决方案**：
```bash
# 检查当前版本
node --version

# 安装 Node.js 22.x
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

# 验证
node --version  # 应该 >= 18
```

---

### 4.3 OpenClaw 安装问题

#### 问题 1：npm 安装超时

```
npm ERR! network timeout at: https://registry.npmjs.org/
```

**解决方案**：
```bash
# 使用国内镜像
NPM_CONFIG_REGISTRY=https://registry.npmmirror.com npm install -g openclaw

# 或永久配置
npm config set registry https://registry.npmmirror.com

# 清理缓存重试
npm cache clean --force
npm install -g openclaw
```

---

#### 问题 2：OpenClaw 初始化失败

```
error: unknown command 'init'
```

**原因**：OpenClaw 版本差异或命令变更

**解决方案**：
```bash
# 方案 A：手动创建配置目录和文件
mkdir -p ~/.openclaw
cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan"
  }
}
EOF

# 方案 B：使用 gateway install
openclaw gateway install

# 方案 C：更新 OpenClaw
npm install -g openclaw@latest
```

---

### 4.4 Gateway 启动问题

#### 问题 1：Gateway 无法启动

```
Runtime: stopped (state inactive)
```

**原因**：
- 配置文件错误
- 端口被占用
- 权限问题

**解决方案**：
```bash
# 1. 查看日志定位问题
openclaw logs --follow
# 或
journalctl --user -u openclaw-gateway.service -n 50

# 2. 检查配置文件语法
cat ~/.openclaw/openclaw.json | python3 -m json.tool

# 3. 检查端口占用
netstat -tlnp | grep 18789
# 如果有占用，修改配置中的端口或杀掉占用进程

# 4. 重启服务
systemctl --user restart openclaw-gateway.service

# 5. 重新安装服务
openclaw gateway uninstall
openclaw gateway install
openclaw gateway start
```

---

#### 问题 2：Control UI 无法访问 - 来源限制

```
origin not allowed (open the Control UI from the gateway host or allow it in gateway.controlUi.allowedOrigins)
```

**原因**：Cross-Origin 限制，默认只允许 localhost 访问

**解决方案**：
```bash
# 1. 编辑配置文件
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
      "token": "your-token"
    }
  }
}
EOF

# 2. 重启 Gateway
openclaw gateway restart

# 3. 验证
openclaw gateway status
```

---

#### 问题 3：Control UI 无法访问 - 设备身份验证

```
control ui requires device identity (use HTTPS or localhost secure context)
```

**原因**：非 HTTPS/localhost 环境需要设备认证

**解决方案**：
```bash
# 在配置中添加
"controlUi": {
  "dangerouslyDisableDeviceAuth": true
}

# 重启 Gateway
openclaw gateway restart
```

---

### 4.5 模型配置问题

#### 问题 1：模型不可用

```
Model not found: bailian/qwen3.5-plus
```

**解决方案**：
```bash
# 1. 检查模型配置
cat ~/.openclaw/openclaw.json | grep -A30 '"models"'

# 2. 验证 API Key 是否有效
curl -X GET "https://dashscope.aliyuncs.com/api/v1/account/balance" \
  -H "Authorization: Bearer sk-sp-your-key"

# 3. 检查配置格式
cat ~/.openclaw/openclaw.json | python3 -m json.tool

# 4. 重启 Gateway
openclaw gateway restart
```

---

#### 问题 2：API Key 无效

```
Invalid API Key
```

**解决方案**：
```bash
# 1. 验证 API Key 格式
# 应该是 sk-sp- 或 sk- 开头

# 2. 登录阿里云百炼控制台确认 Key 有效
# https://dashscope.console.aliyun.com/

# 3. 更新配置
vi ~/.openclaw/openclaw.json
# 修改 apiKey 字段

# 4. 重启
openclaw gateway restart
```

---

### 4.6 网络连接问题

#### 问题 1：子节点无法从主节点访问

```
curl: (7) Failed to connect to <IP> port 18789: Connection refused
```

**解决方案**：
```bash
# 1. 检查防火墙（子节点）
# Ubuntu
ufw allow 18789/tcp
ufw status

# CentOS
firewall-cmd --add-port=18789/tcp --permanent
firewall-cmd --reload

# 2. 检查云服务器安全组
# 登录阿里云/腾讯云控制台
# 在安全组规则中添加入站规则：TCP 18789

# 3. 验证监听地址
netstat -tlnp | grep 18789
# 应该显示 0.0.0.0:18789 或 *:18789
# 如果显示 127.0.0.1:18789，修改配置 "bind": "lan"

# 4. 测试本地访问
curl http://127.0.0.1:18789

# 5. 从主节点测试远程访问
curl http://<子节点 IP>:18789
```

---

## 5. 配置管理

### 5.1 配置文件位置

| 文件 | 路径 | 说明 |
|------|------|------|
| 主配置 | `~/.openclaw/openclaw.json` | OpenClaw 主配置 |
| 服务配置 | `~/.config/systemd/user/openclaw-gateway.service` | systemd 服务文件 |
| 日志 | `/tmp/openclaw/openclaw-*.log` | 运行日志 |
| systemd 日志 | `journalctl --user -u openclaw-gateway` | 系统日志 |

### 5.2 关键配置项详解

```json
{
  "gateway": {
    "port": 18789,           // Gateway 监听端口
    "mode": "local",         // 运行模式：local/remote
    "bind": "lan",           // 绑定地址：lan(0.0.0.0)/localhost(127.0.0.1)
    
    "controlUi": {
      "enabled": true,                    // 启用 Control UI
      "allowedOrigins": ["*"],            // 允许的访问来源，* 表示全部
      "allowInsecureAuth": true,          // 允许非 HTTPS 认证
      "dangerouslyDisableDeviceAuth": true // 禁用设备身份验证
    },
    
    "auth": {
      "mode": "token",                    // 认证方式：token/password
      "token": "your-auth-token"          // 访问令牌
    }
  },
  
  "models": {
    "mode": "merge",                      // 模型配置模式
    "providers": {
      "bailian": {                        // 阿里云百炼
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "sk-sp-xxx",
        "api": "openai-completions"
      }
    }
  },
  
  "agents": {
    "defaults": {
      "model": {
        "primary": "bailian/qwen3.5-plus" // 默认模型
      }
    }
  }
}
```

### 5.3 备份与恢复

```bash
# 备份配置
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak.$(date +%Y%m%d_%H%M%S)

# 列出备份
ls -la ~/.openclaw/openclaw.json.bak.*

# 恢复配置
cp ~/.openclaw/openclaw.json.bak.20260316 ~/.openclaw/openclaw.json
openclaw gateway restart

# 查看配置差异
diff ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak.20260316
```

---

## 6. 维护与监控

### 6.1 日常检查命令

```bash
# 检查服务状态
openclaw gateway status

# 检查 systemd 服务
systemctl --user status openclaw-gateway.service

# 检查进程
ps aux | grep openclaw

# 检查端口监听
netstat -tlnp | grep 18789

# 查看实时日志
openclaw logs --follow

# 查看最近 50 行日志
openclaw logs --tail 50

# 查看 systemd 日志
journalctl --user -u openclaw-gateway.service -n 50

# 检查配置
cat ~/.openclaw/openclaw.json | python3 -m json.tool
```

### 6.2 更新升级

```bash
# 查看当前版本
openclaw --version

# 更新 OpenClaw
npm install -g openclaw@latest

# 验证更新
openclaw --version

# 重启服务
openclaw gateway restart

# 检查服务状态
openclaw gateway status
```

### 6.3 故障排查流程

```
┌─────────────────────────────────────┐
│  1. 检查服务状态                    │
│     openclaw gateway status         │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  2. 查看错误日志                    │
│     openclaw logs --follow          │
│     journalctl --user -u ...        │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  3. 检查配置文件                    │
│     cat ~/.openclaw/openclaw.json   │
│     python3 -m json.tool 验证格式   │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  4. 检查端口监听                    │
│     netstat -tlnp | grep 18789      │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  5. 重启服务                        │
│     openclaw gateway restart        │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  6. 重新安装服务                    │
│     openclaw gateway uninstall      │
│     openclaw gateway install        │
│     openclaw gateway start          │
└─────────────────────────────────────┘
```

### 6.4 清理与卸载

```bash
# 停止服务
openclaw gateway stop

# 卸载服务
openclaw gateway uninstall

# 删除配置（谨慎操作）
rm -rf ~/.openclaw

# 删除 OpenClaw
npm uninstall -g openclaw

# 验证清理
openclaw --version  # 应该显示 command not found
```

---

## 📞 支持资源

| 资源 | 链接 |
|------|------|
| 官方文档 | https://docs.openclaw.ai/ |
| GitHub | https://github.com/openclaw/openclaw |
| 故障排除 | https://docs.openclaw.ai/troubleshooting |
| 社区 | https://discord.com/invite/clawd |
| NPM 包 | https://www.npmjs.com/package/openclaw |

---

## 📝 更新日志

| 日期 | 版本 | 更新内容 |
|------|------|----------|
| 2026-03-16 | 2.0 | 添加完整手工部署步骤，细化故障排除 |
| 2026-03-16 | 1.1 | 添加子节点部署完整指南 |
| 2026-03-13 | 1.0 | 初始版本，服务端部署指南 |

---

## 📚 附录

### A. 常用命令速查

```bash
# 服务管理
openclaw gateway start      # 启动
openclaw gateway stop       # 停止
openclaw gateway restart    # 重启
openclaw gateway status     # 状态
openclaw gateway install    # 安装服务
openclaw gateway uninstall  # 卸载服务

# 日志
openclaw logs --follow      # 实时日志
openclaw logs --tail 100    # 最近 100 行

# 配置
openclaw doctor             # 诊断配置
openclaw doctor --repair    # 自动修复

# 系统
systemctl --user status openclaw-gateway.service
systemctl --user restart openclaw-gateway.service
journalctl --user -u openclaw-gateway.service -f
```

### B. 端口说明

| 端口 | 用途 | 说明 |
|------|------|------|
| 18789 | Gateway | OpenClaw Gateway 默认端口 |
| 80 | HTTP | Nginx HTTP 重定向 |
| 443 | HTTPS | Nginx HTTPS 服务 |

### C. 文件权限

```bash
# 确保配置文件权限正确
chmod 600 ~/.openclaw/openclaw.json
chown $USER:$USER ~/.openclaw/openclaw.json

# 确保服务文件权限正确
chmod 644 ~/.config/systemd/user/openclaw-gateway.service
```
