# Ansible 安装配置手册

_在子节点 1 上部署 Ansible 控制端_

---

## 一、环境要求

- **控制端：** 子节点 1 (38.246.245.39)
- **Python：** 3.8+
- **网络：** 能 SSH 访问所有被管节点

---

## 二、安装 Ansible

```bash
# SSH 登录子节点 1
ssh root@38.246.245.39

# 安装 Python pip（如果没有）
apt update && apt install -y python3-pip

# 安装 Ansible
pip3 install ansible ansible-core

# 验证安装
ansible --version
```

---

## 三、目录结构

```bash
mkdir -p /root/ansible/{inventory,playbooks,roles,scripts}
```

| 目录 | 用途 |
|------|------|
| `inventory/` | 主机清单 |
| `playbooks/` | 部署脚本 |
| `roles/` | 可复用角色 |
| `scripts/` | 辅助脚本 |

---

## 四、配置 Inventory

创建 `/root/ansible/inventory/hosts.ini`：

```ini
[k8s_cluster:children]
masters
workers

[masters]
master1 ansible_host=124.132.136.17 ansible_port=9005 ansible_user=root ansible_ssh_pass=Huanxin0321

[workers]
node1 ansible_host=124.132.136.17 ansible_port=9191 ansible_user=root ansible_ssh_pass=Huanxin0321
node2 ansible_host=124.132.136.17 ansible_port=9053 ansible_user=root ansible_ssh_pass=Huanxin0321
node3 ansible_host=124.132.136.17 ansible_port=9010 ansible_user=root ansible_ssh_pass=Huanxin0321

[all:vars]
ansible_python_interpreter=/usr/bin/python3
host_key_checking=False
```

---

## 五、配置 SSH 密钥（可选但推荐）

```bash
# 生成密钥
ssh-keygen -t ed25519 -f ~/.ssh/ansible_key -N ''

# 分发到所有节点
for port in 9005 9191 9053 9010; do
  sshpass -p 'Huanxin0321' ssh-copy-id -o StrictHostKeyChecking=no \
    -p $port root@124.132.136.17
done
```

---

## 六、测试连接

```bash
# 测试所有节点
ansible k8s_cluster -i /root/ansible/inventory/hosts.ini -m ping

# 预期输出：
# master1 | SUCCESS => {...}
# node1   | SUCCESS => {...}
# node2   | SUCCESS => {...}
# node3   | SUCCESS => {...}
```

---

## 七、常用命令

```bash
# 查看主机列表
ansible all -i inventory/hosts.ini --list-hosts

# 执行临时命令
ansible k8s_cluster -i inventory/hosts.ini -a 'uptime'

# 拷贝文件
ansible master1 -i inventory/hosts.ini -m copy \
  -a 'src=/local/file dest=/remote/file'

# 清理临时文件
ansible k8s_cluster -i inventory/hosts.ini -m file \
  -a 'path=/tmp/test state=absent'
```

---

## 八、故障排除

### SSH 连接失败
```bash
# 详细日志
ansible master1 -i inventory/hosts.ini -m ping -vvv
```

### 端口不通
```bash
# 测试端口
nc -zv 124.132.136.17 9005
```

### Python 版本问题
```bash
# 指定 Python 解释器
ansible all -i inventory/hosts.ini -m ping \
  -e 'ansible_python_interpreter=/usr/bin/python3'
```

---

**下一篇：** [主机清单配置](inventory.md)
