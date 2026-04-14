# Grafana 监控系统部署方案 v2.0

**文档编号：** MON-GRAFANA-001  
**版本：** v2.0  
**创建时间：** 2026-03-25  
**最后更新：** 2026-03-25 08:58 UTC  
**状态：** 已上线  
**评审：** 子节点 1 已复核，用户已确认

---

## 1. 概述

### 1.1 方案目标

构建覆盖 OpenClaw 三节点（堡垒机、主节点、子节点 1）的集中式监控系统，实现：
- 实时 CPU/内存/磁盘/网络监控
- 系统负载、进程状态、磁盘 IOPS 追踪
- 多节点统一 Dashboard 展示
- 阈值告警（70% 警告，90% 严重）

### 1.2 监控范围

| 节点 | 主机名 | 外网 IP | 内网 IP | 角色 |
|------|--------|---------|---------|------|
| 堡垒机 | ser280729144889 | 222.211.80.222 | - | 监控中心 1 |
| 主节点 | ser493590849885 | 38.246.245.32 | 10.0.118.4 | 被监控 |
| 子节点 1 | mubai-subagent1 | 38.246.245.39 | 10.0.118.6 | 监控中心 2 |

### 1.3 技术栈

| 组件 | 版本 | 端口 | 说明 |
|------|------|------|------|
| Prometheus | 3.10.0 | 9090 | 指标采集与存储 |
| Grafana | 12.4.1 | 3000 | 可视化 Dashboard |
| Node Exporter | 1.7.0 | 9100 | 系统指标采集 |

---

## 2. 架构设计

### 2.1 双监控中心架构

```
┌─────────────────────────────────────────────────────────┐
│                  监控架构拓扑                            │
└─────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │   主节点         │
                    │ 38.246.245.32   │
                    │  (被监控)        │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
    ┌─────────────────┐           ┌─────────────────┐
    │   堡垒机         │           │   子节点 1       │
    │ 222.211.80.222  │           │ 38.246.245.39   │
    │  (监控中心 1)     │           │  (监控中心 2)     │
    │  Prometheus     │           │  Prometheus     │
    │  Grafana :3000  │           │  Grafana :3000  │
    └─────────────────┘           └─────────────────┘
              │                           │
              └───────────┬───────────────┘
                          │
                          ▼
              ┌─────────────────────┐
              │   用户访问           │
              │ grafana.mubai.top   │
              │ (SSH 隧道代理)        │
              └─────────────────────┘
```

### 2.2 数据采集流程

```
Node Exporter (各节点)
       ↓ (9100/tcp)
Prometheus (拉取模式，15s 间隔)
       ↓ (本地查询)
Grafana (可视化展示)
       ↓ (30s 刷新)
用户浏览器
```

### 2.3 网络连通性

| 源 → 目标 | 堡垒机 | 主节点 | 子节点 1 |
|-----------|--------|--------|----------|
| **堡垒机** | - | ✅ 38.246.245.32:9100 | ✅ 38.246.245.39:9100 |
| **主节点** | ✅ 222.211.80.222:9100 | - | ✅ 38.246.245.39:9100 |
| **子节点 1** | ✅ 222.211.80.222:9100 | ✅ 38.246.245.32:9100 | - |

**关键发现：** 主节点内网 IP (10.0.118.4) 在跨网段场景下不可达，必须使用外网 IP (38.246.245.32)。

---

## 3. 部署配置

### 3.1 Docker Compose 配置（堡垒机）

**文件路径：** `/data/monitoring/docker-compose.yml`

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/data:/prometheus
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./grafana/data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_SERVER_SERVE_FROM_SUB_PATH=true
    depends_on:
      - prometheus
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
    networks:
      - monitoring

  jenkins:
    image: jenkins/jenkins:lts-jdk17
    container_name: jenkins
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - ./jenkins/home:/var/jenkins_home
    environment:
      - JAVA_OPTS=-Djava.awt.headless=true
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

### 3.2 Prometheus 配置（堡垒机）

**文件路径：** `/data/monitoring/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100', '38.246.245.39:9100', '38.246.245.32:9100']
```

### 3.3 Prometheus 配置（子节点 1）

**文件路径：** `/data/monitoring/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100', '222.211.80.222:9100', '38.246.245.32:9100']
```

### 3.4 Node Exporter 部署

**Docker 方式（推荐）：**
```bash
docker run -d \
  --name node-exporter \
  --restart unless-stopped \
  --net host \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /:/rootfs:ro \
  prom/node-exporter:latest \
  --path.procfs=/host/proc \
  --path.sysfs=/host/sys
```

**进程方式（主节点）：**
```bash
# 后台运行
nohup /usr/local/bin/node_exporter --web.listen-address=:9100 > /var/log/node_exporter.log 2>&1 &

# 验证
ss -tlnp | grep 9100
curl -s http://localhost:9100/metrics | head -3
```

---

## 4. Grafana Dashboard 配置

### 4.1 Dashboard 导入

**Dashboard UID:** `linux-system-monitor`  
**面板数量:** 16 个（中文界面）  
**刷新间隔:** 30 秒  
**时间范围:** 默认 1 小时

### 4.2 监控面板清单

#### 概览面板（8 个）

| ID | 面板名称 | 指标 | 阈值 |
|----|----------|------|------|
| 1 | CPU 使用率 | 实时百分比 | 70%/90% |
| 2 | 内存使用率 | 实时百分比 | 70%/90% |
| 3 | 磁盘使用率 | 实时百分比 | 70%/90% |
| 4 | 节点名称 | 主机名 | - |
| 5 | 节点 IP | 实例地址 | - |
| 6 | 总内存 | 内存容量 | - |
| 7 | 总磁盘 | 磁盘容量 | - |
| 8 | 运行时间 | 系统 uptime | - |

#### 趋势图表面板（8 个）

| ID | 面板名称 | 指标 | 说明 |
|----|----------|------|------|
| 9 | CPU 使用率趋势 | 5m 平均 | 含 P95/P99 线 |
| 10 | 内存使用趋势 | Buffers/Cached | 内存分布 |
| 11 | 磁盘使用率 | 按挂载点 | 分区使用率 |
| 12 | 网络流量 | 接收/发送 | 网卡流量 |
| 13 | 系统负载 | Load 1/5/15m | 负载趋势 |
| 14 | 进程状态 | Running/Blocked | 进程统计 |
| 15 | 磁盘 IOPS | 读/写次数 | IO 性能 |
| 16 | 磁盘吞吐量 | 读/写字节 | 带宽使用 |

### 4.3 变量配置

**节点选择器变量：**

| 配置项 | 值 |
|--------|-----|
| Name | `node` |
| Label | `节点` |
| Type | `Query` |
| Query | `label_values(node_uname_info, instance)` |
| Refresh | `On Dashboard Load` |
| Sort | `Alphabetical` |

---

## 5. 访问方式

### 5.1 直接访问

| 监控中心 | URL | 登录凭证 |
|----------|-----|----------|
| 堡垒机 | http://222.211.80.222:3000 | admin / admin123 |
| 子节点 1 | http://38.246.245.39:3000 | admin / admin123 |

### 5.2 域名访问（推荐）

| 域名 | 目标 | 说明 |
|------|------|------|
| grafana.mubai.top | 堡垒机 :3000 | SSH 隧道代理 |
| promethus.mubai.top | 堡垒机 :9090 | SSH 隧道代理 |
| jenkins.mubai.top | 堡垒机 :8080 | SSH 隧道代理 |

**SSH 隧道配置（子节点 1）：**
```bash
# 服务状态
systemctl status ssh-tunnel.service

# 隧道端口映射
18080 → 堡垒机 8080 (Jenkins)
19090 → 堡垒机 9090 (Prometheus)
13000 → 堡垒机 3000 (Grafana)
```

### 5.3 Dashboard 路径

```
/d/linux-system-monitor/linux-system-monitor-dashboard
```

---

## 6. 运维操作

### 6.1 服务管理

```bash
# 查看服务状态
docker ps | grep -E 'prometheus|grafana|node-exporter'

# 重启服务
cd /data/monitoring
docker compose restart prometheus grafana

# 查看日志
docker logs prometheus --tail 50
docker logs grafana --tail 50

# 重新加载 Prometheus 配置
docker exec prometheus kill -HUP 1
```

### 6.2 添加新监控节点

1. **在新节点部署 Node Exporter**
```bash
docker run -d --name node-exporter --restart unless-stopped \
  --net host -v /proc:/host/proc:ro -v /sys:/host/sys:ro \
  prom/node-exporter:latest --path.procfs=/host/proc --path.sysfs=/host/sys
```

2. **更新 Prometheus 配置**
```yaml
scrape_configs:
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['现有节点', '新节点 IP:9100']
```

3. **重新加载配置**
```bash
docker exec prometheus kill -HUP 1
```

4. **验证目标状态**
```bash
curl -s 'http://localhost:9090/api/v1/targets' | \
  python3 -c "import sys,json; d=json.load(sys.stdin); \
  [print(f\"{t['labels']['instance']}: {t['health']}\") \
  for t in d['data']['activeTargets']]"
```

### 6.3 健康检查

```bash
# Prometheus 健康
curl -s http://localhost:9090/api/health

# Grafana 健康
curl -s -u admin:admin123 http://localhost:3000/api/health

# Node Exporter 健康
curl -s http://localhost:9100/metrics | head -3

# 所有目标状态
curl -s 'http://localhost:9090/api/v1/targets' | \
  python3 -m json.tool | grep -A2 'health'
```

---

## 7. 故障排查

### 7.1 常见问题

| 问题 | 可能原因 | 解决方案 |
|------|----------|----------|
| Dashboard 无数据 | Prometheus 数据源未配置 | 手动添加 Prometheus 数据源 |
| 节点选择器无选项 | PromQL 查询无结果 | 检查 node_uname_info 指标 |
| Target 状态 down | 网络不通或服务未启动 | 检查 9100 端口连通性 |
| Grafana 无法访问 | 反向代理配置问题 | 设置 GF_SERVER_SERVE_FROM_SUB_PATH=true |
| 容器权限错误 | 挂载目录权限不足 | chmod -R 777 数据目录 |

### 7.2 网络连通性测试

```bash
# TCP 端口测试
timeout 3 bash -c 'echo > /dev/tcp/IP/9100' && echo '可达' || echo '不可达'

# HTTP 指标测试
curl -s --connect-timeout 5 http://IP:9100/metrics | head -3

# Ping 测试
ping -c 2 IP | tail -3
```

### 7.3 防火墙检查

```bash
# 检查 iptables 规则
iptables -L -n | grep 9100

# 检查 UFW 状态
ufw status

# 检查端口监听
ss -tlnp | grep 9100
```

---

## 8. 备份与恢复

### 8.1 数据备份

```bash
# Prometheus 数据
tar czf prometheus-data-$(date +%Y%m%d).tar.gz /data/monitoring/prometheus/data/

# Grafana 数据（含 Dashboard）
tar czf grafana-data-$(date +%Y%m%d).tar.gz /data/monitoring/grafana/data/

# 配置文件
tar czf monitoring-config-$(date +%Y%m%d).tar.gz \
  /data/monitoring/prometheus/prometheus.yml \
  /data/monitoring/docker-compose.yml
```

### 8.2 Dashboard 导出

```bash
# 通过 API 导出
curl -s -u admin:admin123 \
  http://localhost:3000/api/dashboards/uid/linux-system-monitor | \
  jq '.dashboard' > dashboard-backup.json
```

### 8.3 恢复步骤

```bash
# 停止服务
docker compose down

# 恢复数据
tar xzf prometheus-data-YYYYMMDD.tar.gz -C /
tar xzf grafana-data-YYYYMMDD.tar.gz -C /

# 启动服务
docker compose up -d
```

---

## 9. 安全建议

### 9.1 访问控制

- ✅ 修改默认密码（admin/admin123）
- ✅ 限制 Grafana 端口仅内网访问
- ✅ 使用 Nginx 反向代理 + HTTPS
- ✅ 配置 Grafana 认证（LDAP/OAuth）

### 9.2 网络安全

- ✅ SSH 隧道加密跨境流量
- ✅ 防火墙限制 9100 端口访问来源
- ✅ Prometheus 不暴露公网

### 9.3 数据安全

- ✅ 定期备份 Prometheus 数据
- ✅ 敏感信息不提交 Git
- ✅ 使用环境变量存储密码

---

## 10. 监控指标说明

### 10.1 CPU 指标

| 指标名 | 说明 | PromQL |
|--------|------|--------|
| CPU 使用率 | 非空闲 CPU 百分比 | `100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` |
| CPU 系统态 | 内核态 CPU 使用 | `irate(node_cpu_seconds_total{mode="system"}[5m])` |
| CPU 用户态 | 用户态 CPU 使用 | `irate(node_cpu_seconds_total{mode="user"}[5m])` |
| CPU IOWait | IO 等待时间 | `irate(node_cpu_seconds_total{mode="iowait"}[5m])` |

### 10.2 内存指标

| 指标名 | 说明 | PromQL |
|--------|------|--------|
| 内存使用率 | 已用内存百分比 | `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100` |
| 可用内存 | 可用内存字节 | `node_memory_MemAvailable_bytes` |
| 总内存 | 总内存字节 | `node_memory_MemTotal_bytes` |
| Buffer | 缓冲区内存 | `node_memory_Buffers_bytes` |
| Cached | 缓存内存 | `node_memory_Cached_bytes` |

### 10.3 磁盘指标

| 指标名 | 说明 | PromQL |
|--------|------|--------|
| 磁盘使用率 | 已用磁盘百分比 | `100 - ((node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes)` |
| 磁盘 IOPS 读 | 每秒读操作数 | `irate(node_disk_reads_completed_total[5m])` |
| 磁盘 IOPS 写 | 每秒写操作数 | `irate(node_disk_writes_completed_total[5m])` |
| 磁盘吞吐量读 | 每秒读字节数 | `irate(node_disk_read_bytes_total[5m])` |
| 磁盘吞吐量写 | 每秒写字节数 | `irate(node_disk_written_bytes_total[5m])` |

### 10.4 网络指标

| 指标名 | 说明 | PromQL |
|--------|------|--------|
| 网络接收 | 每秒接收字节数 | `irate(node_network_receive_bytes_total[5m])` |
| 网络发送 | 每秒发送字节数 | `irate(node_network_transmit_bytes_total[5m])` |

### 10.5 系统负载

| 指标名 | 说明 | PromQL |
|--------|------|--------|
| Load 1m | 1 分钟平均负载 | `node_load1` |
| Load 5m | 5 分钟平均负载 | `node_load5` |
| Load 15m | 15 分钟平均负载 | `node_load15` |

---

## 11. 变更记录

| 版本 | 日期 | 变更内容 | 变更人 |
|------|------|----------|--------|
| v1.0 | 2026-03-24 | 初始部署（单节点） | OpenClaw |
| v2.0 | 2026-03-25 | 三节点监控 + 双中心架构 | OpenClaw |

---

## 12. 附录

### 12.1 快速命令参考

```bash
# 部署 Node Exporter
docker run -d --name node-exporter --restart unless-stopped --net host \
  -v /proc:/host/proc:ro -v /sys:/host/sys:ro -v /:/rootfs:ro \
  prom/node-exporter:latest --path.procfs=/host/proc --path.sysfs=/host/sys

# 检查目标状态
curl -s 'http://localhost:9090/api/v1/targets' | \
  python3 -c "import sys,json; d=json.load(sys.stdin); \
  [print(f\"{t['labels']['instance']}: {t['health']}\") \
  for t in d['data']['activeTargets'] if t['labels'].get('job')=='node-exporter']"

# 重置 Grafana 密码
docker exec grafana grafana-cli admin reset-admin-password 新密码

# 查看可用指标
curl -s 'http://localhost:9090/api/v1/label/__name__/values' | \
  python3 -m json.tool | grep node_
```

### 12.2 相关文档

- [Prometheus 官方文档](https://prometheus.io/docs/)
- [Grafana 官方文档](https://grafana.com/docs/)
- [Node Exporter GitHub](https://github.com/prometheus/node_exporter)
- 内部文档：`/data/openclaw-dist/CI-CD/常规变更单模板.md`

---

**文档归档位置：** `/data/openclaw-dist/CI-CD/服务方案/Grafana 监控系统部署方案-v2.0.md`  
**Git 仓库：** `https://github.com/muba0321/notes-by-ai`  
**同步状态：** 待提交
