# NetBox CMDB 配置记录

## 部署信息

- **位置：** 子节点 1 (38.246.245.39)
- **路径：** `/data/netbox/`
- **版本：** NetBox v4.0.2
- **访问：** http://cmdb.mubai.top
- **账号：** admin / NetBox@****

---

## 虚拟机清单

### Infrastructure (基础设施)

| 名称 | 外部 IP | 内部 IP | vCPUs | 内存 | 硬盘 | 描述 |
|------|---------|---------|-------|------|------|------|
| ser280729144889 | 222.211.80.222 | - | 4 | 3800 MB | 30 GB | 国内堡垒机 |
| ser493590849885 | - | 10.0.118.4 | 2 | 2048 MB | 20 GB | OpenClaw 主节点 |
| mubai-subagent1 | 38.246.245.39 | - | 4 | 8192 MB | 80 GB | OpenClaw 子节点 1 |
| master1 | 124.132.136.17 | 172.16.0.42 | 4 | 8192 MB | 100 GB | K8s Master |
| node1 | 124.132.136.17 | 172.16.0.98 | 8 | 16384 MB | 200 GB | K8s Worker 1 |
| node2 | 124.132.136.17 | 172.16.0.40 | 8 | 16384 MB | 200 GB | K8s Worker 2 |
| node3 | 124.132.136.17 | - | 8 | 16384 MB | 200 GB | K8s Worker 3 |

### Application (应用服务)

| 名称 | 外部 IP | 内部 IP | 访问 URL | vCPUs | 内存 | 硬盘 |
|------|---------|---------|----------|-------|------|------|
| netbox-cmdb | cmdb.mubai.top | 127.0.0.1:8082 | http://cmdb.mubai.top | 2 | 4096 MB | 20 GB |
| jenkins-ci | jenkins.mubai.top | 222.211.80.222:8080 | http://jenkins.mubai.top | 4 | 8192 MB | 100 GB |
| prometheus | promethus.mubai.top | 222.211.80.222:9090 | http://promethus.mubai.top | 2 | 4096 MB | 50 GB |
| grafana | grafana.mubai.top | 222.211.80.222:3000 | http://grafana.mubai.top | 2 | 2048 MB | 10 GB |
| openclaw-gateway | 38.246.245.39:18789 | 127.0.0.1:18789 | http://38.246.245.39:18789 | 1 | 512 MB | 5 GB |

---

## 自定义字段

| 字段名 | 标签 | 类型 | 说明 |
|--------|------|------|------|
| ext_ip | 外部 IP | text | 公网 IP 或域名 |
| int_ip | 内部 IP | text | 内网 IP: 端口 |
| site_url | 访问 URL | text | 完整访问地址 |
| disk_gb | 硬盘 | integer | 磁盘大小 (GB) |
| ssh_username | SSH 用户名 | text | Infrastructure 专用 |
| ssh_password | SSH 密码 | text | Infrastructure 专用 |
| ssh_port | SSH 端口 | integer | Infrastructure 专用 |
| service_owner | 负责人 | text | 通用 |
| admin_username | 管理员用户名 | text | Application 专用 |
| admin_password | 管理员密码 | text | Application 专用 |

---

## 标签

- **Infrastructure** - 基础设施服务器 (蓝色 #0072c6)
- **Application** - 应用服务 (绿色 #4caf50)

---

## 快速访问

- 全部虚拟机：http://cmdb.mubai.top/virtualization/virtual-machines/
- 基础设施：http://cmdb.mubai.top/virtualization/virtual-machines/?tag=infrastructure
- 应用服务：http://cmdb.mubai.top/virtualization/virtual-machines/?tag=application

---

**更新时间：** 2026-03-25
