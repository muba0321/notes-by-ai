# OpenClaw 子节点部署指南 v2.0

**更新日期：** 2026-03-17  
**适用版本：** OpenClaw 2026.3.13+  
**文档类型：** 内部节点部署

---

## 📋 目录

1. [快速部署](#1-快速部署)
2. [批量部署脚本](#2-批量部署脚本)
3. [连接主节点](#3-连接主节点)
4. [服务管理](#4-服务管理)
5. [常见问题](#5-常见问题)

---

## 1. 快速部署

### 1.1 适用场景

- 内部任务执行节点
- 无需域名和 HTTPS
- 由主节点统一调度

### 1.2 前置要求

- Ubuntu 22.04+ 服务器
- 主节点 Gateway 可访问
- 18789 端口开放（内网）

### 1.3 部署步骤

```bash
# 1. 安装 Node.js 22.x
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

# 2. 安装 OpenClaw
npm install -g openclaw@latest --no-fund --no-audit

# 3. 生成随机 Token
AUTH_TOKEN=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
echo "子节点 Token: $AUTH_TOKEN"

# 4. 创建配置
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

# 5. 安装并启动服务
openclaw gateway install
systemctl --user daemon-reload
systemctl --user enable openclaw-gateway.service
systemctl --user start openclaw-gateway.service

# 6. 验证
sleep 5
openclaw gateway status
ss -tlnp | grep 18789
```

---

## 2. 批量部署脚本

### 2.1 准备服务器列表

创建文件 `/data/ip-subagent.txt`：

```
# 格式：IP:SSH 端口：用户名：密码：主机名
38.246.245.39:22:root:password123:mubai-subagent1
192.168.1.100:22:admin:secret456:subagent-2
```

### 2.2 部署脚本

创建脚本 `deploy-subagent-auto.sh`：

```bash
#!/bin/bash
set -e

IP_FILE="/data/ip-subagent.txt"
GATEWAY_PORT="18789"

log_info() { echo "[INFO] $1"; }
log_success() { echo "[✓] $1"; }
log_error() { echo "[✗] $1"; }

deploy_to_remote() {
    local ip=$1
    local port=$2
    local user=$3
    local password=$4
    local hostname=$5
    
    log_info "部署到 $ip ($hostname)"
    
    # SSH 测试
    if ! sshpass -p "$password" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "echo OK" > /dev/null 2>&1; then
        log_error "SSH 失败：$ip"
        return 1
    fi
    
    # 安装 Node.js
    sshpass -p "$password" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "
        curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
        apt install -y nodejs
    "
    
    # 安装 OpenClaw
    sshpass -p "$password" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "
        npm install -g openclaw@latest --no-fund --no-audit
    "
    
    # 生成 Token
    local auth_token
    auth_token=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "cat /proc/sys/kernel/random/uuid | tr -d '-'")
    
    # 创建配置
    sshpass -p "$password" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "
        mkdir -p ~/.openclaw
        cat > ~/.openclaw/openclaw.json << EOF
{
  \"gateway\": {
    \"port\": ${GATEWAY_PORT},
    \"mode\": \"local\",
    \"bind\": \"lan\",
    \"controlUi\": {
      \"enabled\": true,
      \"allowedOrigins\": [\"*\"],
      \"allowInsecureAuth\": true,
      \"dangerouslyDisableDeviceAuth\": true
    },
    \"auth\": {
      \"mode\": \"token\",
      \"token\": \"${auth_token}\"
    }
  }
}
EOF
    "
    
    # 安装服务
    sshpass -p "$password" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "
        openclaw gateway install
        systemctl --user daemon-reload
        systemctl --user enable openclaw-gateway.service
        systemctl --user start openclaw-gateway.service
    "
    
    log_success "$hostname 部署完成 (Token: $auth_token)"
    return 0
}

# 主程序
while IFS=':' read -r ip port user password hostname; do
    [[ "$ip" =~ ^# ]] && continue
    [[ -z "$ip" ]] && continue
    
    port="${port:-22}"
    user="${user:-root}"
    hostname="${hostname:-subagent-$(echo $ip | tr '.' '-')}"
    
    deploy_to_remote "$ip" "$port" "$user" "$password" "$hostname"
    
done < "$IP_FILE"

echo "批量部署完成"
```

### 2.3 执行部署

```bash
# 安装 sshpass
apt install -y sshpass

# 执行脚本
chmod +x deploy-subagent-auto.sh
./deploy-subagent-auto.sh
```

---

## 3. 连接主节点

### 3.1 作为节点配对

子节点部署完成后，需要在主节点进行配对：

```bash
# 在主节点执行
openclaw devices list

# 找到子节点的配对请求
# 批准配对
openclaw devices approve <requestId>

# 验证节点状态
openclaw nodes status
```

### 3.2 配置节点执行

```bash
# 设置默认执行节点
openclaw config set tools.exec.host node
openclaw config set tools.exec.node "<节点 IP 或名称>"
openclaw config set tools.exec.security allowlist

# 添加命令白名单
openclaw approvals allowlist add --node <节点> "/usr/bin/docker"
openclaw approvals allowlist add --node <节点> "/usr/bin/git"
```

---

## 4. 服务管理

### 4.1 常用命令

```bash
# 查看状态
openclaw gateway status
systemctl --user status openclaw-gateway.service

# 重启
systemctl --user restart openclaw-gateway.service

# 查看日志
journalctl --user -u openclaw-gateway.service -f

# 更新
npm install -g openclaw@latest --no-fund --no-audit
systemctl --user restart openclaw-gateway.service
```

### 4.2 防火墙配置

```bash
# Ubuntu UFW
ufw allow 18789/tcp
ufw status

# 云服务器安全组
# 登录控制台，添加入站规则：TCP 18789
```

---

## 5. 常见问题

### 5.1 Gateway 启动失败

```bash
# 清理锁文件
pkill -9 -f openclaw
rm -rf ~/.openclaw/agents/main/sessions/*.lock

# 重启
systemctl --user restart openclaw-gateway.service
```

### 5.2 无法从主节点访问

```bash
# 检查监听地址
ss -tlnp | grep 18789
# 应该显示 0.0.0.0:18789 或 *:18789

# 检查防火墙
ufw status
# 确保 18789 开放

# 测试本地访问
curl http://127.0.0.1:18789

# 从主节点测试
curl http://<子节点 IP>:18789
```

### 5.3 配对失败

```bash
# 检查配置
cat ~/.openclaw/openclaw.json

# 重启 Gateway
systemctl --user restart openclaw-gateway.service

# 在主节点重新查看
openclaw devices list
```

---

## 📝 部署检查清单

- [ ] Node.js 已安装
- [ ] OpenClaw 已安装
- [ ] Gateway 服务运行中
- [ ] 端口 18789 监听
- [ ] 防火墙已配置
- [ ] Token 已记录
- [ ] 主节点可访问

---

**文档版本：** 2.0  
**最后更新：** 2026-03-17
