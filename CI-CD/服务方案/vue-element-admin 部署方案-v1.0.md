# Vue Element Admin 前端部署方案

**文档编号：** FRONTEND-VUE-001  
**版本：** v1.0  
**创建时间：** 2026-03-25  
**状态：** 已上线  
**评审：** 子节点 1 已复核，用户已确认

---

## 1. 概述

### 1.1 项目目标

基于 vue-element-admin 框架部署前端门户，作为后续前端需求开发的基础平台。

### 1.2 技术栈

| 组件 | 版本 | 说明 |
|------|------|------|
| Vue.js | 2.6.10 | 渐进式 JavaScript 框架 |
| Element UI | 2.13.x | Vue 2.0 组件库 |
| Nginx | Alpine | Web 服务器/反向代理 |
| Node.js | 18.x | 构建环境 |

### 1.3 部署架构

```
┌─────────────────────────────────────────────────────────┐
│                  前端部署架构                            │
└─────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │   用户访问       │
                    │ portal.mubai.top│
                    └────────┬────────┘
                             │
                             ▼
              ┌──────────────────────────┐
              │   子节点 1 Nginx          │
              │  (系统 Nginx :80)         │
              │   反向代理                │
              └────────────┬─────────────┘
                           │
                           │ 8081
                           ▼
              ┌──────────────────────────┐
              │   nginx-portal 容器       │
              │   (Docker :8081→80)      │
              │   虚拟主机配置            │
              └────────────┬─────────────┘
                           │
                           │ Docker 网络
                           ▼
              ┌──────────────────────────┐
              │   portal-vue 容器         │
              │   (Vue 静态文件)          │
              │   生产构建 dist           │
              └──────────────────────────┘
```

---

## 2. 部署配置

### 2.1 代码仓库

**仓库地址：** https://github.com/PanJiaChen/vue-element-admin  
**分支：** master  
**版本：** v4.4.0

**本地路径：** `/data/frontend/portal-vue/`

### 2.2 Docker 配置

**文件路径：** `/data/frontend/docker-compose.yml`

```yaml
services:
  portal-vue:
    build:
      context: ./portal-vue
      dockerfile: ../Dockerfile-portal-vue
    container_name: portal-vue
    restart: unless-stopped
    expose:
      - "80"
    networks:
      - frontend

  nginx-portal:
    image: nginx:alpine
    container_name: nginx-portal
    restart: unless-stopped
    ports:
      - "8081:80"
    volumes:
      - ./nginx-portal.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - portal-vue
    networks:
      - frontend

networks:
  frontend:
    driver: bridge
```

### 2.3 Dockerfile

**文件路径：** `/data/frontend/Dockerfile-portal-vue`

```dockerfile
# 多阶段构建 Vue 项目
FROM node:18-alpine AS builder

WORKDIR /app

# 安装 git（某些依赖需要）
RUN apk add --no-cache git

# 复制 package.json
COPY package*.json ./

# 安装依赖（使用淘宝镜像加速）
RUN npm config set registry https://registry.npmmirror.com && \
    npm install

# 复制源代码
COPY . .

# 构建生产版本
RUN npm run build:prod

# 生产阶段：使用 Nginx 提供静态文件
FROM nginx:alpine

# 复制构建好的静态文件
COPY --from=builder /app/dist /usr/share/nginx/html

# 暴露端口
EXPOSE 80

# 启动 nginx
CMD ["nginx", "-g", "daemon off;"]
```

### 2.4 Nginx 容器配置

**文件路径：** `/data/frontend/nginx-portal.conf`

```nginx
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://portal-vue:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 2.5 系统 Nginx 配置

**文件路径：** `/etc/nginx/conf.d/portal.mubai.top.conf`

```nginx
server {
    listen 80;
    server_name portal.mubai.top;
    
    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 3. 部署步骤

### 3.1 克隆代码

```bash
mkdir -p /data/frontend
cd /data/frontend
git clone --depth 1 https://github.com/PanJiaChen/vue-element-admin.git portal-vue
```

### 3.2 构建并启动容器

```bash
cd /data/frontend
docker compose build
docker compose up -d
```

### 3.3 配置系统 Nginx

```bash
cat > /etc/nginx/conf.d/portal.mubai.top.conf << 'EOF'
server {
    listen 80;
    server_name portal.mubai.top;
    
    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

nginx -t && nginx -s reload
```

### 3.4 验证部署

```bash
# 检查容器状态
docker ps | grep portal

# 测试访问
curl -s -o /dev/null -w '%{http_code}' -H 'Host: portal.mubai.top' http://38.246.245.39/

# 预期输出：200
```

---

## 4. 访问方式

### 4.1 域名访问

| 域名 | URL | 说明 |
|------|-----|------|
| **Portal** | http://portal.mubai.top | 主域名访问 |

### 4.2 直接访问

| 方式 | URL | 说明 |
|------|-----|------|
| 子节点 1 | http://38.246.245.39:8081 | 容器端口直连 |

### 4.3 默认登录

vue-element-admin 默认提供以下测试账号：

| 用户名 | 密码 | 角色 |
|--------|------|------|
| admin | admin | 管理员 |
| editor | editor | 编辑 |

**登录页面：** http://portal.mubai.top/login

---

## 5. 运维操作

### 5.1 服务管理

```bash
# 查看服务状态
docker ps | grep -E 'portal|nginx'

# 重启服务
cd /data/frontend
docker compose restart

# 停止服务
docker compose down

# 查看日志
docker logs portal-vue --tail 50
docker logs nginx-portal --tail 50
```

### 5.2 代码更新

```bash
cd /data/frontend/portal-vue

# 拉取最新代码
git pull origin master

# 重新构建
cd /data/frontend
docker compose build --no-cache
docker compose up -d
```

### 5.3 健康检查

```bash
# 检查容器状态
docker inspect --format='{{.State.Health.Status}}' portal-vue

# 检查 HTTP 状态
curl -s -o /dev/null -w '%{http_code}' -H 'Host: portal.mubai.top' http://38.246.245.39/

# 预期输出：200
```

---

## 6. 开发指南

### 6.1 本地开发

```bash
# 进入项目目录
cd /data/frontend/portal-vue

# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 访问 http://localhost:9527
```

### 6.2 构建生产版本

```bash
# 生产环境构建
npm run build:prod

# 输出目录：dist/
```

### 6.3 目录结构

```
portal-vue/
├── src/                    # 源代码
│   ├── api/               # API 接口
│   ├── assets/            # 静态资源
│   ├── components/        # 组件
│   ├── directive/         # 指令
│   ├── filters/           # 过滤器
│   ├── icons/             # 图标
│   ├── layout/            # 布局
│   ├── router/            # 路由
│   ├── store/             # 状态管理
│   ├── styles/            # 样式
│   ├── utils/             # 工具函数
│   ├── vendor/            # 第三方库
│   ├── views/             # 页面
│   ├── App.vue            # 根组件
│   └── main.js            # 入口文件
├── public/                 # 公共资源
├── dist/                   # 构建输出
├── package.json            # 依赖配置
└── vue.config.js           # Vue 配置
```

---

## 7. 常见问题

### 7.1 构建失败

**问题：** npm install 报错

**解决方案：**
```bash
# 清理缓存
npm cache clean --force

# 使用淘宝镜像
npm config set registry https://registry.npmmirror.com

# 重新安装
rm -rf node_modules package-lock.json
npm install
```

### 7.2 端口冲突

**问题：** 8081 端口被占用

**解决方案：**
```bash
# 查看占用端口的进程
ss -tlnp | grep 8081

# 修改 docker-compose.yml 端口映射
ports:
  - "8082:80"  # 改为其他端口

# 更新系统 Nginx 配置
proxy_pass http://127.0.0.1:8082;
```

### 7.3 白屏问题

**问题：** 访问页面显示白屏

**排查步骤：**
1. 检查浏览器控制台错误
2. 确认 Vue 路由模式（hash/history）
3. 检查 Nginx 配置中的 try_files
4. 确认 dist 目录文件完整

---

## 8. 安全建议

### 8.1 访问控制

- ✅ 修改默认登录密码
- ✅ 配置 HTTPS（Let's Encrypt）
- ✅ 启用 Nginx 访问日志
- ✅ 配置 CORS 策略

### 8.2 构建安全

- ✅ 定期更新依赖包
- ✅ 扫描 npm 漏洞（npm audit）
- ✅ 使用固定版本依赖
- ✅ 移除开发依赖

### 8.3 容器安全

- ✅ 使用非 root 用户运行
- ✅ 限制容器资源
- ✅ 定期更新基础镜像
- ✅ 只读文件系统（生产环境）

---

## 9. 变更记录

| 版本 | 日期 | 变更内容 | 变更人 |
|------|------|----------|--------|
| v1.0 | 2026-03-25 | 初始部署 | OpenClaw |

---

## 10. 相关文档

- [vue-element-admin 官方文档](https://panjiachen.github.io/vue-element-admin-site/)
- [Vue.js 官方文档](https://vuejs.org/)
- [Element UI 文档](https://element.eleme.cn/)
- [Docker 最佳实践](./服务方案/Docker 部署最佳实践.md)

---

**文档归档位置：** `/data/openclaw-dist/CI-CD/服务方案/vue-element-admin 部署方案-v1.0.md`  
**Git 仓库：** `https://github.com/muba0321/notes-by-ai`  
**同步状态：** 待提交
