# Grafana 40 核心监控指标详解

_Linux 系统监控 Dashboard v2 - 40 个高优先级指标_

**创建日期：** 2026-03-23  
**Dashboard UID:** linux-system-monitor-v2  
**版本：** 2.0

---

## 📊 Dashboard 概览

| 项目 | 值 |
|------|-----|
| **面板数量** | 20 个 |
| **监控指标** | 40 个 |
| **刷新频率** | 30 秒 |
| **时间范围** | 最近 1 小时 |

---

## 🎯 40 个核心指标清单

### P0 级 - 最关键指标（5 个）

| # | 指标 | 说明 | 告警阈值 |
|---|------|------|---------|
| 1 | **CPU 使用率** | 系统整体 CPU 使用情况 | >80% 警告，>90% 严重 |
| 2 | **内存使用率** | 物理内存使用情况 | >85% 警告，>95% 严重 |
| 3 | **磁盘使用率** | 磁盘空间使用情况 | >85% 警告，>95% 严重 |
| 4 | **系统负载** | 1 分钟平均负载 | >CPU 核心数*2 |
| 5 | **运行时间** | 系统连续运行时间 | - |

---

### P1 级 - 重要指标（10 个）

| # | 指标 | 说明 | 告警阈值 |
|---|------|------|---------|
| 6 | CPU User 时间 | 用户空间 CPU 使用 | - |
| 7 | CPU System 时间 | 内核空间 CPU 使用 | - |
| 8 | CPU IOWait | IO 等待时间 | >20% |
| 9 | 可用内存 | 实际可用内存量 | <10% |
| 10 | Swap 使用率 | 交换空间使用 | >50% |
| 11 | 磁盘读取速率 | 磁盘读取速度 | - |
| 12 | 磁盘写入速率 | 磁盘写入速度 | - |
| 13 | 网络接收流量 | 网络入口流量 | - |
| 14 | 网络发送流量 | 网络出口流量 | - |
| 15 | TCP 连接数 | 当前 TCP 连接数 | - |

---

### P2 级 - 参考指标（15 个）

| # | 指标 | 说明 |
|---|------|------|
| 16 | 内存缓存 | 页面缓存大小 |
| 17 | 内存缓冲 | 内核缓冲区大小 |
| 18 | 磁盘 IO 延迟 | 磁盘读写延迟 |
| 19 | 网络丢包率 | 网络包丢失比例 |
| 20 | 网络错误率 | 网络错误包比例 |
| 21 | TCP TIME_WAIT | TIME_WAIT 状态连接数 |
| 22 | TCP 重传率 | TCP 包重传比例 |
| 23 | TCP 接收错误 | TCP 接收错误数 |
| 24 | TCP 发送 RST | TCP 发送重置数 |
| 25 | 运行进程数 | 当前运行进程数 |
| 26 | 阻塞进程数 | 被阻塞进程数 |
| 27 | Fork 速率 | 进程创建速率 |
| 28 | 文件描述符 | 已分配文件描述符数 |
| 29 | 熵池可用 | 熵池可用位数 |
| 30 | 连接跟踪 | 连接跟踪条目数 |

---

### P3 级 - 详细指标（10 个）

| # | 指标 | 说明 |
|---|------|------|
| 31 | CPU 各核心使用率 | 每个 CPU 核心使用情况 |
| 32 | 5 分钟负载 | 5 分钟平均负载 |
| 33 | 15 分钟负载 | 15 分钟平均负载 |
| 34 | 磁盘使用率（按挂载点） | 各分区使用情况 |
| 35 | 网络流量（按网卡） | 各网卡流量 |
| 36 | 磁盘 IOPS | 每秒 IO 操作数 |
| 37 | CPU 压力等待 | PSI CPU 等待时间 |
| 38 | 内存压力停滞 | PSI 内存停滞时间 |
| 39 | 内存压力等待 | PSI 内存等待时间 |
| 40 | IO 压力停滞 | PSI IO 停滞时间 |

---

## 📈 Dashboard 面板布局

```
┌─────────────────────────────────────────────────────────────┐
│ Panel 1: 系统概览 (Stat) - 运行时间                         │
├─────────────────────────────────────────────────────────────┤
│ Panel 2-5: 核心指标 (Stat) - CPU/内存/磁盘/负载             │
├─────────────────────────────────────────────────────────────┤
│ Panel 6: CPU 使用率趋势 (Time series) - 4 个指标             │
│ Panel 7: 内存详细 (Time series) - 4 个指标                   │
├─────────────────────────────────────────────────────────────┤
│ Panel 8: 磁盘 IO (Time series) - 读写速率                    │
│ Panel 9: 磁盘使用率 (Time series) - 按挂载点                 │
├─────────────────────────────────────────────────────────────┤
│ Panel 10: 网络流量 (Time series) - 接收/发送                 │
│ Panel 11: 网络质量 (Time series) - 丢包/错误                 │
├─────────────────────────────────────────────────────────────┤
│ Panel 12: TCP 连接 (Time series) - 连接数/TIME_WAIT/孤立     │
│ Panel 13: TCP 质量 (Time series) - 重传/错误/RST             │
├─────────────────────────────────────────────────────────────┤
│ Panel 14: 系统负载 (Time series) - 1/5/15 分钟               │
│ Panel 15: 进程 (Time series) - 运行/阻塞/Fork                │
├─────────────────────────────────────────────────────────────┤
│ Panel 16: 文件描述符 (Stat) │ Panel 17: 熵池 (Stat) │ Panel 18: 连接跟踪 (Stat) │
├─────────────────────────────────────────────────────────────┤
│ Panel 19: CPU 压力监控 (Time series)                         │
│ Panel 20: 内存压力监控 (Time series)                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔍 指标详细说明

### 1. CPU 使用率

**PromQL:**
```promql
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**说明:** 系统整体 CPU 使用百分比

**告警:**
- Warning: >80% 持续 5 分钟
- Critical: >90% 持续 5 分钟

---

### 2. 内存使用率

**PromQL:**
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

**说明:** 物理内存使用百分比（包含缓存）

**告警:**
- Warning: >85% 持续 5 分钟
- Critical: >95% 持续 5 分钟

---

### 3. 磁盘使用率

**PromQL:**
```promql
(1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100
```

**说明:** 磁盘空间使用百分比

**告警:**
- Warning: >85% 持续 10 分钟
- Critical: >95% 持续 10 分钟

---

### 4. 系统负载

**PromQL:**
```promql
node_load1
```

**说明:** 1 分钟内平均负载（运行队列中的进程数）

**告警:**
- Warning: >CPU 核心数 * 2
- Critical: >CPU 核心数 * 3

---

### 5-8. CPU 详细指标

**PromQL:**
```promql
# User 时间
100 - (avg by(instance, mode) (rate(node_cpu_seconds_total{mode="user"}[5m])) * 100)

# System 时间
100 - (avg by(instance, mode) (rate(node_cpu_seconds_total{mode="system"}[5m])) * 100)

# IOWait
100 - (avg by(instance, mode) (rate(node_cpu_seconds_total{mode="iowait"}[5m])) * 100)
```

---

### 9-11. 内存详细指标

**PromQL:**
```promql
# 已用内存
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes

# 缓存
node_memory_Cached_bytes

# 缓冲
node_memory_Buffers_bytes

# Swap 已用
node_memory_SwapTotal_bytes - node_memory_SwapFree_bytes
```

---

### 12-15. 网络详细指标

**PromQL:**
```promql
# 接收流量
rate(node_network_receive_bytes_total{device!="lo"}[5m])

# 发送流量
rate(node_network_transmit_bytes_total{device!="lo"}[5m])

# 丢包
rate(node_network_receive_drop_total{device!="lo"}[5m])

# 错误
rate(node_network_receive_errs_total{device!="lo"}[5m])
```

---

### 16-20. TCP 详细指标

**PromQL:**
```promql
# 当前连接
node_netstat_Tcp_CurrEstab

# TIME_WAIT
node_sockstat_TCP_tw

# 重传
rate(node_netstat_Tcp_RetransSegs[5m])

# 接收错误
rate(node_netstat_Tcp_InErrs[5m])

# 发送 RST
rate(node_netstat_Tcp_OutRsts[5m])
```

---

## 🎨 面板配色方案

| 指标类型 | 颜色 |
|---------|------|
| CPU | 🔴 红色系 |
| 内存 | 🟡 黄色系 |
| 磁盘 | 🔵 蓝色系 |
| 网络 | 🟢 绿色系 |
| TCP | 🟣 紫色系 |
| 系统 | ⚫ 灰色系 |
| 压力 | ⚠️ 橙色系 |

---

## ⚠️ 告警配置建议

### 关键告警规则

```yaml
groups:
  - name: system_critical
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "高 CPU 使用率 ({{ $value }}%)"
          
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "高内存使用率 ({{ $value }}%)"
          
      - alert: HighDiskUsage
        expr: (1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "高磁盘使用率 ({{ $value }}%)"
```

---

## 🔗 访问地址

**Dashboard URL:** http://grafana.mubai.top/d/linux-system-monitor-v2

---

## 📝 更新记录

| 日期 | 版本 | 更新内容 |
|------|------|---------|
| 2026-03-23 | 2.0 | 扩容至 40 个核心指标，20 个面板 |
| 2026-03-23 | 1.0 | 初始版本（8 个面板） |

---

**维护者：** OpenClaw 子节点 1  
**最后更新：** 2026-03-23
