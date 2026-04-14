# CI/CD 服务目录

**位置：** `/data/openclaw-dist/CI-CD/`  
**用途：** 存储 Jenkins、监控、部署相关的配置和文档

---

## 📁 目录结构

```
CI-CD/
├── README.md                              # 本文件
├── 服务迁移方案 - 堡垒机到子节点 1.md        # 完整迁移文档
├── scripts/                               # 运维脚本
│   ├── check-tunnel.sh                    # 隧道状态检查
│   ├── backup-services.sh                 # 服务备份脚本
│   └── restore-services.sh                # 服务恢复脚本
└── configs/                               # 配置文件备份
    ├── docker-compose.yml                 # Docker Compose 配置
    ├── prometheus.yml                     # Prometheus 配置
    └── ssh-tunnel.service                 # SSH 隧道 systemd 配置
```

---

## 🔧 快速命令

### 服务状态检查

```bash
# 堡垒机 - 检查所有服务
cd /data/monitoring
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# 子节点 1 - 检查隧道
systemctl status ssh-tunnel --no-pager

# 子节点 1 - 检查 Nginx
systemctl status nginx --no-pager
```

### 隧道管理

```bash
# 重启隧道
systemctl restart ssh-tunnel

# 查看隧道日志
journalctl -u ssh-tunnel -f --no-pager

# 测试隧道连接
curl -I http://127.0.0.1:18080/login
```

### 服务访问

| 服务 | 访问地址 | 说明 |
|------|----------|------|
| Jenkins | http://jenkins.mubai.top | CI/CD 自动化 |
| Prometheus | http://promethus.mubai.top | 监控指标 |
| Grafana | http://grafana.mubai.top | 可视化 Dashboard |

---

## 📋 相关文档

- **完整迁移文档：** `服务迁移方案 - 堡垒机到子节点 1.md`
- **OpenClaw 配置：** `../OpenClaw/`
- **监控配置：** `../Monitoring/`

---

**最后更新：** 2026-03-24
