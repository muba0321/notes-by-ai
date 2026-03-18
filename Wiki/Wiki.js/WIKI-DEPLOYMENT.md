# Wiki.js 部署文档

本文档包含 Wiki.js 的**脚本部署**和**手工部署**两种方式的完整指南。

---

## 📋 目录

1. [Wiki.js 简介](#wikijs-简介)
2. [前置要求](#前置要求)
3. [脚本部署](#脚本部署)
4. [手工部署](#手工部署)
5. [初始化配置](#初始化配置)
6. [备份与恢复](#备份与恢复)
7. [常见问题](#常见问题)

---

## Wiki.js 简介

**Wiki.js** 是一个现代化、开源的 Wiki 平台，特点：

- ✅ 原生 Markdown 支持
- ✅ 美观的现代化界面
- ✅ Git 同步备份
- ✅ 完善的权限管理
- ✅ 全文搜索
- ✅ 支持多种数据库（SQLite/PostgreSQL/MySQL）

**官网**: https://js.wiki/

---

## 前置要求

### 服务器要求

| 项目 | 要求 |
|------|------|
| CPU | 1 核心以上 |
| 内存 | 512 MB 以上 |
| 磁盘 | 5 GB 以上 |
| 系统 | Ubuntu 20.04+ / Debian 10+ / CentOS 8+ |
| 端口 | 80 (HTTP), 443 (HTTPS) |

### 域名要求

- 域名已解析到服务器 IP
- DNS 记录类型：A 记录

---

## 脚本部署

### 步骤 1：准备服务器列表

```bash
# 创建 IP 文件
vi /data/ip-wiki.txt

# 格式：IP:SSH 端口：用户名：密码
# 示例：
38.246.245.39:22:root:Huanxin0321
```

### 步骤 2：安装 sshpass（本地机器）

```bash
apt install -y sshpass
```

### 步骤 3：执行部署

```bash
# 使用默认域名 wiki.mubai.top
cd /data
chmod +x deploy-wiki.sh
./deploy-wiki.sh

# 或指定域名
./deploy-wiki.sh your-domain.com
```

### 步骤 4：等待部署完成

脚本会自动完成：
1. 安装 Docker
2. 安装 Docker Compose
3. 创建 Wiki.js 容器
4. 创建 Nginx 容器
5. 申请 SSL 证书

### 步骤 5：访问初始化

打开浏览器访问：`https://wiki.mubai.top`

首次访问需要：
1. 创建管理员账户
2. 配置站点信息
3. 配置认证方式

---

## 手工部署

### 步骤 1：SSH 登录服务器

```bash
ssh root@38.246.245.39
```

### 步骤 2：安装 Docker

```bash
# 一键安装 Docker
curl -fsSL https://get.docker.com | bash

# 启动 Docker
systemctl enable docker
systemctl start docker

# 验证安装
docker --version

# 添加当前用户到 docker 组（可选）
usermod -aG docker $USER
```

### 步骤 3：安装 Docker Compose

```bash
# Ubuntu 22.04+ 使用插件方式
apt install -y docker-compose-plugin

# 验证
docker compose version

# 或手动安装（旧系统）
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

### 步骤 4：创建 Wiki.js 目录

```bash
# 创建目录结构
mkdir -p /opt/wiki/data
mkdir -p /opt/wiki/logs
mkdir -p /opt/wiki/ssl
mkdir -p /var/www/certbot

# 进入目录
cd /opt/wiki
```

### 步骤 5：创建 Docker Compose 配置

```bash
cat > /opt/wiki/docker-compose.yml << 'EOF'
version: '3.8'
services:
  wiki:
    image: requarks/wiki:latest
    container_name: wiki
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"
    environment:
      - DB_TYPE=sqlite
      - DB_FILEPATH=/var/lib/wiki/db.sqlite
    volumes:
      - wiki-data:/var/lib/wiki
      - ./logs:/var/logs/wiki
    networks:
      - wiki-network

  nginx:
    image: nginx:alpine
    container_name: wiki-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/letsencrypt:ro
    depends_on:
      - wiki
    networks:
      - wiki-network

volumes:
  wiki-data:

networks:
  wiki-network:
    driver: bridge
EOF
```

**配置说明**：
- `wiki` 服务：Wiki.js 主应用，监听 3000 端口
- `nginx` 服务：反向代理，处理 80/443 端口
- `wiki-data` 卷：持久化存储 Wiki 数据
- 网络隔离：Wiki 不直接暴露，只通过 Nginx 访问

### 步骤 6：创建 Nginx 配置（HTTP 阶段）

```bash
cat > /opt/wiki/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    server_tokens off;
    
    # HTTP 服务器 - 用于 SSL 证书验证
    server {
        listen 80;
        server_name wiki.mubai.top;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            return 301 https://$server_name$request_uri;
        }
    }
    
    # HTTPS 服务器（证书申请后启用）
    server {
        listen 443 ssl http2;
        server_name wiki.mubai.top;
        
        ssl_certificate /etc/letsencrypt/live/wiki.mubai.top/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/wiki.mubai.top/privkey.pem;
        
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
        
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        
        client_max_body_size 50M;
        
        location / {
            proxy_pass http://wiki:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
            proxy_buffering off;
        }
        
        access_log /var/log/nginx/wiki_access.log;
        error_log /var/log/nginx/wiki_error.log;
    }
}
EOF

# 替换实际域名（如果不是 wiki.mubai.top）
sed -i "s/wiki.mubai.top/your-domain.com/g" /opt/wiki/nginx.conf
```

### 步骤 7：启动容器

```bash
cd /opt/wiki
docker compose up -d

# 查看状态
docker compose ps

# 查看日志
docker compose logs -f
```

### 步骤 8：申请 SSL 证书

```bash
# 使用 Certbot 申请证书
docker run --rm \
    -v /opt/wiki/ssl:/etc/letsencrypt \
    -v /var/www/certbot:/var/www/certbot \
    certbot/certbot certonly \
    --webroot -w /var/www/certbot \
    -d wiki.mubai.top \
    --email admin@your-domain.com \
    --agree-tos \
    --non-interactive
```

**如果自动申请失败，手动申请**：
```bash
# 1. 临时停止 Nginx 的 80 端口占用
docker compose stop nginx

# 2. 使用 standalone 模式申请
docker run --rm \
    -v /opt/wiki/ssl:/etc/letsencrypt \
    -p 80:80 \
    certbot/certbot certonly \
    --standalone \
    -d wiki.mubai.top \
    --email admin@your-domain.com \
    --agree-tos \
    --non-interactive

# 3. 重新启动 Nginx
docker compose start nginx
```

### 步骤 9：验证部署

```bash
# 检查容器状态
docker compose ps

# 检查端口监听
netstat -tlnp | grep -E '80|443'

# 测试访问
curl -I https://wiki.mubai.top

# 查看 Wiki 日志
docker logs wiki --tail 20
```

---

## 初始化配置

### 首次访问

1. 打开浏览器访问：`https://wiki.mubai.top`
2. 点击 "Create Account" 创建管理员账户
3. 填写信息：
   - 邮箱
   - 用户名
   - 密码
4. 配置站点：
   - Site Name: 例如 "OpenClaw Wiki"
   - Site URL: `https://wiki.mubai.top`

### 配置 Git 备份（推荐）

1. 进入管理后台 → **Storage**
2. 点击 **Git**
3. 配置 Git 仓库：
   ```
   Repository URL: git@github.com:your-user/wiki-backup.git
   Branch: main
   Author Name: Wiki Bot
   Author Email: bot@your-domain.com
   ```
4. 启用自动同步

### 配置 Markdown 导出

1. 进入管理后台 → **Modules**
2. 确保 **Markdown** 编辑器已启用
3. 页面编辑时可选择 Markdown 模式

---

## 备份与恢复

### 方式 A：数据库备份

```bash
# 进入 Wiki 目录
cd /opt/wiki

# 备份数据卷
docker compose exec wiki tar -czf /var/lib/wiki/backup.tar.gz /var/lib/wiki

# 复制到本地
docker cp wiki:/var/lib/wiki/backup.tar.gz ./wiki-backup-$(date +%Y%m%d).tar.gz
```

### 方式 B：Git 同步

在管理后台配置 Git 后，内容会自动同步到 Git 仓库：

```bash
# 克隆备份
git clone git@github.com:your-user/wiki-backup.git

# 所有页面都是 Markdown 文件
ls wiki-backup/pages/
```

### 方式 C：完整备份

```bash
# 备份整个目录
tar -czf wiki-full-backup.tar.gz /opt/wiki

# 备份 Docker 卷
docker run --rm \
    -v wiki_wiki-data:/data \
    -v $(pwd):/backup \
    alpine tar -czf /backup/wiki-data.tar.gz /data
```

### 恢复数据

```bash
# 1. 停止容器
docker compose down

# 2. 恢复数据卷
docker run --rm \
    -v wiki_wiki-data:/data \
    -v $(pwd):/backup \
    alpine tar -xzf /backup/wiki-data.tar.gz -C /

# 3. 重启容器
docker compose up -d
```

---

## 常见问题

### 问题 1：SSL 证书申请失败

```
Failed authorization procedure.
```

**原因**：域名未解析或 80 端口被占用

**解决方案**：
```bash
# 1. 检查域名解析
dig wiki.mubai.top

# 2. 检查 80 端口
netstat -tlnp | grep :80

# 3. 使用 standalone 模式
docker run --rm \
    -v /opt/wiki/ssl:/etc/letsencrypt \
    -p 80:80 \
    certbot/certbot certonly \
    --standalone \
    -d wiki.mubai.top \
    --email admin@your-domain.com \
    --agree-tos
```

---

### 问题 2：Wiki 无法访问

```
502 Bad Gateway
```

**原因**：Wiki 容器未启动

**解决方案**：
```bash
# 检查容器状态
docker compose ps

# 重启容器
docker compose restart wiki

# 查看日志
docker logs wiki
```

---

### 问题 3：Markdown 导出

**导出单个页面**：
1. 打开页面
2. 点击页面右上角 **⋮**
3. 选择 **Export** → **Markdown**

**批量导出**：
1. 管理后台 → **Storage**
2. 配置 Git 同步
3. 所有页面会自动同步为 MD 文件

---

### 问题 4：数据迁移

**迁移到新服务器**：
```bash
# 1. 在旧服务器备份
docker compose exec wiki tar -czf /var/lib/wiki/backup.tar.gz /var/lib/wiki
docker cp wiki:/var/lib/wiki/backup.tar.gz ./

# 2. 复制到新服务器
scp wiki-backup.tar.gz root@new-server:/opt/wiki/

# 3. 在新服务器恢复
docker compose up -d
docker cp backup.tar.gz wiki:/var/lib/wiki/
docker compose exec wiki tar -xzf /var/lib/wiki/backup.tar.gz -C /
```

---

### 问题 5：性能优化

**启用缓存**：
```bash
# 编辑 docker-compose.yml，添加 Redis
services:
  redis:
    image: redis:alpine
    container_name: wiki-redis
    restart: unless-stopped

# Wiki 配置中启用 Redis 缓存
```

**调整 Nginx 缓存**：
```nginx
# 在 nginx.conf 的 location / 中添加
proxy_cache_valid 200 10m;
proxy_cache_valid 404 1m;
```

---

## 管理命令速查

```bash
# 进入目录
cd /opt/wiki

# 查看状态
docker compose ps

# 查看日志
docker compose logs -f
docker logs wiki --tail 50

# 重启
docker compose restart

# 停止
docker compose stop

# 启动
docker compose start

# 更新 Wiki.js
docker compose pull wiki
docker compose up -d wiki

# 备份
docker compose exec wiki tar -czf /var/lib/wiki/backup.tar.gz /var/lib/wiki
docker cp wiki:/var/lib/wiki/backup.tar.gz ./wiki-backup.tar.gz

# 进入容器
docker compose exec wiki sh
```

---

## 文件结构

```
/opt/wiki/
├── docker-compose.yml      # Docker Compose 配置
├── nginx.conf              # Nginx 配置
├── ssl/                    # SSL 证书目录
│   └── live/
│       └── wiki.mubai.top/
│           ├── fullchain.pem
│           └── privkey.pem
├── logs/                   # Wiki 日志
└── data/                   # 数据目录（Docker 卷）
```

---

## 安全建议

1. **定期备份**：配置 Git 自动同步
2. **更新维护**：定期 `docker compose pull` 更新镜像
3. **强密码**：管理员账户使用强密码
4. **防火墙**：只开放 80/443 端口
5. **监控日志**：定期检查 `/var/log/nginx/` 和 Wiki 日志

---

## 支持资源

| 资源 | 链接 |
|------|------|
| 官方文档 | https://docs.requarks.io/ |
| GitHub | https://github.com/Requarks/wiki |
| Docker Hub | https://hub.docker.com/r/requarks/wiki |
| 社区 | https://talk.js.wiki/ |

---

## 更新日志

| 日期 | 版本 | 更新内容 |
|------|------|----------|
| 2026-03-16 | 1.2 | 添加部署后初始化、中文化配置、页面组织指南 |
| 2026-03-16 | 1.1 | 修复数据库路径问题，添加故障排除 |
| 2026-03-16 | 1.0 | 初始版本，Wiki.js 部署指南 |

---

## 部署后操作

### 首次初始化

1. **访问初始化页面**
   ```
   http://38.246.245.39
   ```

2. **创建管理员账户**
   - Email: `admin@mubai.top`
   - Username: `admin`
   - Name: `Administrator`
   - Password: `Admin123456!`

3. **配置站点信息**
   - Site Name: `OpenClaw Wiki`
   - Site URL: `http://wiki.mubai.top`

4. **完成初始化**

---

### 中文化配置

**第 1 步：下载中文语言包**

1. 登录后，点击左下角 **Administration**（管理）
2. 左侧菜单：**Settings** → **Locale**（设置 → 语言环境）
3. 找到 **简体中文 (zh-CN)**
4. 点击右侧的 **Download** 按钮
5. 等待下载完成（状态变为 Available）

**第 2 步：设置为中文**

1. 在 **Site Locale** 下拉框选择 **简体中文**
2. 勾选 **Update Automatically**（自动更新）
3. 点击 **Save** 保存

**第 3 步：刷新页面**

按 F5 刷新浏览器，界面变为中文

---

### 页面组织结构

Wiki.js 支持多层级目录结构，推荐这样组织：

```
/
├── 🏠 Home (首页)
├── 📦 OpenClaw 部署
│   ├── 服务端部署（带 Nginx 反向代理）
│   ├── 子节点部署（任务执行节点）
│   └── Wiki.js 部署
├── ⚙️ 配置文档
│   ├── Gateway 配置
│   ├── 模型配置（阿里云百炼）
│   ├── 钉钉集成
│   └── 子节点管理
├── 📜 脚本库
│   ├── deploy-nginx.sh
│   ├── deploy-subagent.sh
│   ├── deploy-wiki.sh
│   └── 其他工具脚本
├── 🔧 故障排除
│   ├── SSH 连接问题
│   ├── Node.js 安装
│   ├── OpenClaw 问题
│   └── Gateway 问题
└── 📚 其他文档
    ├── API 文档
    ├── 使用手册
    └── 最佳实践
```

**创建多层级页面**：
1. 点击 **New Page**（新建页面）
2. 在 **Path** 字段输入路径，如：`openclaw/deployment/server`
3. 填写标题和内容
4. 保存

**配置导航菜单**：
1. **Administration** → **Navigation**
2. 添加菜单项，拖拽排序
3. 保存

---

## 已解决的问题

### 问题：SQLITE_CANTOPEN 错误

**现象**：Wiki.js 启动失败，日志显示 `Database Connection Error: SQLITE_CANTOPEN`

**原因**：Docker 卷挂载路径不正确

**解决方案**：使用正确的路径 `/wiki/data`：

```yaml
services:
  wiki:
    environment:
      - DB_TYPE=sqlite
      - DB_FILEPATH=/wiki/data/db.sqlite
    volumes:
      - wiki-data:/wiki/data
```
