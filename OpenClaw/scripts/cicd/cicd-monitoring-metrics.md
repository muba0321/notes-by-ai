# CI/CD 平台监控指标文档

_Prometheus + Grafana + Node Exporter 完整监控方案_

**创建日期：** 2026-03-23  
**版本：** 1.0

---

## 📊 监控架构

```
┌─────────────────────────────────────────────────────────────┐
│                      Grafana (3000)                          │
│                    可视化展示层                               │
└────────────────────┬────────────────────────────────────────┘
                     │ 查询 (PromQL)
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                    Prometheus (9090)                         │
│                  指标采集与存储层                             │
└────────────┬──────────────────────┬─────────────────────────┘
             │ 采集                  │ 采集
             ↓                       ↓
┌────────────────────┐    ┌────────────────────────────────────┐
│  Node Exporter     │    │  Node Exporter                     │
│  子节点 1 (:9100)     │    │  主节点 (:9100)                    │
│  系统指标          │    │  系统指标                          │
└────────────────────┘    └────────────────────────────────────┘
             │                       │
             └───────────┬───────────┘
                         │
             ┌───────────┴───────────┐
             ↓                       ↓
    ┌────────────────┐    ┌────────────────┐
    │    Jenkins     │    │     其他       │
    │   (:8080)      │    │     服务       │
    │  CI/CD 指标     │    │                │
    └────────────────┘    └────────────────┘
```

---

## 🎯 监控目标清单

| 目标 | 地址 | 端口 | 说明 |
|------|------|------|------|
| **Prometheus** | localhost | 9090 | 自监控 |
| **Grafana** | localhost | 3000 | 可视化平台 |
| **Jenkins** | jenkins:8080 | 8080 | CI/CD 平台 |
| **Node Exporter (子节点 1)** | localhost | 9100 | 子节点系统监控 |
| **Node Exporter (主节点)** | 10.0.118.4 | 9100 | 主节点系统监控 |

---

## 📈 监控指标分类

### 1. 系统资源指标 (Node Exporter)

#### CPU 指标

| 指标名 | 说明 | 告警阈值 |
|--------|------|---------|
| `node_cpu_seconds_total` | CPU 使用时间（按模式） | - |
| `node_load1` | 1 分钟平均负载 | > CPU 核心数 * 2 |
| `node_load5` | 5 分钟平均负载 | > CPU 核心数 * 1.5 |
| `node_load15` | 15 分钟平均负载 | > CPU 核心数 |

**常用查询：**
```promql
# CPU 使用率
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 负载与 CPU 核心数比率
node_load1 / count by(instance) (node_cpu_seconds_total{mode="idle"})
```

---

#### 内存指标

| 指标名 | 说明 | 告警阈值 |
|--------|------|---------|
| `node_memory_MemTotal_bytes` | 总内存 | - |
| `node_memory_MemAvailable_bytes` | 可用内存 | - |
| `node_memory_Buffers_bytes` | 缓冲区内存 | - |
| `node_memory_Cached_bytes` | 缓存内存 | - |
| `node_memory_SwapTotal_bytes` | 总交换空间 | - |
| `node_memory_SwapFree_bytes` | 空闲交换空间 | - |

**常用查询：**
```promql
# 内存使用率
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# 交换空间使用率
(1 - (node_memory_SwapFree_bytes / node_memory_SwapTotal_bytes)) * 100
```

---

#### 磁盘指标

| 指标名 | 说明 | 告警阈值 |
|--------|------|---------|
| `node_filesystem_size_bytes` | 文件系统总大小 | - |
| `node_filesystem_avail_bytes` | 文件系统可用空间 | - |
| `node_filesystem_free_bytes` | 文件系统空闲空间 | - |
| `node_disk_read_bytes_total` | 磁盘读取总量 | - |
| `node_disk_written_bytes_total` | 磁盘写入总量 | - |
| `node_disk_io_time_seconds_total` | 磁盘 IO 时间 | - |

**常用查询：**
```promql
# 磁盘使用率
(1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100

# 磁盘 IO 使用率
rate(node_disk_io_time_seconds_total[5m]) * 100
```

---

#### 网络指标

| 指标名 | 说明 | 告警阈值 |
|--------|------|---------|
| `node_network_receive_bytes_total` | 网络接收总量 | - |
| `node_network_transmit_bytes_total` | 网络发送总量 | - |
| `node_network_receive_drop_total` | 网络接收丢包 | > 100/min |
| `node_network_transmit_drop_total` | 网络发送丢包 | > 100/min |
| `node_network_receive_errs_total` | 网络接收错误 | > 10/min |
| `node_network_transmit_errs_total` | 网络发送错误 | > 10/min |

**常用查询：**
```promql
# 网络接收速率
rate(node_network_receive_bytes_total{device!="lo"}[5m])

# 网络发送速率
rate(node_network_transmit_bytes_total{device!="lo"}[5m])

# 网络丢包率
rate(node_network_receive_drop_total[5m]) / rate(node_network_receive_bytes_total[5m]) * 100
```

---

### 2. Jenkins 指标

| 指标名 | 说明 | 告警阈值 |
|--------|------|---------|
| `jenkins_jobs_queueLength` | 构建队列长度 | > 10 |
| `jenkins_jobs_duration_seconds_summary` | 构建时长统计 | - |
| `jenkins_jobs_failed_count` | 失败构建数 | > 5/小时 |
| `jenkins_executor_count` | 执行器数量 | - |
| `jenkins_executor_in_use_count` | 使用中执行器 | - |
| `jenkins_node_count` | 节点数量 | - |
| `jenkins_node_offline_value` | 离线节点数 | > 0 |

**常用查询：**
```promql
# 构建队列长度
jenkins_jobs_queueLength

# 构建成功率
jenkins_jobs_success_count / (jenkins_jobs_success_count + jenkins_jobs_failed_count) * 100

# 执行器使用率
jenkins_executor_in_use_count / jenkins_executor_count * 100
```

---

### 3. Prometheus 自监控指标

| 指标名 | 说明 | 告警阈值 |
|--------|------|---------|
| `prometheus_tsdb_head_samples_appended_total` | 采集的样本总数 | - |
| `prometheus_tsdb_head_active_appenders` | 活跃的追加器 | - |
| `prometheus_target_scrape_pool_targets` | 目标池中的目标数 | - |
| `prometheus_target_scrape_pool_sync_total` | 目标池同步次数 | - |
| `prometheus_rule_group_duration_seconds` | 规则组执行时长 | - |
| `prometheus_rule_group_iterations_missed_total` | 错过的规则组迭代 | > 0 |

---

## ⚠️ 告警规则

### 系统告警

```yaml
groups:
  - name: system_alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "高 CPU 使用率 ({{ $value }}%)"
          description: "实例 {{ $labels.instance }} 的 CPU 使用率超过 80%"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "高内存使用率 ({{ $value }}%)"
          description: "实例 {{ $labels.instance }} 的内存使用率超过 85%"

      - alert: HighDiskUsage
        expr: (1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "高磁盘使用率 ({{ $value }}%)"
          description: "实例 {{ $labels.instance }} 的磁盘使用率超过 85%"

      - alert: InstanceDown
        expr: up == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "实例宕机 ({{ $labels.instance }})"
          description: "实例 {{ $labels.instance }} 已宕机超过 2 分钟"
```

---

### Jenkins 告警

```yaml
  - name: jenkins_alerts
    rules:
      - alert: JenkinsBuildQueueHigh
        expr: jenkins_jobs_queueLength > 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Jenkins 构建队列过长 ({{ $value }})"
          description: "Jenkins 构建队列长度超过 10"

      - alert: JenkinsNodeOffline
        expr: jenkins_node_offline_value > 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Jenkins 节点离线"
          description: "有 {{ $value }} 个 Jenkins 节点离线"

      - alert: JenkinsHighBuildFailureRate
        expr: rate(jenkins_jobs_failed_count[1h]) > 5
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Jenkins 构建失败率高"
          description: "每小时失败构建数超过 5 个"
```

---

## 📊 Grafana Dashboard 配置

### 推荐 Dashboard

| Dashboard | ID | 用途 |
|-----------|----|------|
| **Node Exporter Full** | 1860 | 完整系统监控 |
| **Jenkins Overview** | 9964 | Jenkins 监控 |
| **Prometheus Stats** | 2 | Prometheus 自身监控 |
| **Linux 系统监控（自定义）** | - | 基础系统指标 |

---

### 自定义 Linux 系统监控面板

#### Panel 1: CPU 使用率

```promql
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**可视化：** Time series  
**阈值：** 80% (warning), 90% (critical)

---

#### Panel 2: 内存使用率

```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

**可视化：** Time series  
**阈值：** 85% (warning), 95% (critical)

---

#### Panel 3: 磁盘使用率

```promql
(1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100
```

**可视化：** Time series 或 Gauge  
**阈值：** 85% (warning), 95% (critical)

---

#### Panel 4: 网络流量

```promql
# 接收
rate(node_network_receive_bytes_total{device!="lo"}[5m])

# 发送
rate(node_network_transmit_bytes_total{device!="lo"}[5m])
```

**可视化：** Time series

---

#### Panel 5: 系统负载

```promql
node_load1
node_load5
node_load15
```

**可视化：** Time series

---

#### Panel 6: 运行状态概览

```promql
# Up/Down 状态
up{job=~"node-.*"}

# 运行时间
node_time_seconds - node_boot_time_seconds
```

**可视化：** Stat 或 Table

---

## 🔧 配置管理

### Prometheus 配置文件

**位置：** `/data/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'jenkins'
    metrics_path: '/prometheus'
    static_configs:
      - targets: ['jenkins:8080']

  - job_name: 'node-subagent1'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          node: subagent1
          role: product-design

  - job_name: 'node-server'
    static_configs:
      - targets: ['10.0.118.4:9100']
        labels:
          node: server
          role: main
```

---

### Grafana 数据源配置

**Prometheus 数据源：**
- Name: Prometheus
- Type: Prometheus
- URL: http://prometheus:9090
- Access: Server

---

## 📝 维护说明

### 添加新监控目标

1. 在目标机器安装 Node Exporter
2. 更新 Prometheus 配置添加 scrape_config
3. 重启 Prometheus
4. 在 Grafana 导入或创建 Dashboard

### 备份策略

```bash
# 备份 Prometheus 配置
tar czf prometheus-backup-$(date +%Y%m%d).tar.gz /data/prometheus

# 备份 Grafana 数据
tar czf grafana-backup-$(date +%Y%m%d).tar.gz /data/grafana
```

### 数据保留

Prometheus 默认保留 15 天数据，可通过启动参数调整：
```bash
--storage.tsdb.retention.time=30d
```

---

## 🔗 相关文档

- [Prometheus 官方文档](https://prometheus.io/docs/)
- [Grafana 官方文档](https://grafana.com/docs/)
- [Node Exporter GitHub](https://github.com/prometheus/node_exporter)
- [部署记录](./prometheus-grafana-deployment.md)
- [Nginx 反向代理配置](./nginx-proxy-config.md)

---

**维护者：** OpenClaw 子节点 1  
**最后更新：** 2026-03-23  
**状态：** ✅ 运行中
