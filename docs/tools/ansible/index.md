# Ansible 自动化工具

_Ansible 配置管理工具集_

---

## 📁 文档导航

| 文档 | 说明 |
|------|------|
| [安装配置](ansible-setup.md) | Ansible 安装与基础配置 |
| [主机清单](inventory.md) | Inventory 编写指南 |
| [Playbook 示例](playbooks.md) | 常用 Playbook 模板 |
| [K8s 部署](k8s-deploy.md) | k3s 集群部署指南 |
| [测试报告](test-report.md) | 部署测试与问题记录 |

---

## 🚀 快速开始

### 1. 登录控制端

```bash
ssh root@38.246.245.39
```

### 2. 测试连接

```bash
ansible k8s_cluster -i /root/ansible/inventory/hosts.ini -m ping
```

### 3. 执行 Playbook

```bash
# 基础环境初始化
ansible-playbook -i /root/ansible/inventory/hosts.ini /root/ansible/playbooks/init.yml

# 部署 k3s
ansible-playbook -i /root/ansible/inventory/hosts.ini /root/ansible/playbooks/k3s-deploy.yml
```

---

## 📂 目录结构

```
/root/ansible/
├── inventory/
│   └── hosts.ini          # 主机清单
├── playbooks/
│   ├── init.yml           # 环境初始化
│   ├── k3s-deploy.yml     # k3s 部署
│   └── verify.yml         # 集群验证
├── scripts/               # 辅助脚本
└── docs/                  # 本地文档
```

---

## 🔧 被管机器

| 主机名 | IP:端口 | 用途 |
|--------|---------|------|
| master1 | 124.132.136.17:9005 | K8s Master |
| node1 | 124.132.136.17:9191 | K8s Worker 1 |
| node2 | 124.132.136.17:9053 | K8s Worker 2 |
| node3 | 124.132.136.17:9010 | K8s Worker 3 |

---

## ⚠️ 注意事项

1. **SSH 兼容性：** 远程机器使用 OpenSSH 7.4，可能需要特殊配置
2. **密码认证：** 当前使用密码认证，建议改为 SSH 密钥
3. **端口映射：** 所有机器通过端口映射访问，确保路由器配置正确

---

**上一篇：** [工具首页](../index.md)
