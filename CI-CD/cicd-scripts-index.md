# CI/CD 安装脚本集合

_Jenkins + GitHub + Ansible + K8s 完整安装脚本_

**创建日期：** 2026-03-23  
**用途：** 自动化部署 CI/CD 平台组件

---

## 📁 脚本清单

| 脚本名 | 用途 | 执行位置 | 必须性 |
|--------|------|---------|--------|
| `install-base-tools.sh` | 安装基础工具（Docker/Ansible/Git/kubectl） | 子节点 1 | 🔴 必须 |
| `install-jenkins.sh` | 部署 Jenkins（Docker） | 子节点 1 | 🔴 必须 |
| `install-harbor.sh` | 部署 Harbor 镜像仓库 | 子节点 1 | 🟡 推荐 |
| `install-sonarqube.sh` | 部署 SonarQube 代码质量 | 子节点 1 | 🟡 推荐 |
| `k8s-cluster-setup.yml` | K8s 集群配置（Ansible） | 子节点 1 | 🔴 必须 |
| `jenkins-credentials-setup.yml` | Jenkins 凭证配置 | 子节点 1 | 🟡 推荐 |
| `verify-environment.sh` | 环境验证脚本 | 全部节点 | 🟡 推荐 |
| `test-cicd-pipeline.sh` | CI/CD 流程测试 | 子节点 1 | 🟡 推荐 |
| `test-rollback.sh` | 回滚测试脚本 | 子节点 1 | 🟡 推荐 |
| `backup-cicd.sh` | 备份脚本 | 子节点 1 | 🟡 推荐 |

---

## 🚀 快速开始

### 1. 基础环境安装

```bash
# 下载脚本
cd /data/openclaw-dist/OpenClaw/scripts/cicd

# 执行基础安装
chmod +x install-base-tools.sh
./install-base-tools.sh
```

**预计时间：** 10-15 分钟

---

### 2. Jenkins 部署

```bash
# 执行 Jenkins 安装
chmod +x install-jenkins.sh
./install-jenkins.sh

# 获取初始密码
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

**预计时间：** 5 分钟

**访问地址：** http://子节点 1-IP:8080

---

### 3. Harbor 部署（可选）

```bash
# 执行 Harbor 安装
chmod +x install-harbor.sh
./install-harbor.sh
```

**预计时间：** 10 分钟

**访问地址：** http://子节点 1-IP:8082  
**管理员账号：** admin / Harbor12345

---

### 4. SonarQube 部署（可选）

```bash
# 执行 SonarQube 安装
chmod +x install-sonarqube.sh
./install-sonarqube.sh
```

**预计时间：** 5 分钟

**访问地址：** http://子节点 1-IP:9000  
**默认账号：** admin / admin

---

### 5. K8s 集群配置

```bash
# 执行 Ansible Playbook
ansible-playbook k8s-cluster-setup.yml -i inventory.ini
```

**预计时间：** 20 分钟（4 台机器）

---

### 6. 环境验证

```bash
# 执行验证脚本
chmod +x verify-environment.sh
./verify-environment.sh
```

**预期输出：** 所有组件版本信息和状态

---

## 📋 完整部署流程

```
1. install-base-tools.sh    (10-15 分钟)
       ↓
2. install-jenkins.sh       (5 分钟)
       ↓
3. install-harbor.sh        (10 分钟，可选)
       ↓
4. install-sonarqube.sh     (5 分钟，可选)
       ↓
5. k8s-cluster-setup.yml    (20 分钟)
       ↓
6. jenkins-credentials-setup.yml (5 分钟)
       ↓
7. verify-environment.sh    (2 分钟)
       ↓
8. test-cicd-pipeline.sh    (10 分钟)
       ↓
部署完成
```

**总预计时间：** 60-70 分钟（含可选组件）

---

## 🔧 脚本说明

### install-base-tools.sh

**功能：**
- 安装 Docker 24.0+
- 安装 Ansible 2.14+
- 安装 Git 2.35+
- 安装 kubectl 1.26+
- 安装 Helm 3.x

**依赖：** Ubuntu 22.04+

**修改项：** 无需修改

---

### install-jenkins.sh

**功能：**
- 拉取 Jenkins LTS 镜像
- 创建数据卷
- 启动 Jenkins 容器
- 输出初始管理员密码

**端口：** 8080 (Web), 50000 (Agent)

**数据目录：** `/data/jenkins`

**修改项：**
- `JENKINS_VERSION` - Jenkins 版本号
- `JENKINS_HOME` - 数据目录路径

---

### install-harbor.sh

**功能：**
- 下载 Harbor 离线安装包
- 配置 harbor.yml
- 安装 Harbor（含 Trivy 和 ChartMuseum）

**端口：** 8082 (Web)

**数据目录：** `/data/harbor`

**修改项：**
- `HARBOR_VERSION` - Harbor 版本号
- `hostname` - 修改为实际 IP 或域名

---

### install-sonarqube.sh

**功能：**
- 拉取 SonarQube 镜像
- 创建数据卷
- 启动 SonarQube 容器

**端口：** 9000 (Web)

**数据目录：** `/data/sonarqube`

**修改项：**
- `SONAR_VERSION` - SonarQube 版本号

---

### k8s-cluster-setup.yml

**功能：**
- 安装 Kubernetes 组件（kubeadm/kubelet/kubectl）
- 配置容器运行时
- 配置内核参数

**目标主机：** K8s 集群所有节点

**修改项：**
- `k8s_version` - K8s 版本号
- `inventory.ini` - 主机清单

---

### jenkins-credentials-setup.yml

**功能：**
- 添加 GitHub 凭证
- 添加 K8s 凭证
- 添加 Harbor 凭证

**修改项：**
- `jenkins_url` - Jenkins 地址
- `jenkins_user` - 管理员账号
- `jenkins_token` - API Token
- GitHub 用户名和 Token
- K8s kubeconfig 文件路径

---

### verify-environment.sh

**功能：**
- 验证所有工具版本
- 验证服务可访问性
- 验证 K8s 集群状态

**输出：** 各组件状态和版本信息

---

### test-cicd-pipeline.sh

**功能：**
- 创建测试仓库
- 推送测试代码
- 触发 Jenkins 构建
- 验证构建结果
- 验证 K8s 部署

**前置条件：**
- Jenkins 已配置 GitHub Webhook
- K8s 集群可用

---

### test-rollback.sh

**功能：**
- 记录当前版本
- 执行 K8s 回滚
- 验证回滚结果

**用途：** 验证回滚机制是否正常

---

### backup-cicd.sh

**功能：**
- 备份 Jenkins 数据
- 备份 Harbor 数据
- 备份 K8s 配置
- 清理旧备份（>30 天）

**备份目录：** `/data/backups`

**建议：** 添加到 cron 定时执行

```bash
# 每天凌晨 2 点备份
0 2 * * * /data/openclaw-dist/OpenClaw/scripts/cicd/backup-cicd.sh
```

---

## 📝 Inventory 示例

```ini
# inventory.ini
[k8s_cluster]
master1 ansible_host=124.132.136.17 ansible_port=9005 ansible_user=root
node1 ansible_host=124.132.136.17 ansible_port=9191 ansible_user=root
node2 ansible_host=124.132.136.17 ansible_port=9053 ansible_user=root
node3 ansible_host=124.132.136.17 ansible_port=9010 ansible_user=root

[jenkins_server]
subagent1 ansible_host=38.246.245.39 ansible_user=root

[k8s_cluster:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

---

## ⚠️ 注意事项

### 执行前准备

1. **确认系统版本**
   ```bash
   cat /etc/os-release
   # 应为 Ubuntu 22.04+
   ```

2. **确认网络连接**
   ```bash
   ping -c 4 github.com
   ping -c 4 docker.io
   ```

3. **确认 SSH 访问**
   ```bash
   ssh root@124.132.136.17 -p 9005
   ```

4. **备份现有配置**
   ```bash
   cp -r /etc/ansible /etc/ansible.bak
   cp -r ~/.kube ~/.kube.bak
   ```

### 执行中注意

- 使用 `screen` 或 `tmux` 执行长耗时脚本
- 保持网络稳定
- 不要中途中断脚本

### 执行后验证

- 运行 `verify-environment.sh`
- 手动访问各服务 Web UI
- 执行 `test-cicd-pipeline.sh`

---

## 🔧 故障排除

### 脚本执行失败

```bash
# 启用调试模式
bash -x install-base-tools.sh

# 查看详细日志
tail -f /var/log/apt/history.log
```

### Docker 拉取镜像失败

```bash
# 配置 Docker 镜像加速
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.cn-hangzhou.aliyuncs.com"
  ]
}
EOF

# 重启 Docker
systemctl restart docker
```

### Ansible 连接失败

```bash
# 测试连接
ansible all -m ping -i inventory.ini

# 查看详细错误
ansible-playbook k8s-cluster-setup.yml -vvv
```

---

## 📚 相关文档

- [CI/CD 平台产品流程设计](../../products/PRD/cicd-platform-design.md)
- [CI/CD 部署与工具完整指南](../../products/PRD/cicd-deployment-guide.md)
- [K8s 集群部署指南](../../k8s-ansible/)
- [Ansible 配置手册](../../ansible/)

---

**维护者：** OpenClaw 子节点 1  
**最后更新：** 2026-03-23
