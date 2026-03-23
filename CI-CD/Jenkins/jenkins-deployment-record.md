# Jenkins 部署记录

**部署日期：** 2026-03-23  
**部署位置：** 子节点 1 (38.246.245.39)  
**部署方式：** Docker 容器

---

## 📦 部署信息

| 项目 | 值 |
|------|-----|
| **Jenkins 版本** | 2.541.3 (LTS) |
| **镜像** | jenkins/jenkins:lts-jdk17 |
| **容器 ID** | 2563933a0611 |
| **数据目录** | /data/jenkins |
| **Web 端口** | 8080 |
| **Agent 端口** | 50000 |

---

## 🔐 登录信息

**访问地址：** http://38.246.245.39:8080

**初始管理员密码：**
```
0f344adb7f864361a5a8a08d8e6c4d10
```

⚠️ **重要：** 首次登录后请立即修改密码并保存！

---

## 🚀 启动命令

```bash
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /data/jenkins:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e JAVA_OPTS='-Xmx2048m' \
  jenkins/jenkins:lts-jdk17
```

---

## 🔧 常用命令

### 查看状态
```bash
docker ps | grep jenkins
docker logs jenkins
```

### 重启
```bash
docker restart jenkins
```

### 停止
```bash
docker stop jenkins
```

### 启动
```bash
docker start jenkins
```

### 查看密码
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 进入容器
```bash
docker exec -it jenkins bash
```

---

## 📋 初始化步骤

1. **访问** http://38.246.245.39:8080

2. **输入初始密码** 完成认证

3. **安装插件**
   - 选择 "Install suggested plugins"（推荐插件）
   - 等待安装完成（约 5-10 分钟）

4. **创建管理员账号**
   - 用户名：admin
   - 密码：（设置强密码）
   - 邮箱：（可选）

5. **配置 Jenkins URL**
   - 默认：http://38.246.245.39:8080
   - 确认即可

6. **完成初始化**

---

## 🔌 推荐插件

### 必装插件

| 插件名 | 用途 |
|--------|------|
| **Pipeline** | 流水线支持 |
| **GitHub Integration** | GitHub 集成 |
| **Docker Pipeline** | Docker 构建支持 |
| **Kubernetes** | K8s 部署支持 |
| **Ansible** | Ansible 集成 |
| **Blue Ocean** | 现代化 UI |
| **Config File Provider** | 配置文件管理 |
| **Credentials Binding** | 凭证绑定 |

### 可选插件

| 插件名 | 用途 |
|--------|------|
| **SonarQube Scanner** | 代码质量扫描 |
| **Harbor** | Harbor 镜像仓库集成 |
| **Email Extension** | 邮件通知 |
| **Slack Notification** | Slack 通知 |
| **Build Timeout** | 构建超时控制 |

---

## 🔗 关联配置

### GitHub 凭证配置

1. 进入 **Manage Jenkins** → **Credentials**

2. 添加 GitHub 凭证：
   - Kind: Username with password
   - Username: GitHub 用户名
   - Password: GitHub Personal Access Token
   - ID: github-credentials

### K8s 凭证配置

1. 进入 **Manage Jenkins** → **Credentials**

2. 添加 K8s 凭证：
   - Kind: Secret file
   - File: kubeconfig 文件
   - ID: k8s-kubeconfig

### Docker Registry 配置

1. 进入 **Manage Jenkins** → **Credentials**

2. 添加 Harbor 凭证：
   - Kind: Username with password
   - Username: Harbor 账号
   - Password: Harbor 密码
   - ID: harbor-credentials

---

## 📊 健康检查

### 检查 Jenkins 状态
```bash
curl http://38.246.245.39:8080/login
```

### 检查端口
```bash
netstat -tlnp | grep 8080
netstat -tlnp | grep 50000
```

### 检查磁盘空间
```bash
df -h /data/jenkins
```

### 检查日志
```bash
docker logs jenkins | tail -50
```

---

## ⚠️ 注意事项

### 安全配置

1. **修改默认密码** - 首次登录后立即修改
2. **配置 HTTPS** - 生产环境建议配置 SSL
3. **限制访问** - 配置防火墙只允许信任 IP
4. **定期备份** - 备份 /data/jenkins 目录

### 性能优化

1. **JVM 参数** - 根据内存调整 JAVA_OPTS
2. **构建并发** - 配置同时构建数量
3. **工作空间清理** - 定期清理旧构建

### 备份策略

```bash
# 备份 Jenkins 数据
tar czf jenkins-backup-$(date +%Y%m%d).tar.gz /data/jenkins

# 恢复到新服务器
tar xzf jenkins-backup.tar.gz -C /data/jenkins
```

---

## 🔧 故障排除

### Jenkins 无法启动

```bash
# 查看日志
docker logs jenkins

# 检查端口占用
netstat -tlnp | grep 8080

# 检查磁盘空间
df -h
```

### 无法连接 Docker

```bash
# 检查 socket 权限
ls -la /var/run/docker.sock

# 重启 Docker
systemctl restart docker
```

### 构建失败

```bash
# 检查插件版本
# 进入 Manage Jenkins → Manage Plugins

# 检查凭证配置
# 进入 Manage Jenkins → Credentials
```

---

## 📚 相关文档

- [Jenkins 官方文档](https://www.jenkins.io/doc/)
- [CI/CD 平台产品流程设计](./cicd-platform-design.md)
- [CI/CD 部署完整指南](./cicd-deployment-guide.md)
- [安装脚本索引](../../OpenClaw/scripts/cicd/cicd-scripts-index.md)

---

**部署者：** OpenClaw 子节点 1  
**最后更新：** 2026-03-23  
**状态：** ✅ 运行中
