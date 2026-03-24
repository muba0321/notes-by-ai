# CI/CD 平台部署与工具完整指南

_Jenkins + GitHub + Ansible + K8s 完整部署方案、工具依赖与安装脚本_

**创建日期：** 2026-03-23  
**最后更新：** 2026-03-23  
**作者：** OpenClaw 子节点 1  
**状态：** approved  
**版本：** 1.0  
**关联文档：** [cicd-platform-design.md](./cicd-platform-design.md)

---

## 📦 工具清单与版本

### 核心组件

| 工具 | 推荐版本 | 用途 | 部署位置 | 必须性 |
|------|---------|------|---------|--------|
| **Jenkins** | 2.400+ LTS | CI/CD 编排 | 子节点 1 | 🔴 必须 |
| **Docker** | 24.0+ | 容器构建 | 子节点 1 + K8s 节点 | 🔴 必须 |
| **Ansible** | 2.14+ | 自动化部署 | 子节点 1 | 🔴 必须 |
| **Kubernetes** | 1.26+ | 容器编排 | 4 台机器集群 | 🔴 必须 |
| **Git** | 2.35+ | 版本控制 | 全部节点 | 🔴 必须 |

### 可选工具

| 工具 | 版本 | 用途 | 部署位置 | 必须性 |
|------|------|------|---------|--------|
| **Harbor** | 2.8+ | 私有镜像仓库 | 子节点 1 或独立 | 🟡 推荐 |
| **SonarQube** | 10.0+ | 代码质量检查 | 子节点 1 | 🟡 推荐 |
| **Nexus** | 3.60+ | 制品仓库 | 子节点 1 | 🟡 可选 |
| **Prometheus** | 2.40+ | 监控指标 | K8s 集群 | 🟡 推荐 |
| **Grafana** | 10.0+ | 监控可视化 | K8s 集群 | 🟡 推荐 |
| **ELK Stack** | 8.x | 日志收集 | K8s 集群 | 🟡 可选 |
| **ArgoCD** | 2.8+ | GitOps 部署 | K8s 集群 | 🟡 可选 |

---

## 🏗️ 部署架构

### 拓扑图

```
┌────────────────────────────────────────────────────────────────────┐
│                         子节点 1 (38.246.245.39)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │   Jenkins    │  │    Docker    │  │   Ansible    │            │
│  │   (8080)     │  │    (2375)    │  │   (本地)     │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│  ┌──────────────┐  ┌──────────────┐                              │
│  │   Harbor     │  │  SonarQube   │                              │
│  │   (8082)     │  │   (9000)     │                              │
│  └──────────────┘  └──────────────┘                              │
└────────────────────────────────────────────────────────────────────┘
                            │ SSH/API
                            ↓
┌────────────────────────────────────────────────────────────────────┐
│                      K8s 集群 (4 台机器)                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │   master1    │  │    node1     │  │    node2     │            │
│  │ 124.132.136.17:9005 │ 124.132.136.17:9191 │ 124.132.136.17:9053 │
│  │   Control    │  │    Worker    │  │    Worker    │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│  ┌──────────────┐                                                  │
│  │    node3     │                                                  │
│  │ 124.132.136.17:9010 │                                          │
│  │    Worker    │                                                  │
│  └──────────────┘                                                  │
└────────────────────────────────────────────────────────────────────┘
```

### 端口规划

| 服务 | 端口 | 协议 | 说明 |
|------|------|------|------|
| Jenkins | 8080 | HTTP | Web UI |
| Jenkins Agent | 50000 | TCP | 节点通信 |
| Docker Registry | 5000 | HTTPS | 镜像推送 |
| Harbor | 8082 | HTTP/HTTPS | 镜像仓库 UI |
| SonarQube | 9000 | HTTP | 代码质量 |
| K8s API | 6443 | HTTPS | 集群管理 |
| K8s etcd | 2379-2380 | TCP | 集群存储 |
| NodePort | 30000-32767 | TCP | 服务暴露 |

---

## 📋 部署方案

### 方案 A：Docker Compose 部署（推荐）

**适用场景：** 快速部署，测试环境，小规模生产

**优点：**
- ✅ 部署简单，一条命令
- ✅ 易于备份和迁移
- ✅ 资源隔离好
- ✅ 升级方便

**缺点：**
- ⚠️ 单点故障
- ⚠️ 扩展性有限

---

### 方案 B：K8s 部署（生产推荐）

**适用场景：** 生产环境，高可用需求

**优点：**
- ✅ 高可用，自动故障恢复
- ✅ 水平扩展
- ✅ 资源调度优化
- ✅ 自愈能力

**缺点：**
- ⚠️ 部署复杂
- ⚠️ 需要 K8s 知识
- ⚠️ 资源开销大

---

### 方案 C：混合部署

**适用场景：** 过渡阶段，部分服务容器化

```
Jenkins (Docker) + Ansible (本地) + K8s (集群)
```

---

## 🛠️ 安装脚本

### 1. 子节点 1 基础环境准备

```bash
#!/bin/bash
# install-base-tools.sh
# 用途：安装 Docker、Ansible、Git 等基础工具

set -e

echo "=== 安装基础工具 ==="

# 更新系统
apt update && apt upgrade -y

# 安装 Docker
echo "安装 Docker..."
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# 安装 Ansible
echo "安装 Ansible..."
apt install -y software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt install -y ansible

# 安装 Git
echo "安装 Git..."
apt install -y git

# 安装 kubectl
echo "安装 kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# 安装 Helm
echo "安装 Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 验证安装
echo "=== 验证安装 ==="
docker --version
ansible --version
git --version
kubectl version --client
helm version

echo "=== 基础工具安装完成 ==="
```

---

### 2. Jenkins 部署脚本（Docker）

```bash
#!/bin/bash
# install-jenkins.sh
# 用途：使用 Docker 部署 Jenkins

set -e

JENKINS_VERSION="2.400-lts"
JENKINS_HOME="/data/jenkins"

echo "=== 部署 Jenkins ==="

# 创建数据目录
mkdir -p $JENKINS_HOME

# 设置权限
chown -R 1000:1000 $JENKINS_HOME

# 拉取镜像
docker pull jenkins/jenkins:$JENKINS_VERSION

# 启动容器
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v $JENKINS_HOME:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/bin/docker:/usr/bin/docker \
  -e JAVA_OPTS="-Xmx2048m" \
  jenkins/jenkins:$JENKINS_VERSION

# 等待 Jenkins 启动
echo "等待 Jenkins 启动..."
sleep 30

# 获取初始管理员密码
echo "=== Jenkins 初始管理员密码 ==="
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

echo "=== Jenkins 部署完成 ==="
echo "访问地址：http://<子节点 1-IP>:8080"
echo "请完成初始化配置并安装推荐插件"
```

---

### 3. Harbor 部署脚本（Docker Compose）

```bash
#!/bin/bash
# install-harbor.sh
# 用途：部署 Harbor 私有镜像仓库

set -e

HARBOR_VERSION="2.8.0"
HARBOR_HOME="/data/harbor"

echo "=== 部署 Harbor ==="

# 下载安装包
cd /tmp
wget https://github.com/goharbor/harbor/releases/download/v$HARBOR_VERSION/harbor-offline-installer-v$HARBOR_VERSION.tgz
tar xvf harbor-offline-installer-v$HARBOR_VERSION.tgz
mv harbor $HARBOR_HOME
cd $HARBOR_HOME

# 配置文件
cat > harbor.yml <<EOF
hostname: <子节点 1-IP>
http:
  port: 8082
database:
  password: harbor12345
harbor_admin_password: Harbor12345
data_volume: $HARBOR_HOME/data
EOF

# 安装
./install.sh --with-trivy --with-chartmuseum

echo "=== Harbor 部署完成 ==="
echo "访问地址：http://<子节点 1-IP>:8082"
echo "管理员账号：admin / Harbor12345"
```

---

### 4. SonarQube 部署脚本（Docker）

```bash
#!/bin/bash
# install-sonarqube.sh
# 用途：部署 SonarQube 代码质量平台

set -e

SONAR_VERSION="10.0"
SONAR_HOME="/data/sonarqube"

echo "=== 部署 SonarQube ==="

# 创建数据目录
mkdir -p $SONAR_HOME/{data,logs,extensions}

# 拉取镜像
docker pull sonarqube:$SONAR_VERSION

# 启动容器
docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  -v $SONAR_HOME/data:/opt/sonarqube/data \
  -v $SONAR_HOME/logs:/opt/sonarqube/logs \
  -v $SONAR_HOME/extensions:/opt/sonarqube/extensions \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:$SONAR_VERSION

# 等待启动
echo "等待 SonarQube 启动..."
sleep 60

echo "=== SonarQube 部署完成 ==="
echo "访问地址：http://<子节点 1-IP>:9000"
echo "默认账号：admin / admin"
```

---

### 5. K8s 集群配置脚本（Ansible）

```yaml
# k8s-cluster-setup.yml
---
- name: Configure Kubernetes Cluster
  hosts: k8s_cluster
  become: yes
  vars:
    k8s_version: "1.26.0"
    
  tasks:
    - name: Install required packages
      apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - gnupg
          - lsb-release
        state: present
        update_cache: yes
    
    - name: Add Kubernetes GPG key
      apt_key:
        url: https://packages.cloud.google.com/apt/doc/apt-key.gpg
        state: present
    
    - name: Add Kubernetes repository
      apt_repository:
        repo: "deb https://apt.kubernetes.io/ kubernetes-xenial main"
        state: present
    
    - name: Install Kubernetes components
      apt:
        name:
          - kubelet={{ k8s_version }}-00
          - kubeadm={{ k8s_version }}-00
          - kubectl={{ k8s_version }}-00
        state: present
        update_cache: yes
    
    - name: Hold Kubernetes packages
      dpkg_selections:
        name: "{{ item }}"
        selection: hold
      loop:
        - kubelet
        - kubeadm
        - kubectl
    
    - name: Enable kubelet service
      systemd:
        name: kubelet
        enabled: yes
        state: started
    
    - name: Configure container runtime
      copy:
        dest: /etc/modules-load.d/containerd.conf
        content: |
          overlay
          br_netfilter
    
    - name: Load kernel modules
      modprobe:
        name: "{{ item }}"
        state: present
      loop:
        - overlay
        - br_netfilter
    
    - name: Configure sysctl for Kubernetes
      sysctl:
        name: "{{ item.name }}"
        value: "{{ item.value }}"
        sysctl_set: yes
        state: present
        reload: yes
      loop:
        - { name: 'net.bridge.bridge-nf-call-iptables', value: '1' }
        - { name: 'net.bridge.bridge-nf-call-ip6tables', value: '1' }
        - { name: 'net.ipv4.ip_forward', value: '1' }
```

---

### 6. Jenkins 凭证配置脚本（Ansible）

```yaml
# jenkins-credentials-setup.yml
---
- name: Configure Jenkins Credentials
  hosts: jenkins_server
  vars:
    jenkins_url: "http://localhost:8080"
    jenkins_user: "admin"
    jenkins_token: "<API_TOKEN>"
    
  tasks:
    - name: Add GitHub credentials
      uri:
        url: "{{ jenkins_url }}/credentials/store/system/domain/_/createCredentials"
        method: POST
        user: "{{ jenkins_user }}"
        password: "{{ jenkins_token }}"
        body_format: form-urlencoded
        body:
          credentials: |
            <com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
              <scope>GLOBAL</scope>
              <id>github-credentials</id>
              <description>GitHub Account</description>
              <username>your-github-username</username>
              <password>your-github-token</password>
            </com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
        headers:
          Content-Type: "application/x-www-form-urlencoded"
        status_code: [200, 201, 302]
    
    - name: Add K8s credentials
      uri:
        url: "{{ jenkins_url }}/credentials/store/system/domain/_/createCredentials"
        method: POST
        user: "{{ jenkins_user }}"
        password: "{{ jenkins_token }}"
        body_format: form-urlencoded
        body:
          credentials: |
            <org.jenkinsci.plugins.kubernetes.credentials.FileCredential>
              <scope>GLOBAL</scope>
              <id>k8s-kubeconfig</id>
              <description>Kubernetes Config</description>
              <fileName>kubeconfig</fileName>
              <secretText>{{ lookup('file', '~/.kube/config') }}</secretText>
            </org.jenkinsci.plugins.kubernetes.credentials.FileCredential>
        headers:
          Content-Type: "application/x-www-form-urlencoded"
        status_code: [200, 201, 302]
```

---

## 🧪 测试与验证

### 1. 基础环境验证

```bash
#!/bin/bash
# verify-environment.sh
# 用途：验证所有组件安装成功

echo "=== 验证基础环境 ==="

# Docker
echo "检查 Docker..."
docker --version && docker ps

# Ansible
echo "检查 Ansible..."
ansible --version

# Git
echo "检查 Git..."
git --version

# kubectl
echo "检查 kubectl..."
kubectl version --client

# Helm
echo "检查 Helm..."
helm version

echo "=== 验证 Jenkins ==="
curl -I http://localhost:8080/login

echo "=== 验证 Harbor ==="
curl -I http://localhost:8082

echo "=== 验证 SonarQube ==="
curl -I http://localhost:9000

echo "=== 验证 K8s 集群 ==="
kubectl get nodes
kubectl get pods --all-namespaces

echo "=== 所有验证完成 ==="
```

---

### 2. CI/CD 流程测试

```bash
#!/bin/bash
# test-cicd-pipeline.sh
# 用途：测试完整 CI/CD 流程

set -e

echo "=== CI/CD 流程测试 ==="

# 1. 创建测试仓库
echo "创建测试仓库..."
cd /tmp
git clone https://github.com/your-org/test-app.git
cd test-app

# 2. 推送测试代码
echo "推送测试代码..."
echo "# Test App" > README.md
git add .
git commit -m "Test commit for CI/CD"
git push origin main

# 3. 等待 Jenkins 构建
echo "等待 Jenkins 构建 (60 秒)..."
sleep 60

# 4. 检查构建状态
echo "检查构建状态..."
curl -u admin:TOKEN http://localhost:8080/job/test-app/lastBuild/api/json | jq '.result'

# 5. 检查镜像是否生成
echo "检查镜像..."
docker images | grep test-app

# 6. 检查部署状态
echo "检查 K8s 部署..."
kubectl get deployments
kubectl get pods

# 7. 验证服务可访问
echo "验证服务..."
SERVICE_IP=$(kubectl get svc test-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -I http://$SERVICE_IP

echo "=== CI/CD 流程测试完成 ==="
```

---

### 3. 回滚测试

```bash
#!/bin/bash
# test-rollback.sh
# 用途：测试回滚功能

set -e

echo "=== 回滚测试 ==="

# 1. 记录当前版本
CURRENT_VERSION=$(kubectl get deployment test-app -o jsonpath='{.spec.template.spec.containers[0].image}')
echo "当前版本：$CURRENT_VERSION"

# 2. 执行回滚
echo "执行回滚..."
kubectl rollout undo deployment/test-app

# 3. 等待回滚完成
echo "等待回滚完成..."
kubectl rollout status deployment/test-app

# 4. 验证回滚版本
NEW_VERSION=$(kubectl get deployment test-app -o jsonpath='{.spec.template.spec.containers[0].image}')
echo "回滚后版本：$NEW_VERSION"

# 5. 验证服务正常
echo "验证服务..."
kubectl get pods
kubectl get svc

echo "=== 回滚测试完成 ==="
```

---

### 4. 压力测试

```bash
#!/bin/bash
# stress-test.sh
# 用途：压力测试 CI/CD 平台

echo "=== 压力测试 ==="

# 并发构建测试
echo "并发构建测试 (10 个并发)..."
for i in {1..10}; do
  curl -X POST http://localhost:8080/job/test-app/build?token=BUILD_TOKEN &
done
wait

# 等待构建完成
echo "等待构建完成..."
sleep 300

# 检查构建结果
echo "检查构建结果..."
curl -u admin:TOKEN http://localhost:8080/job/test-app/api/json | jq '.builds[0:10] | .[].result'

# 资源使用检查
echo "资源使用情况..."
kubectl top nodes
kubectl top pods

echo "=== 压力测试完成 ==="
```

---

## 📊 监控配置

### Prometheus 配置

```yaml
# prometheus-cicd.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'jenkins'
    static_configs:
      - targets: ['jenkins:8080']
    metrics_path: '/prometheus'
  
  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
  
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
  
  - job_name: 'harbor'
    static_configs:
      - targets: ['harbor:8082']
```

### Grafana 看板

导入以下 Dashboard ID：
- **Jenkins:** 9964
- **Kubernetes:** 6417
- **Harbor:** 12096
- **SonarQube:** 9575

---

## 🔧 故障排除

### 常见问题与解决方案

| 问题 | 症状 | 解决方案 |
|------|------|---------|
| Jenkins 无法连接 Docker | `permission denied` | 将 jenkins 用户加入 docker 组 |
| K8s Pod 无法启动 | `ImagePullBackOff` | 检查镜像仓库凭证 |
| Ansible 连接失败 | `UNREACHABLE` | 检查 SSH 密钥和防火墙 |
| Harbor 推送失败 | `denied: requested access` | 检查登录凭证和权限 |
| SonarQube 扫描失败 | `401 Unauthorized` | 检查 Token 配置 |

### 日志查看命令

```bash
# Jenkins 日志
docker logs jenkins

# Harbor 日志
docker logs harbor-core

# K8s Pod 日志
kubectl logs <pod-name> -n <namespace>

# Ansible 调试
ansible-playbook playbook.yml -vvv
```

---

## 📝 维护手册

### 日常维护

| 任务 | 频率 | 命令 |
|------|------|------|
| Jenkins 备份 | 每天 | `tar czf jenkins-backup.tar.gz /data/jenkins` |
| 日志清理 | 每周 | `docker system prune -af` |
| 镜像清理 | 每周 | `docker image prune -af --filter "until=168h"` |
| K8s 资源清理 | 每周 | `kubectl delete pods --field-selector=status.phase==Failed` |
| 系统更新 | 每月 | `apt update && apt upgrade -y` |

### 备份策略

```bash
#!/bin/bash
# backup-cicd.sh
# 用途：备份 CI/CD 平台数据

BACKUP_DIR="/data/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# 备份 Jenkins
docker exec jenkins tar czf - /var/jenkins_home > $BACKUP_DIR/jenkins_$DATE.tar.gz

# 备份 Harbor
docker exec harbor-core tar czf - /harbor_data > $BACKUP_DIR/harbor_$DATE.tar.gz

# 备份 K8s 配置
kubectl get all --all-namespaces -o yaml > $BACKUP_DIR/k8s_$DATE.yaml

# 备份 Ansible Inventory
cp /etc/ansible/hosts $BACKUP_DIR/ansible_hosts_$DATE

# 删除 30 天前的备份
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "备份完成：$BACKUP_DIR"
```

---

## 📚 参考资源

### 官方文档

- [Jenkins](https://www.jenkins.io/doc/)
- [Docker](https://docs.docker.com/)
- [Ansible](https://docs.ansible.com/)
- [Kubernetes](https://kubernetes.io/docs/)
- [Harbor](https://goharbor.io/docs/)
- [SonarQube](https://docs.sonarqube.org/)

### 社区资源

- [Jenkins Pipeline 示例库](https://github.com/jenkinsci/pipeline-examples)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Helm Charts](https://artifacthub.io/)
- [Kubernetes 示例](https://github.com/kubernetes/examples)

---

## 📝 变更记录

| 版本 | 日期 | 作者 | 变更内容 |
|------|------|------|---------|
| 1.0 | 2026-03-23 | OpenClaw 子节点 1 | 初始版本 |

---

**审批：**

- [ ] 产品负责人
- [ ] 技术负责人
- [ ] 运维负责人
