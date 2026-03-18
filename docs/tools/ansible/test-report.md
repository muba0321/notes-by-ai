# Ansible 部署测试报告

_部署时间：2026-03-18_
_状态：进行中_

---

## 一、环境信息

### 控制端（子节点 1）

| 项目 | 值 |
|------|------|
| 主机名 | mubai-subagent1 |
| IP | 38.246.245.39 |
| Ansible 版本 | 10.7.0 |
| ansible-core | 2.17.14 |
| Python | 3.10.12 |
| SSH 客户端 | OpenSSH 8.9p1 |

### 被管机器（K8s 集群）

| 主机名 | 公网 IP:端口 | SSH 用户 | 用途 |
|--------|-------------|----------|------|
| master1 | 124.132.136.17:9005 | root | K8s Master |
| node1 | 124.132.136.17:9191 | root | K8s Worker 1 |
| node2 | 124.132.136.17:9053 | root | K8s Worker 2 |
| node3 | 124.132.136.17:9010 | root | K8s Worker 3 |

**远程 SSH 版本：** OpenSSH 7.4（2016 年老版本）

---

## 二、部署步骤

### 1. 安装 Ansible

```bash
# SSH 登录子节点 1
ssh root@38.246.245.39

# 安装依赖
apt update && apt install -y python3-pip sshpass

# 安装 Ansible
pip3 install ansible ansible-core

# 验证
ansible --version
```

**输出：**
```
ansible [core 2.17.14]
  python version = 3.10.12
  jinja version = 3.1.6
```

---

### 2. 创建目录结构

```bash
mkdir -p /root/ansible/{inventory,playbooks,scripts,docs}
```

---

### 3. 配置 Inventory

文件：`/root/ansible/inventory/hosts.ini`

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
ansible_ssh_common_args='-o KexAlgorithms=+diffie-hellman-group-exchange-sha256 -o HostKeyAlgorithms=+ssh-rsa,ssh-dss -o PubkeyAcceptedAlgorithms=+ssh-rsa'
```

---

### 4. 测试连接

```bash
ansible k8s_cluster -i /root/ansible/inventory/hosts.ini -m ping
```

---

## 三、遇到的问题

### 问题 1：SSH 连接被拒绝

**现象：**
```
master1 | UNREACHABLE! => {
    "changed": false,
    "msg": "Failed to connect to the host via ssh: Connection closed by 124.132.136.17 port 9005"
}
```

**排查：**
1. ✅ 端口连通性正常（telnet 可连接）
2. ✅ 能看到 SSH 横幅（SSH-2.0-OpenSSH_7.4）
3. ❌ SSH 握手阶段被服务器主动关闭

**SSH 调试日志：**
```
debug1: Remote protocol version 2.0, remote software version OpenSSH_7.4
debug1: kex: algorithm: curve25519-sha256
debug1: expecting SSH2_MSG_KEX_ECDH_REPLY
Connection closed by 124.132.136.17 port 9005
```

**原因分析：**
- 远程服务器使用 OpenSSH 7.4（2016 年版本）
- 控制端使用 OpenSSH 8.9p1（2022 年版本）
- 密钥交换阶段兼容性问题
- 笔记本（老 SSH 客户端）可以连接，子节点 1（新 SSH 客户端）无法连接

**解决方案：**

#### 方案 A：升级远程 SSH 服务器（推荐）
```bash
# 在远程机器上执行（需要先通过其他方式登录）
yum update openssh-server  # CentOS 7
# 或
apt update && apt install --reinstall openssh-server  # Ubuntu/Debian
```

#### 方案 B：配置 SSH 中转
通过一台中间机器转发连接。

#### 方案 C：使用内网 IP
如果子节点 1 和 K8s 集群在同一内网，尝试使用内网 IP 直连。

---

## 四、后续步骤

1. **解决 SSH 连接问题**（优先级：高）
2. **测试 Ansible 连接**
3. **执行基础环境初始化 Playbook**
4. **部署 k3s 集群**
5. **验证集群状态**

---

## 五、参考文档

- [Ansible 安装配置](ansible-setup.md)
- [主机清单配置](inventory.md)
- [Playbook 示例](playbooks.md)
- [K8s 部署指南](k8s-deploy.md)

---

**最后更新：** 2026-03-18 08:15 UTC
**状态：** SSH 连接问题排查中
