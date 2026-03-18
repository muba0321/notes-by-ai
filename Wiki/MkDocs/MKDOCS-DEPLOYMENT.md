# MkDocs 部署完整文档

**部署时间：** 2026-03-17  
**服务器：** 38.246.245.39 (wiki.mubai.top)  
**文档系统：** MkDocs + Material 主题  
**维护者：** OpenClaw 团队

---

## 📋 目录

1. [环境准备](#1-环境准备)
2. [MkDocs 安装](#2-mkdocs-安装)
3. [项目初始化](#3-项目初始化)
4. [主题配置](#4-主题配置)
5. [文档结构](#5-文档结构)
6. [内容更新](#6-内容更新)
7. [构建发布](#7-构建发布)
8. [Nginx 配置](#8-nginx-配置)
9. [自动化脚本](#9-自动化脚本)
10. [常见问题](#10-常见问题)

---

## 1. 环境准备

### 1.1 系统要求

- Ubuntu 22.04+
- Python 3.10+
- Nginx
- root 权限

### 1.2 检查环境

```bash
# 检查 Python
python3 --version  # 应输出 Python 3.10.x

# 检查 pip
pip3 --version

# 检查 Nginx
nginx -v
```

---

## 2. MkDocs 安装

### 2.1 安装 MkDocs 和主题

```bash
# 安装 MkDocs
pip3 install mkdocs

# 安装 Material 主题
pip3 install mkdocs-material

# 验证安装
mkdocs --version
```

### 2.2 安装依赖

```bash
# 安装 Python 依赖
pip3 install \
    mkdocs-material \
    pymdown-extensions \
    markdown-extensions
```

---

## 3. 项目初始化

### 3.1 创建项目目录

```bash
# 创建目录
mkdir -p /opt/mkdocs
cd /opt/mkdocs

# 初始化项目
mkdocs new .
```

### 3.2 目录结构

```
/opt/mkdocs/
├── mkdocs.yml          # 配置文件
├── docs/               # 文档源文件
│   ├── index.md
│   ├── openclaw/
│   ├── scripts/
│   └── tools/
└── site/               # 构建输出（自动生成）
```

---

## 4. 主题配置

### 4.1 编辑 mkdocs.yml

```yaml
site_name: OpenClaw Wiki
site_url: http://wiki.mubai.top
site_author: OpenClaw Team
site_description: OpenClaw 官方文档和脚本库

repo_url: https://github.com/openclaw/openclaw
repo_name: openclaw/openclaw

theme:
  name: material
  language: zh
  palette:
    primary: blue
    accent: blue
  features:
    - navigation.tabs
    - navigation.sections
    - navigation.expand
    - content.code.copy
    - content.code.download

markdown_extensions:
  - pymdownx.highlight:
      anchor_linenums: true
  - pymdownx.inlinehilite
  - pymdownx.snippets
  - pymdownx.superfences
  - tables
  - toc:
      permalink: true
  - attr_list
  - md_in_html
  - pymdownx.emoji:
      emoji_index: !!python/name:material.extensions.emoji.twemoji
      emoji_generator: !!python/name:material.extensions.emoji.to_svg
```

---

## 5. 文档结构

### 5.1 导航配置

```yaml
nav:
  - 首页：index.md
  - 工具分类:
    - 工具首页：tools/index.md
    - OpenClaw 工具：tools/openclaw/index.md
    - Wiki 工具：tools/wiki/index.md
    - Nginx 工具：tools/nginx/index.md
  - OpenClaw 部署:
    - 服务端部署：openclaw/deployment/server.md
    - 子节点部署：openclaw/deployment/subagent.md
    - Wiki.js 部署：openclaw/deployment/wiki.md
  - 配置文档:
    - Gateway 配置：openclaw/configuration/gateway.md
    - 模型配置：openclaw/configuration/model.md
    - 钉钉集成：openclaw/configuration/dingtalk.md
    - 子节点管理：openclaw/configuration/subagent.md
  - 脚本库:
    - 部署脚本:
      - deploy_openclaw_server.sh: scripts/deploy/deploy_openclaw_server.md
      - deploy-subagent.sh: scripts/deploy/deploy-subagent.md
      - deploy-wiki.sh: scripts/deploy/deploy-wiki.md
    - 配置文件:
      - ip.txt: scripts/config/ip-txt.md
      - ip-subagent.txt: scripts/config/ip-subagent-txt.md
      - ip-wiki.txt: scripts/config/ip-wiki-txt.md
    - 工具脚本:
      - set-nginx-password.sh: scripts/tools/set-nginx-password.md
  - 故障排除:
    - SSH 连接问题：openclaw/troubleshooting/ssh.md
    - Node.js 安装：openclaw/troubleshooting/nodejs.md
    - OpenClaw 问题：openclaw/troubleshooting/openclaw.md
    - Gateway 问题：openclaw/troubleshooting/gateway.md
```

### 5.2 文档分类

```
docs/
├── index.md                    # 首页
├── openclaw/
│   ├── deployment/             # 部署文档
│   │   ├── server.md
│   │   ├── subagent.md
│   │   └── wiki.md
│   ├── configuration/          # 配置文档
│   └── troubleshooting/        # 故障排除
├── scripts/
│   ├── deploy/                 # 部署脚本
│   ├── config/                 # 配置文件
│   └── tools/                  # 工具脚本
├── tools/                      # 工具分类
└── assets/                     # 静态资源（下载文件）
```

---

## 6. 内容更新

### 6.1 上传新文档

```bash
# 从本地复制文档到服务器
scp deploy_openclaw_server.sh root@38.246.245.39:/opt/mkdocs/docs/scripts/deploy/
scp deploy_openclaw_server.md root@38.246.245.39:/opt/mkdocs/docs/scripts/deploy/
scp server.md root@38.246.245.39:/opt/mkdocs/docs/openclaw/deployment/
scp subagent.md root@38.246.245.39:/opt/mkdocs/docs/openclaw/deployment/
```

### 6.2 批量上传脚本

```bash
#!/bin/bash
# deploy-wiki-content.sh

WIKI_SERVER="38.246.245.39"
WIKI_USER="root"
WIKI_PASS="Huanxin0321"
LOCAL_DOCS="/data/openclaw/openclaw-deploy/"
REMOTE_DOCS="/opt/mkdocs/docs/"

# 上传部署脚本
sshpass -p "$WIKI_PASS" scp "$LOCAL_DOCS/deploy_openclaw_server.sh" "$WIKI_USER@$WIKI_SERVER:$REMOTE_DOCS/scripts/deploy/"
sshpass -p "$WIKI_PASS" scp "$LOCAL_DOCS/deploy_openclaw_server.md" "$WIKI_USER@$WIKI_SERVER:$REMOTE_DOCS/scripts/deploy/"

# 上传部署文档
sshpass -p "$WIKI_PASS" scp "$LOCAL_DOCS/openclaw 服务端部署 v2.md" "$WIKI_USER@$WIKI_SERVER:$REMOTE_DOCS/openclaw/deployment/server.md"
sshpass -p "$WIKI_PASS" scp "$LOCAL_DOCS/openclaw 子节点部署.md" "$WIKI_USER@$WIKI_SERVER:$REMOTE_DOCS/openclaw/deployment/subagent.md"

echo "文档上传完成"
```

---

## 7. 构建发布

### 7.1 构建站点

```bash
cd /opt/mkdocs

# 构建静态站点
mkdocs build

# 清理旧文件并重新构建
mkdocs build --clean
```

### 7.2 本地预览

```bash
# 启动开发服务器（预览用）
mkdocs serve --dev-addr=0.0.0.0:8000

# 访问 http://服务器 IP:8000
```

### 7.3 部署脚本

```bash
#!/bin/bash
# build-wiki.sh

cd /opt/mkdocs

echo "开始构建 Wiki..."

# 清理并构建
mkdocs build --clean

if [ $? -eq 0 ]; then
    echo "构建成功！"
    echo "站点目录：/opt/mkdocs/site"
    echo "文件大小：$(du -sh /opt/mkdocs/site | cut -f1)"
else
    echo "构建失败！"
    exit 1
fi
```

---

## 8. Nginx 配置

### 8.1 创建配置文件

```bash
cat > /etc/nginx/sites-available/wiki.mubai.top << 'EOF'
server {
    listen 80;
    server_name wiki.mubai.top;

    root /opt/mkdocs/site;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # 强制下载脚本文件
    location /assets/scripts/ {
        add_header Content-Disposition 'attachment';
        add_header Content-Type 'application/octet-stream';
    }

    location ~* \.(css|js|png|jpg|svg|woff|woff2|ico)$ {
        expires 7d;
        add_header Cache-Control "public";
    }

    access_log /var/log/nginx/wiki_access.log;
    error_log /var/log/nginx/wiki_error.log;
}
EOF
```

### 8.2 启用站点

```bash
# 创建软链接
ln -sf /etc/nginx/sites-available/wiki.mubai.top /etc/nginx/sites-enabled/

# 删除默认站点
rm -f /etc/nginx/sites-enabled/default

# 测试配置
nginx -t

# 重新加载
systemctl reload nginx
```

---

## 9. 自动化脚本

### 9.1 完整部署脚本

创建 `/data/openclaw-deploy/deploy-mkdocs-wiki.sh`：

```bash
#!/bin/bash
# MkDocs Wiki 一键部署脚本

set -e

WIKI_SERVER="38.246.245.39"
WIKI_USER="root"
WIKI_PASS="Huanxin0321"

log_info() { echo "[INFO] $1"; }
log_success() { echo "[✓] $1"; }
log_error() { echo "[✗] $1"; }

# 检查 SSH 连接
log_info "检查 SSH 连接..."
if ! sshpass -p "$WIKI_PASS" ssh -o StrictHostKeyChecking=no "$WIKI_USER@$WIKI_SERVER" "echo OK" > /dev/null 2>&1; then
    log_error "SSH 连接失败"
    exit 1
fi
log_success "SSH 连接成功"

# 安装 MkDocs
log_info "安装 MkDocs..."
sshpass -p "$WIKI_PASS" ssh -o StrictHostKeyChecking=no "$WIKI_USER@$WIKI_SERVER" "
    pip3 install mkdocs mkdocs-material -q
    mkdocs --version
"
log_success "MkDocs 安装完成"

# 创建目录结构
log_info "创建目录结构..."
sshpass -p "$WIKI_PASS" ssh -o StrictHostKeyChecking=no "$WIKI_USER@$WIKI_SERVER" "
    mkdir -p /opt/mkdocs/docs/{openclaw/{deployment,configuration,troubleshooting},scripts/{deploy,config,tools},tools/{openclaw,wiki,nginx},assets/scripts}
"
log_success "目录创建完成"

# 配置 Nginx
log_info "配置 Nginx..."
sshpass -p "$WIKI_PASS" ssh -o StrictHostKeyChecking=no "$WIKI_USER@$WIKI_SERVER" "
    cat > /etc/nginx/sites-available/wiki.mubai.top << 'NGINX_EOF'
server {
    listen 80;
    server_name wiki.mubai.top;
    root /opt/mkdocs/site;
    index index.html;
    location / { try_files \$uri \$uri/ /index.html; }
    location /assets/scripts/ {
        add_header Content-Disposition 'attachment';
        add_header Content-Type 'application/octet-stream';
    }
}
NGINX_EOF
    ln -sf /etc/nginx/sites-available/wiki.mubai.top /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    nginx -t && systemctl reload nginx
"
log_success "Nginx 配置完成"

echo ""
echo "========================================"
echo "  MkDocs Wiki 部署完成！"
echo "========================================"
echo ""
echo "访问地址：http://wiki.mubai.top"
echo "文档目录：/opt/mkdocs/docs/"
echo "构建命令：cd /opt/mkdocs && mkdocs build"
echo ""
```

### 9.2 更新脚本

```bash
#!/bin/bash
# update-wiki.sh - 快速更新 Wiki 内容

set -e

REMOTE_SERVER="38.246.245.39"
REMOTE_USER="root"
REMOTE_PASS="Huanxin0321"
LOCAL_DOCS="/data/openclaw/openclaw-deploy/"
REMOTE_DOCS="/opt/mkdocs/docs/"

echo "上传文档到 Wiki 服务器..."

# 上传文档
sshpass -p "$REMOTE_PASS" scp "$LOCAL_DOCS"/*.md "$REMOTE_USER@$REMOTE_SERVER:$REMOTE_DOCS/"

# 构建
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" "
    cd /opt/mkdocs && mkdocs build --clean && systemctl reload nginx
"

echo "Wiki 更新完成！"
```

---

## 10. 常见问题

### 10.1 MkDocs 构建失败

**症状：**
```
ERROR - Error building site
```

**解决：**
```bash
# 检查配置文件
cd /opt/mkdocs
cat mkdocs.yml | python3 -c "import yaml,sys; yaml.safe_load(sys.stdin)"

# 检查 Markdown 语法
mkdocs build --verbose

# 清理缓存
rm -rf site/
mkdocs build --clean
```

### 10.2 Nginx 502 错误

**症状：**
```
HTTP/1.1 502 Bad Gateway
```

**解决：**
```bash
# 检查 MkDocs 构建
cd /opt/mkdocs && mkdocs build

# 检查 site 目录
ls -la /opt/mkdocs/site/

# 检查 Nginx 配置
nginx -t

# 重启 Nginx
systemctl restart nginx
```

### 10.3 下载按钮不工作

**症状：**
点击下载链接打开页面而不是下载文件

**解决：**
```bash
# 修改 Nginx 配置
cat > /etc/nginx/sites-available/wiki.mubai.top << 'EOF'
location /assets/scripts/ {
    add_header Content-Disposition 'attachment';
    add_header Content-Type 'application/octet-stream';
}
EOF

# 重新加载
systemctl reload nginx
```

### 10.4 样式丢失

**症状：**
页面显示正常但没有样式

**解决：**
```bash
# 检查静态文件
ls -la /opt/mkdocs/site/assets/

# 清除浏览器缓存
# 或强制刷新 Ctrl+F5

# 重新构建
cd /opt/mkdocs && mkdocs build --clean
```

---

## 📝 维护清单

### 日常维护

```bash
# 1. 更新文档后构建
cd /opt/mkdocs && mkdocs build --clean

# 2. 检查构建结果
ls -la site/

# 3. 重新加载 Nginx
systemctl reload nginx

# 4. 验证访问
curl -I http://wiki.mubai.top
```

### 定期维护

```bash
# 1. 更新 MkDocs
pip3 install --upgrade mkdocs mkdocs-material

# 2. 检查链接
mkdocs build --strict

# 3. 清理旧文件
rm -rf site/
mkdocs build --clean

# 4. 备份配置
cp mkdocs.yml mkdocs.yml.bak.$(date +%Y%m%d)
```

---

## 🔗 相关资源

| 资源 | 链接 |
|------|------|
| MkDocs 官方文档 | https://www.mkdocs.org/ |
| Material 主题 | https://squidfunk.github.io/mkdocs-material/ |
| 当前 Wiki | http://wiki.mubai.top |
| 服务器 | 38.246.245.39 |

---

**文档版本：** 1.0  
**最后更新：** 2026-03-17  
**维护者：** OpenClaw 团队
