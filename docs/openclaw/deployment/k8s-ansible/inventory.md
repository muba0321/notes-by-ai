# 主机清单配置 (Inventory)

_Ansible 主机清单编写指南_

---

## 一、Inventory 文件格式

### INI 格式（推荐）

```ini
# 单机组
[masters]
master1 ansible_host=124.132.136.17 ansible_port=9005

# 多机组
[workers]
node1 ansible_host=124.132.136.17 ansible_port=9191
node2 ansible_host=124.132.136.17 ansible_port=9053
node3 ansible_host=124.132.136.17 ansible_port=9010

# 组合组
[k8s_cluster:children]
masters
workers

# 全局变量
[all:vars]
ansible_user=root
ansible_ssh_pass=Huanxin0321
ansible_python_interpreter=/usr/bin/python3
host_key_checking=False
```

### YAML 格式

```yaml
all:
  children:
    masters:
      hosts:
        master1:
          ansible_host: 124.132.136.17
          ansible_port: 9005
    workers:
      hosts:
        node1:
          ansible_host: 124.132.136.17
          ansible_port: 9191
        node2:
          ansible_host: 124.132.136.17
          ansible_port: 9053
        node3:
          ansible_host: 124.132.136.17
          ansible_port: 9010
  vars:
    ansible_user: root
    ansible_ssh_pass: Huanxin0321
```

---

## 二、常用变量

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `ansible_host` | 目标主机 IP | 124.132.136.17 |
| `ansible_port` | SSH 端口 | 9005 |
| `ansible_user` | SSH 用户 | root |
| `ansible_ssh_pass` | SSH 密码 | Huanxin0321 |
| `ansible_python_interpreter` | Python 路径 | /usr/bin/python3 |
| `host_key_checking` | 跳过主机密钥检查 | False |
| `ansible_become` | 是否提权 | yes |
| `ansible_become_pass` | 提权密码 | password |

---

## 三、多 Inventory 管理

```bash
/root/ansible/inventory/
├── hosts.ini          # 主清单
├── production.ini     # 生产环境
├── development.ini    # 开发环境
└── group_vars/        # 组变量
    ├── all.yml
    ├── masters.yml
    └── workers.yml
```

### group_vars 示例

`/root/ansible/inventory/group_vars/all.yml`:
```yaml
---
# 所有节点通用配置
timezone: Asia/Shanghai
ntp_server: ntp.aliyun.com
dns_servers:
  - 8.8.8.8
  - 1.1.1.1
```

`/root/ansible/inventory/group_vars/masters.yml`:
```yaml
---
# Master 节点专用配置
k3s_role: server
k3s_cluster_init: true
```

---

## 四、动态 Inventory（进阶）

用于云环境或动态主机：

```bash
# 使用脚本生成 inventory
ansible-inventory -i ./dynamic_inventory.py --list
```

---

## 五、最佳实践

1. **密码安全：** 使用 `ansible-vault` 加密敏感信息
   ```bash
   ansible-vault encrypt inventory/hosts.ini
   ansible-playbook -i inventory/hosts.ini playbook.yml --ask-vault-pass
   ```

2. **SSH 密钥：** 优先使用密钥而非密码

3. **版本控制：** Inventory 文件纳入 Git 管理（敏感信息除外）

4. **文档化：** 在 inventory 文件顶部添加注释说明

---

**上一篇：** [Ansible 安装配置](ansible-setup.md)  
**下一篇：** [常用 Playbook 示例](playbooks.md)
