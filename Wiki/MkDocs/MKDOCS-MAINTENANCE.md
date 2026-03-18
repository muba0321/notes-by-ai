# MkDocs 维护文档

**服务器：** 38.246.245.39 (wiki.mubai.top)  
**文档系统：** MkDocs + Material 主题  
**维护周期：** 定期

---

## 📋 目录

1. [日常维护](#1-日常维护)
2. [内容更新](#2-内容更新)
3. [备份恢复](#3-备份恢复)
4. [故障排除](#4-故障排除)
5. [性能优化](#5-性能优化)

---

## 1. 日常维护

### 1.1 检查服务状态

```bash
# SSH 登录服务器
ssh root@38.246.245.39

# 检查 Nginx 状态
systemctl status nginx

# 检查 MkDocs 构建
cd /opt/mkdocs && ls -la site/
```

### 1.2 查看访问日志

```bash
# 查看访问日志
tail -100 /var/log/nginx/wiki.mubai.top_access.log

# 查看错误日志
tail -100 /var/log/nginx/wiki.mubai.top_error.log

# 实时监控
tail -f /var/log/nginx/wiki.mubai.top_access.log
```

### 1.3 清理缓存

```bash
# 清理 MkDocs 缓存
cd /opt/mkdocs
rm -rf site/
mkdocs build --clean

# 重新加载 Nginx
systemctl reload nginx
```

---

## 2. 内容更新

### 2.1 更新单篇文档

```bash
# 方法 1：直接编辑服务器文件
ssh root@38.246.245.39
vi /opt/mkdocs/docs/openclaw/deployment/server.md

# 方法 2：本地编辑后上传
vi server.md
scp server.md root@38.246.245.39:/opt/mkdocs/docs/openclaw/deployment/

# 构建并重新加载
ssh root@38.246.245.39 "cd /opt/mkdocs && mkdocs build --clean && systemctl reload nginx"
```

### 2.2 批量更新文档

使用更新脚本：

```bash
# 从本地目录更新
cd /data/openclaw/openclaw-deploy/
bash /data/openclaw/wiki/mkdocs/update-wiki.sh *.md

# 或手动执行
for file in *.md; do
    scp "$file" root@38.246.245.39:/opt/mkdocs/docs/
done
ssh root@38.246.245.39 "cd /opt/mkdocs && mkdocs build --clean && systemctl reload nginx"
```

### 2.3 添加新页面

```bash
# 1. 创建新文档
cat > /opt/mkdocs/docs/openclaw/deployment/new-feature.md << 'EOF'
# 新功能说明

这里是新功能的详细说明...
EOF

# 2. 编辑 mkdocs.yml 添加导航
vi /opt/mkdocs/mkdocs.yml

# 3. 构建站点
cd /opt/mkdocs && mkdocs build --clean

# 4. 重新加载 Nginx
systemctl reload nginx
```

---

## 3. 备份恢复

### 3.1 备份文档

```bash
# 备份整个文档目录
tar -czf /backup/mkdocs-docs-$(date +%Y%m%d).tar.gz /opt/mkdocs/docs/

# 备份配置文件
cp /opt/mkdocs/mkdocs.yml /backup/mkdocs-config-$(date +%Y%m%d).yml

# 备份 Nginx 配置
cp /etc/nginx/sites-available/wiki.mubai.top /backup/nginx-wiki-$(date +%Y%m%d).conf
```

### 3.2 恢复文档

```bash
# 从备份恢复
tar -xzf /backup/mkdocs-docs-20260317.tar.gz -C /

# 恢复配置
cp /backup/mkdocs-config-20260317.yml /opt/mkdocs/mkdocs.yml

# 重新构建
cd /opt/mkdocs && mkdocs build --clean && systemctl reload nginx
```

### 3.3 自动化备份脚本

```bash
#!/bin/bash
# backup-wiki.sh

BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d)

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 备份文档
tar -czf "$BACKUP_DIR/mkdocs-docs-$DATE.tar.gz" /opt/mkdocs/docs/

# 备份配置
cp /opt/mkdocs/mkdocs.yml "$BACKUP_DIR/mkdocs-config-$DATE.yml"
cp /etc/nginx/sites-available/wiki.mubai.top "$BACKUP_DIR/nginx-wiki-$DATE.conf"

# 删除 30 天前的备份
find "$BACKUP_DIR" -name "mkdocs-*" -mtime +30 -delete

echo "备份完成：$BACKUP_DIR"
```

---

## 4. 故障排除

### 4.1 MkDocs 构建失败

**症状：**
```
ERROR - Error building site
```

**解决：**
```bash
cd /opt/mkdocs

# 检查配置文件
cat mkdocs.yml | python3 -c "import yaml,sys; yaml.safe_load(sys.stdin)"

# 详细构建日志
mkdocs build --verbose

# 清理并重新构建
rm -rf site/
mkdocs build --clean
```

### 4.2 Nginx 502 错误

**症状：**
```
HTTP/1.1 502 Bad Gateway
```

**解决：**
```bash
# 检查 site 目录
ls -la /opt/mkdocs/site/

# 检查是否包含 index.html
ls -la /opt/mkdocs/site/index.html

# 重新构建
cd /opt/mkdocs && mkdocs build --clean

# 检查 Nginx 配置
nginx -t

# 重启 Nginx
systemctl restart nginx
```

### 4.3 样式丢失

**症状：**
页面显示正常但没有样式

**解决：**
```bash
# 检查静态文件
ls -la /opt/mkdocs/site/assets/

# 清除浏览器缓存（Ctrl+F5）

# 重新构建
cd /opt/mkdocs && mkdocs build --clean

# 检查 Nginx 缓存配置
cat /etc/nginx/sites-available/wiki.mubai.top | grep -A5 "location ~*"
```

### 4.4 下载按钮不工作

**症状：**
点击下载链接打开页面而不是下载文件

**解决：**
```bash
# 检查 Nginx 配置
cat /etc/nginx/sites-available/wiki.mubai.top | grep -A3 "assets/scripts"

# 添加强制下载配置
location /assets/scripts/ {
    add_header Content-Disposition 'attachment';
    add_header Content-Type 'application/octet-stream';
}

# 重新加载
systemctl reload nginx
```

### 4.5 导航链接失效

**症状：**
点击导航链接 404

**解决：**
```bash
# 检查 mkdocs.yml 导航配置
cat /opt/mkdocs/mkdocs.yml | grep -A20 "nav:"

# 检查文件是否存在
ls -la /opt/mkdocs/docs/openclaw/deployment/

# 重新构建
cd /opt/mkdocs && mkdocs build --clean
```

---

## 5. 性能优化

### 5.1 启用 Gzip 压缩

```bash
# 编辑 Nginx 配置
cat >> /etc/nginx/sites-available/wiki.mubai.top << 'EOF'

# Gzip 压缩
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json;
EOF

# 重新加载
systemctl reload nginx
```

### 5.2 配置浏览器缓存

```bash
# 在 Nginx 配置中添加
location ~* \.(css|js|png|jpg|svg|woff|woff2|ico)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

### 5.3 优化构建速度

```bash
# 使用 pip 镜像加速
pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple mkdocs mkdocs-material

# 清理不必要的文件
cd /opt/mkdocs
rm -rf .git/ *.log
```

---

## 📝 维护清单

### 每日检查

- [ ] 检查 Nginx 状态
- [ ] 查看错误日志
- [ ] 验证网站可访问

### 每周检查

- [ ] 检查磁盘空间
- [ ] 清理旧日志
- [ ] 检查备份

### 每月检查

- [ ] 更新 MkDocs 和主题
- [ ] 检查链接有效性
- [ ] 审查访问日志
- [ ] 测试备份恢复

---

## 🔧 常用命令速查

```bash
# 构建站点
cd /opt/mkdocs && mkdocs build --clean

# 本地预览
cd /opt/mkdocs && mkdocs serve --dev-addr=0.0.0.0:8000

# 检查 Nginx
systemctl status nginx
nginx -t

# 重新加载
systemctl reload nginx

# 查看日志
tail -f /var/log/nginx/wiki.mubai.top_access.log
tail -f /var/log/nginx/wiki.mubai.top_error.log

# 备份
tar -czf /backup/mkdocs-$(date +%Y%m%d).tar.gz /opt/mkdocs/docs/
```

---

**文档版本：** 1.0  
**最后更新：** 2026-03-17  
**维护者：** OpenClaw 团队
