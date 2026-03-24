# Nginx 反向代理配置

_Jenkins/Prometheus/Grafana 域名访问配置_

**创建日期：** 2026-03-23  
**位置：** 子节点 1 (38.246.245.39)

---

## 🌐 域名绑定

| 服务 | 域名 | 目标端口 | Nginx 端口 |
|------|------|---------|-----------|
| **Jenkins** | jenkins.mubai.top | 8080 | 80 |
| **Prometheus** | promethus.mubai.top | 9090 | 80 |
| **Grafana** | grafana.mubai.top | 3000 | 80 |

**DNS 配置：** 所有域名 A 记录指向 `38.246.245.39`

---

## 📁 配置文件位置

| 文件 | 路径 |
|------|------|
| **Jenkins** | `/etc/nginx/conf.d/jenkins-proxy.conf` |
| **Prometheus** | `/etc/nginx/conf.d/prometheus-proxy.conf` |
| **Grafana** | `/etc/nginx/conf.d/grafana-proxy.conf` |

---

## ⚙️ 配置内容

### Jenkins 代理

```nginx
server {
    listen 80;
    server_name jenkins.mubai.top;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 90;
        proxy_send_timeout 90;
        proxy_read_timeout 90;
    }
}
```

---

### Prometheus 代理

```nginx
server {
    listen 80;
    server_name promethus.mubai.top;
    
    location / {
        proxy_pass http://localhost:9090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

### Grafana 代理

```nginx
server {
    listen 80;
    server_name grafana.mubai.top;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 🚀 部署步骤

### 1. 创建配置文件

```bash
# Jenkins
echo 'server {
    listen 80;
    server_name jenkins.mubai.top;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}' > /etc/nginx/conf.d/jenkins-proxy.conf

# Prometheus
echo 'server {
    listen 80;
    server_name promethus.mubai.top;
    
    location / {
        proxy_pass http://localhost:9090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}' > /etc/nginx/conf.d/prometheus-proxy.conf

# Grafana
echo 'server {
    listen 80;
    server_name grafana.mubai.top;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}' > /etc/nginx/conf.d/grafana-proxy.conf
```

---

### 2. 测试配置

```bash
nginx -t
```

**预期输出：**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

---

### 3. 重载 Nginx

```bash
systemctl reload nginx
```

---

### 4. 验证访问

```bash
# 测试 Jenkins
curl -I http://jenkins.mubai.top

# 测试 Prometheus
curl -I http://promethus.mubai.top

# 测试 Grafana
curl -I http://grafana.mubai.top
```

---

## 🔒 HTTPS 配置（可选）

### 使用 Let's Encrypt

```bash
# 安装 Certbot
apt install -y certbot python3-certbot-nginx

# 获取证书
certbot --nginx -d jenkins.mubai.top -d promethus.mubai.top -d grafana.mubai.top
```

### 手动配置 SSL

```nginx
server {
    listen 443 ssl;
    server_name jenkins.mubai.top;
    
    ssl_certificate /etc/ssl/certs/jenkins.crt;
    ssl_certificate_key /etc/ssl/private/jenkins.key;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 🔧 常用命令

```bash
# 测试配置
nginx -t

# 重载配置
systemctl reload nginx

# 重启 Nginx
systemctl restart nginx

# 查看状态
systemctl status nginx

# 查看日志
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log
```

---

## ⚠️ 注意事项

### 防火墙配置

确保端口 80 (和 443) 开放：
```bash
ufw allow 80/tcp
ufw allow 443/tcp  # 如果使用 HTTPS
```

### DNS 生效

配置 DNS 后可能需要等待几分钟到几小时生效。

### 反向代理问题

如果遇到 502 Bad Gateway：
1. 检查后端服务是否运行
2. 检查 proxy_pass 地址是否正确
3. 查看 Nginx 错误日志

---

## 📊 访问地址汇总

| 服务 | HTTP 地址 | HTTPS 地址（可选） |
|------|---------|------------------|
| **Jenkins** | http://jenkins.mubai.top | https://jenkins.mubai.top |
| **Prometheus** | http://promethus.mubai.top | https://promethus.mubai.top |
| **Grafana** | http://grafana.mubai.top | https://grafana.mubai.top |

---

## 🔗 相关文档

- [Jenkins 部署记录](./jenkins-deployment-record.md)
- [Prometheus + Grafana 部署](./prometheus-grafana-deployment.md)
- [监控指标文档](./cicd-monitoring-metrics.md)

---

**维护者：** OpenClaw 子节点 1  
**最后更新：** 2026-03-23
