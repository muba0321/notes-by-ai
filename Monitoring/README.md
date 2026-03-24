# 监控平台文档

_Prometheus + Grafana + Node Exporter 完整监控方案_

---

## 📁 目录结构

```
Monitoring/
├── README.md                    # 本文件
├── Prometheus/                  # Prometheus 相关文档
│   ├── prometheus-grafana-deployment.md    # 部署记录
│   ├── cicd-monitoring-metrics.md          # CI/CD 监控指标
│   └── linux-monitoring-metrics-full.md    # Linux 系统完整指标 (125+)
└── Grafana/                     # Grafana 相关文档
    ├── grafana-dingtalk-alert-setup.md     # 钉钉告警配置
    └── nginx-proxy-config.md               # Nginx 反向代理
```

---

## 📄 文档说明

### Prometheus

| 文件 | 大小 | 说明 |
|------|------|------|
| **prometheus-grafana-deployment.md** | 5.1 KB | Prometheus+Grafana 部署记录 |
| **cicd-monitoring-metrics.md** | 13 KB | CI/CD 平台监控指标（Jenkins 等） |
| **linux-monitoring-metrics-full.md** | 18 KB | Linux 系统完整监控指标（125+ 指标） |

### Grafana

| 文件 | 大小 | 说明 |
|------|------|------|
| **grafana-dingtalk-alert-setup.md** | 4.3 KB | 钉钉告警配置指南 |
| **nginx-proxy-config.md** | 5.6 KB | Nginx 反向代理配置 |

---

## 🎯 监控目标

| 目标 | 地址 | 端口 | 说明 |
|------|------|------|------|
| **Prometheus** | localhost | 9090 | 自监控 |
| **Grafana** | localhost | 3000 | 可视化平台 |
| **Jenkins** | jenkins:8080 | 8080 | CI/CD 指标 |
| **Node Exporter (子节点 1)** | localhost | 9100 | 子节点系统监控 |
| **Node Exporter (主节点)** | 10.0.118.4 | 9100 | 主节点系统监控 |

---

## 🚀 访问地址

| 服务 | HTTP 地址 | 说明 |
|------|---------|------|
| **Grafana** | http://grafana.mubai.top | 可视化看板 (admin/Grafana12345) |
| **Prometheus** | http://promethus.mubai.top | 指标查询 |
| **Grafana (IP)** | http://38.246.245.39:3000 | 直接访问 |
| **Prometheus (IP)** | http://38.246.245.39:9090 | 直接访问 |

---

## 📊 Grafana Dashboard

### 已导入面板

| Dashboard | UID | 说明 |
|-----------|-----|------|
| **Linux 系统监控** | linux-system-monitor | 自定义系统监控（8 个面板） |

### 推荐导入

| Dashboard | ID | 用途 |
|-----------|----|------|
| **Node Exporter Full** | 1860 | 完整系统监控 |
| **Jenkins Overview** | 9964 | Jenkins 监控 |
| **Prometheus Stats** | 2 | Prometheus 自身监控 |

### Linux 系统监控面板

自定义面板包含 8 个监控视图：

1. **系统概览** - 运行时间统计
2. **CPU 使用率** - CPU 使用率趋势（阈值：80%/90%）
3. **内存使用率** - 内存使用率趋势（阈值：85%/95%）
4. **系统负载** - 1/5/15 分钟负载
5. **磁盘使用率** - 各挂载点使用率
6. **网络流量** - 接收/发送速率
7. **磁盘 IO** - 读写速率
8. **节点状态** - 所有节点 Up/Down 状态

**访问：** http://grafana.mubai.top/d/linux-system-monitor

---

## 🔔 告警配置

### 钉钉告警

**状态：** ✅ 联系人已创建

**配置步骤：**
1. 创建钉钉机器人（获取 Webhook URL）
2. 登录 Grafana → Alerting → Contact points
3. 编辑 DingTalk → 填入 Webhook URL
4. 测试并保存

**告警规则模板：**
- InstanceDown (实例宕机)
- HighCPUUsage (CPU > 80%)
- HighMemoryUsage (内存 > 85%)
- HighDiskUsage (磁盘 > 85%)

详见：[grafana-dingtalk-alert-setup.md](Grafana/grafana-dingtalk-alert-setup.md)

---

## 📈 监控指标分类

### 系统指标（125+ 个）

| 分类 | 指标数量 | 关键指标 |
|------|---------|---------|
| **CPU** | 10+ | 使用率、负载、温度 |
| **内存** | 25+ | 使用率、Swap、缓存 |
| **磁盘** | 25+ | 使用率、IO、读写 |
| **网络** | 20+ | 流量、丢包、错误 |
| **系统** | 30+ | 进程、连接、时间 |
| **硬件** | 15+ | 温度、风扇、电压 |

详见：[linux-monitoring-metrics-full.md](Prometheus/linux-monitoring-metrics-full.md)

---

## 🔧 常用命令

### 查看服务状态

```bash
# Docker 容器状态
docker ps | grep -E 'prometheus|grafana|node-exporter'

# 服务健康检查
curl http://localhost:9090/-/healthy
curl http://localhost:3000/api/health
```

### 备份

```bash
# 备份 Grafana 数据
tar czf grafana-backup-$(date +%Y%m%d).tar.gz /data/grafana

# 备份 Prometheus 配置
tar czf prometheus-backup-$(date +%Y%m%d).tar.gz /data/prometheus
```

### 重启服务

```bash
docker restart prometheus grafana node-exporter
```

---

## 🔗 相关文档

- [CI-CD/](../CI-CD/) - CI/CD 平台文档
- [OpenClaw/](../OpenClaw/) - OpenClaw 部署文档
- [products/](../products/) - 产品设计文档

---

## 📝 更新记录

| 日期 | 更新内容 |
|------|----------|
| 2026-03-23 | 重构目录结构 - 从 OpenClaw/scripts/ 迁移到 Monitoring/ |
| 2026-03-23 | 完善监控体系（125+ 系统指标文档） |
| 2026-03-23 | 导入 Grafana Linux 监控面板 |
| 2026-03-23 | 配置钉钉告警联系人 |
| 2026-03-23 | 部署 Prometheus + Grafana |
| 2026-03-23 | 配置 Nginx 反向代理 |

---

**维护者：** OpenClaw 子节点 1  
**最后更新：** 2026-03-23  
**状态：** ✅ 运行中
