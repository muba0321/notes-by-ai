# K8s 集群部署指南

_使用 Ansible 部署 k3s 集群_

---

## 一、架构设计

```
                    公网 IP: 124.132.136.17
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   端口 9005          端口 9191         端口 9053/9010
        │                  │                  │
        ▼                  ▼                  ▼
   ┌─────────┐       ┌─────────┐       ┌─────────┐
   │ master1 │       │  node1  │       │  node2  │
   │ k3s     │       │  agent  │       │  agent  │
   │ server  │       │         │       │         │
   │192.168.x│       │192.168.x│       │192.168.x│
   └─────────┘       └─────────┘       └─────────┘
        ▲
        │
   ┌─────────┐
   │  node3  │
   │  agent  │
   │         │
   │192.168.x│
   └─────────┘
```

---

## 二、前置准备

### 1. Ansible 控制端（子节点 1）

```bash
# 安装 Ansible
apt update && apt install -y python3-pip
pip3 install ansible ansible-core

# 创建目录
mkdir -p /root/ansible/{inventory,playbooks}
```

### 2. 配置 Inventory

`/root/ansible/inventory/hosts.ini`:

```ini
[k8s_cluster:children]
masters
workers

[masters]
master1 ansible_host=124.132.136.17 ansible_port=9005

[workers]
node1 ansible_host=124.132.136.17 ansible_port=9191
node2 ansible_host=124.132.136.17 ansible_port=9053
node3 ansible_host=124.132.136.17 ansible_port=9010

[all:vars]
ansible_user=root
ansible_ssh_pass=Huanxin0321
ansible_python_interpreter=/usr/bin/python3
host_key_checking=False
```

### 3. 测试连接

```bash
ansible k8s_cluster -i /root/ansible/inventory/hosts.ini -m ping
```

---

## 三、部署步骤

### Step 1: 初始化所有节点

```bash
ansible-playbook -i inventory/hosts.ini playbooks/init.yml
```

**初始化内容：**
- 更新系统包
- 安装基础工具
- 关闭 swap
- 加载内核模块
- 设置内核参数
- 配置时区

---

### Step 2: 部署 k3s Server（master1）

```bash
ansible-playbook -i inventory/hosts.ini playbooks/k3s-deploy.yml \
  --tags server
```

**验证：**
```bash
# SSH 登录 master1
ssh -p 9005 root@124.132.136.17

# 检查服务
systemctl status k3s

# 查看节点
kubectl get nodes
```

---

### Step 3: 部署 k3s Agent（workers）

```bash
ansible-playbook -i inventory/hosts.ini playbooks/k3s-deploy.yml \
  --tags agent
```

**验证：**
```bash
# 在 master1 执行
kubectl get nodes

# 预期输出：
# NAME      STATUS   ROLES                  AGE   VERSION
# master1   Ready    control-plane,master   2m    v1.29.x
# node1     Ready    <none>                 1m    v1.29.x
# node2     Ready    <none>                 1m    v1.29.x
# node3     Ready    <none>                 1m    v1.29.x
```

---

## 四、安装 Dashboard（可选）

```yaml
# /root/ansible/playbooks/dashboard.yml
---
- name: 安装 K8s Dashboard
  hosts: master1
  tasks:
    - name: 部署 Dashboard
      command: kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

    - name: 创建管理员用户
      shell: |
        cat <<EOF | kubectl apply -f -
        apiVersion: v1
        kind: ServiceAccount
        metadata:
          name: admin-user
          namespace: kubernetes-dashboard
        ---
        apiVersion: rbac.authorization.k8s.io/v1
        kind: ClusterRoleBinding
        metadata:
          name: admin-user
        roleRef:
          apiGroup: rbac.authorization.k8s.io
          kind: ClusterRole
          name: cluster-admin
        subjects:
        - kind: ServiceAccount
          name: admin-user
          namespace: kubernetes-dashboard
        EOF

    - name: 获取访问 Token
      command: kubectl -n kubernetes-dashboard create token admin-user
      register: dashboard_token

    - name: 显示 Token
      debug:
        var: dashboard_token.stdout
```

---

## 五、常用运维命令

### 查看集群状态
```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl top nodes
kubectl top pods -A
```

### 部署应用
```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get svc nginx
```

### 访问 Dashboard
```bash
# 获取 Token
kubectl -n kubernetes-dashboard create token admin-user

# 本地代理
kubectl proxy

# 访问：http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

---

## 六、故障排除

### 节点 NotReady
```bash
# 查看节点详情
kubectl describe node <node-name>

# 检查 k3s 日志
journalctl -u k3s -f
```

### Pod 无法启动
```bash
# 查看 Pod 状态
kubectl get pods -A

# 查看 Pod 详情
kubectl describe pod <pod-name> -n <namespace>

# 查看 Pod 日志
kubectl logs <pod-name> -n <namespace>
```

### 网络问题
```bash
# 测试 Pod 间通信
kubectl run test --rm -it --image=busybox -- sh
# 在 Pod 内执行：ping <other-pod-ip>
```

---

## 七、备份与恢复

### 备份
```bash
# 备份 etcd 数据（k3s 使用 SQLite）
cp /var/lib/rancher/k3s/server/db/state.db /backup/state.db.$(date +%Y%m%d)

# 备份资源清单
kubectl get all -A -o yaml > /backup/all-resources.yaml
```

### 恢复
```bash
# 停止 k3s
systemctl stop k3s

# 恢复数据
cp /backup/state.db.YYYYMMDD /var/lib/rancher/k3s/server/db/state.db

# 启动 k3s
systemctl start k3s
```

---

**上一篇：** [常用 Playbook 示例](playbooks.md)
