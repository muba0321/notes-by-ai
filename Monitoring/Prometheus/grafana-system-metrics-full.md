# Grafana 系统监控指标全集

_基于 Node Exporter 的完整系统监控指标与 PromQL 查询_

**版本：** 2.0  
**更新日期：** 2026-03-23  
**适用：** Prometheus + Grafana + Node Exporter

---

## 📊 指标分类总览

| 分类 | 指标数量 | 核心指标 |
|------|---------|---------|
| **CPU** | 8 | 使用率、负载、Guest 时间 |
| **内存** | 35+ | 使用率、Swap、缓存、页表 |
| **磁盘** | 20+ | 使用率、IO、读写、延迟 |
| **网络** | 25+ | 流量、丢包、错误、连接 |
| **系统** | 20+ | 进程、文件描述符、熵池 |
| **TCP/IP** | 30+ | 连接、重传、错误 |
| **压力监控** | 6 | PSI (Pressure Stall Information) |

---

## 🔴 CPU 监控指标

### 核心指标

| 指标名 | 说明 | 单位 |
|--------|------|------|
| `node_cpu_seconds_total` | CPU 各模式累计时间 | 秒 |
| `node_load1` | 1 分钟平均负载 | - |
| `node_load5` | 5 分钟平均负载 | - |
| `node_load15` | 15 分钟平均负载 | - |
| `node_cpu_guest_seconds_total` | 虚拟化 CPU 时间 | 秒 |
| `node_procs_running` | 运行中进程数 | 个 |
| `node_procs_blocked` | 阻塞进程数 | 个 |
| `node_pressure_cpu_waiting_seconds_total` | CPU 压力等待时间 | 秒 |

### CPU 模式说明

| mode | 说明 |
|------|------|
| `idle` | 空闲时间 |
| `user` | 用户空间时间 |
| `system` | 内核空间时间 |
| `iowait` | IO 等待时间 |
| `irq` | 硬件中断时间 |
| `softirq` | 软中断时间 |
| `steal` | 虚拟化窃取时间 |
| `nice` | 低优先级用户时间 |

### PromQL 查询示例

```promql
# CPU 使用率（总体）
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# CPU 使用率（按核心）
100 - (avg by(instance, cpu) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# CPU 各模式占比
avg by(instance, mode) (rate(node_cpu_seconds_total[5m])) * 100

# 负载与 CPU 核心数比率
node_load1 / count by(instance) (node_cpu_seconds_total{mode="idle"})

# 运行中进程数
node_procs_running

# 阻塞进程数
node_procs_blocked

# CPU 压力等待时间增长率
rate(node_pressure_cpu_waiting_seconds_total[5m])
```

### 告警规则

```yaml
- alert: HighCPUUsage
  expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "高 CPU 使用率 ({{ $value }}%)"
    description: "实例 {{ $labels.instance }} 的 CPU 使用率超过 80% 持续 5 分钟"

- alert: HighCPULoad
  expr: node_load1 / count by(instance) (node_cpu_seconds_total{mode="idle"}) > 2
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "高 CPU 负载 ({{ $value }})"
    description: "实例 {{ $labels.instance }} 的 1 分钟负载超过 CPU 核心数的 2 倍"

- alert: HighBlockedProcesses
  expr: node_procs_blocked > 3
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "高阻塞进程数 ({{ $value }})"
    description: "实例 {{ $labels.instance }} 有 {{ $value }} 个进程被阻塞"
```

---

## 🟡 内存监控指标

### 核心指标

| 指标名 | 说明 | 单位 |
|--------|------|------|
| `node_memory_MemTotal_bytes` | 总物理内存 | 字节 |
| `node_memory_MemFree_bytes` | 空闲内存 | 字节 |
| `node_memory_MemAvailable_bytes` | 可用内存 | 字节 |
| `node_memory_Buffers_bytes` | 内核缓冲区 | 字节 |
| `node_memory_Cached_bytes` | 页面缓存 | 字节 |
| `node_memory_SwapTotal_bytes` | 总交换空间 | 字节 |
| `node_memory_SwapFree_bytes` | 空闲交换空间 | 字节 |
| `node_memory_SwapCached_bytes` | 交换缓存 | 字节 |
| `node_memory_Active_bytes` | 活跃内存 | 字节 |
| `node_memory_Inactive_bytes` | 不活跃内存 | 字节 |
| `node_memory_Active_anon_bytes` | 活跃匿名内存 | 字节 |
| `node_memory_Inactive_anon_bytes` | 不活跃匿名内存 | 字节 |
| `node_memory_Active_file_bytes` | 活跃文件缓存 | 字节 |
| `node_memory_Inactive_file_bytes` | 不活跃文件缓存 | 字节 |
| `node_memory_Unevictable_bytes` | 不可回收内存 | 字节 |
| `node_memory_Mlocked_bytes` | 锁定内存 | 字节 |
| `node_memory_Dirty_bytes` | 待写入内存 | 字节 |
| `node_memory_Writeback_bytes` | 正在写入内存 | 字节 |
| `node_memory_KernelStack_bytes` | 内核栈 | 字节 |
| `node_memory_PageTables_bytes` | 页表 | 字节 |
| `node_memory_Committed_AS_bytes` | 承诺内存 | 字节 |
| `node_memory_CommitLimit_bytes` | 承诺限制 | 字节 |
| `node_memory_Slab_bytes` | 内核 SLAB 缓存 | 字节 |
| `node_memory_SReclaimable_bytes` | 可回收 SLAB | 字节 |
| `node_memory_SUnreclaim_bytes` | 不可回收 SLAB | 字节 |
| `node_memory_VmallocTotal_bytes` | 虚拟内存总计 | 字节 |
| `node_memory_VmallocUsed_bytes` | 已用虚拟内存 | 字节 |
| `node_memory_HugePages_Total` | 大页总数 | 个 |
| `node_memory_HugePages_Free` | 空闲大页数 | 个 |
| `node_memory_Hugepagesize_bytes` | 大页大小 | 字节 |

### PromQL 查询示例

```promql
# 内存使用率
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# 已用内存
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes

# 空闲内存
node_memory_MemFree_bytes

# 缓存使用
node_memory_Cached_bytes

# 缓冲区使用
node_memory_Buffers_bytes

# Swap 使用率
(1 - (node_memory_SwapFree_bytes / node_memory_SwapTotal_bytes)) * 100

# Swap 使用中
node_memory_SwapTotal_bytes - node_memory_SwapFree_bytes

# 活跃内存占比
(node_memory_Active_bytes / node_memory_MemTotal_bytes) * 100

# 不活跃内存占比
(node_memory_Inactive_bytes / node_memory_MemTotal_bytes) * 100

# 内核 SLAB 缓存
node_memory_Slab_bytes

# 可回收 SLAB 占比
(node_memory_SReclaimable_bytes / node_memory_Slab_bytes) * 100

# 内存压力（脏页比例）
(node_memory_Dirty_bytes / node_memory_MemTotal_bytes) * 100

# 承诺内存使用率
(node_memory_Committed_AS_bytes / node_memory_CommitLimit_bytes) * 100

# 虚拟内存使用
node_memory_VmallocUsed_bytes

# 大页使用率
(node_memory_HugePages_Total - node_memory_HugePages_Free) / node_memory_HugePages_Total * 100
```

### 告警规则

```yaml
- alert: HighMemoryUsage
  expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "高内存使用率 ({{ $value }}%)"
    description: "实例 {{ $labels.instance }} 的内存使用率超过 85%"

- alert: LowMemoryAvailable
  expr: node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100 < 10
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "内存严重不足 ({{ $value }}%)"
    description: "实例 {{ $labels.instance }} 可用内存低于 10%"

- alert: HighSwapUsage
  expr: (1 - (node_memory_SwapFree_bytes / node_memory_SwapTotal_bytes)) * 100 > 50
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "高 Swap 使用率 ({{ $value }}%)"
    description: "实例 {{ $labels.instance }} 的 Swap 使用率超过 50%"

- alert: HighDirtyMemory
  expr: (node_memory_Dirty_bytes / node_memory_MemTotal_bytes) * 100 > 5
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "高脏页比例 ({{ $value }}%)"
    description: "实例 {{ $labels.instance }} 的脏页比例超过 5%"
```

---

## 🔵 磁盘监控指标

### 文件系统指标

| 指标名 | 说明 | 单位 |
|--------|------|------|
| `node_filesystem_size_bytes` | 文件系统总大小 | 字节 |
| `node_filesystem_avail_bytes` | 可用空间 | 字节 |
| `node_filesystem_free_bytes` | 空闲空间 | 字节 |
| `node_filesystem_files` | 总文件节点数 | 个 |
| `node_filesystem_files_free` | 空闲文件节点数 | 个 |
| `node_filesystem_mount_info` | 挂载信息 | - |
| `node_filesystem_device_error` | 设备错误 | - |
| `node_filesystem_readonly` | 只读状态 | - |
| `node_filesystem_purgeable_bytes` | 可清理空间 | 字节 |

### 磁盘 IO 指标

| 指标名 | 说明 | 单位 |
|--------|------|------|
| `node_disk_read_bytes_total` | 读取总量 | 字节 |
| `node_disk_written_bytes_total` | 写入总量 | 字节 |
| `node_disk_reads_completed_total` | 读取次数 | 次 |
| `node_disk_writes_completed_total` | 写入次数 | 次 |
| `node_disk_read_time_seconds_total` | 读取耗时 | 秒 |
| `node_disk_write_time_seconds_total` | 写入耗时 | 秒 |
| `node_disk_io_time_seconds_total` | IO 总时间 | 秒 |
| `node_disk_io_time_weighted_seconds_total` | 加权 IO 时间 | 秒 |
| `node_disk_io_now` | 当前 IO 数 | 个 |
| `node_disk_reads_merged_total` | 合并读取数 | 次 |
| `node_disk_writes_merged_total` | 合并写入数 | 次 |
| `node_disk_flush_requests_total` | 刷新请求数 | 次 |
| `node_disk_flush_requests_time_seconds_total` | 刷新耗时 | 秒 |
| `node_disk_discards_completed_total` | 丢弃操作数 | 次 |
| `node_disk_discarded_sectors_total` | 丢弃扇区数 | 扇区 |
| `node_disk_discard_time_seconds_total` | 丢弃耗时 | 秒 |
| `node_disk_info` | 磁盘信息 | - |

### PromQL 查询示例

```promql
# 磁盘使用率
(1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100

# 磁盘 IO 使用率
rate(node_disk_io_time_seconds_total[5m]) * 100

# 读取速率 (MB/s)
rate(node_disk_read_bytes_total[5m]) / 1024 / 1024

# 写入速率 (MB/s)
rate(node_disk_written_bytes_total[5m]) / 1024 / 1024

# IOPS
rate(node_disk_reads_completed_total[5m]) + rate(node_disk_writes_completed_total[5m])

# 平均读取延迟 (ms)
rate(node_disk_read_time_seconds_total[5m]) / rate(node_disk_reads_completed_total[5m]) * 1000

# 平均写入延迟 (ms)
rate(node_disk_write_time_seconds_total[5m]) / rate(node_disk_writes_completed_total[5m]) * 1000

# 当前 IO 操作数
node_disk_io_now

# 文件节点使用率
(1 - (node_filesystem_files_free / node_filesystem_files)) * 100

# 只读文件系统
node_filesystem_readonly == 1

# 磁盘错误
node_filesystem_device_error == 1
```

### 告警规则

```yaml
- alert: HighDiskUsage
  expr: (1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 85
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "高磁盘使用率 ({{ $value }}%)"
    description: "实例 {{ $labels.instance }} 的磁盘使用率超过 85%"

- alert: DiskWillFillIn24Hours
  expr: predict_linear(node_filesystem_avail_bytes{fstype!="tmpfs"}[6h], 24*3600) < 0
  for: 30m
  labels:
    severity: warning
  annotations:
    summary: "磁盘将在 24 小时内耗尽"
    description: "实例 {{ $labels.instance }} 的 {{ $labels.mountpoint }} 将在 24 小时内耗尽"

- alert: HighDiskIOLatency
  expr: (rate(node_disk_read_time_seconds_total[5m]) / rate(node_disk_reads_completed_total[5m])) * 1000 > 100
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "高磁盘读取延迟 ({{ $value }}ms)"
    description: "实例 {{ $labels.instance }} 的磁盘读取延迟超过 100ms"

- alert: HighInodeUsage
  expr: (1 - (node_filesystem_files_free / node_filesystem_files)) * 100 > 85
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "高文件节点使用率 ({{ $value }}%)"
    description: "实例 {{ $labels.instance }} 的文件节点使用率超过 85%"
```

---

## 🟢 网络监控指标

### 核心指标

| 指标名 | 说明 | 单位 |
|--------|------|------|
| `node_network_receive_bytes_total` | 接收总量 | 字节 |
| `node_network_transmit_bytes_total` | 发送总量 | 字节 |
| `node_network_receive_packets_total` | 接收包数 | 个 |
| `node_network_transmit_packets_total` | 发送包数 | 个 |
| `node_network_receive_drop_total` | 接收丢包数 | 个 |
| `node_network_transmit_drop_total` | 发送丢包数 | 个 |
| `node_network_receive_errs_total` | 接收错误数 | 个 |
| `node_network_transmit_errs_total` | 发送错误数 | 个 |
| `node_network_receive_fifo_total` | FIFO 错误数 | 个 |
| `node_network_transmit_fifo_total` | 发送 FIFO 错误 | 个 |
| `node_network_receive_frame_total` | 帧错误数 | 个 |
| `node_network_receive_compressed_total` | 压缩包数 | 个 |
| `node_network_transmit_compressed_total` | 压缩发送数 | 个 |
| `node_network_receive_multicast_total` | 组播包数 | 个 |
| `node_network_transmit_colls_total` | 冲突数 | 个 |
| `node_network_up` | 网卡状态 | - |
| `node_network_speed_bytes` | 网卡速度 | 字节/秒 |
| `node_network_mtu_bytes` | MTU | 字节 |
| `node_network_carrier` | 载波状态 | - |
| `node_network_info` | 网卡信息 | - |

### PromQL 查询示例

```promql
# 网络接收速率 (MB/s)
sum by(instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m])) / 1024 / 1024

# 网络发送速率 (MB/s)
sum by(instance) (rate(node_network_transmit_bytes_total{device!="lo"}[5m])) / 1024 / 1024

# 网络接收包速率
rate(node_network_receive_packets_total{device!="lo"}[5m])

# 网络发送包速率
rate(node_network_transmit_packets_total{device!="lo"}[5m])

# 网络丢包率（接收）
sum by(instance) (rate(node_network_receive_drop_total[5m])) / sum by(instance) (rate(node_network_receive_packets_total[5m])) * 100

# 网络丢包率（发送）
sum by(instance) (rate(node_network_transmit_drop_total[5m])) / sum by(instance) (rate(node_network_transmit_packets_total[5m])) * 100

# 网络错误率
sum by(instance) (rate(node_network_receive_errs_total[5m]) + rate(node_network_transmit_errs_total[5m])) / sum by(instance) (rate(node_network_receive_packets_total[5m]) + rate(node_network_transmit_packets_total[5m])) * 100

# 网卡状态
node_network_up{device!="lo"}

# 网卡速度
node_network_speed_bytes

# MTU
node_network_mtu_bytes

# 组播包速率
rate(node_network_receive_multicast_total[5m])
```

### 告警规则

```yaml
- alert: NetworkInterfaceDown
  expr: node_network_up{device!="lo"} == 0
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "网卡宕机"
    description: "实例 {{ $labels.instance }} 的网卡 {{ $labels.device }} 已宕机"

- alert: HighNetworkPacketLoss
  expr: (sum by(instance) (rate(node_network_receive_drop_total[5m])) / sum by(instance) (rate(node_network_receive_packets_total[5m]))) * 100 > 1
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "高网络丢包率 ({{ $value }}%)"
    description: "实例 {{ $labels.instance }} 的网络丢包率超过 1%"

- alert: HighNetworkErrors
  expr: (sum by(instance) (rate(node_network_receive_errs_total[5m]) + rate(node_network_transmit_errs_total[5m]))) * 60 > 10
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "高网络错误率 ({{ $value }}/分钟)"
    description: "实例 {{ $labels.instance }} 每分钟网络错误超过 10 个"
```

---

## 🟣 系统监控指标

### 进程与文件描述符

| 指标名 | 说明 | 单位 |
|--------|------|------|
| `node_procs_running` | 运行中进程数 | 个 |
| `node_procs_blocked` | 阻塞进程数 | 个 |
| `node_forks_total` | 进程 fork 总数 | 次 |
| `node_filefd_allocated` | 已分配文件描述符 | 个 |
| `node_filefd_maximum` | 最大文件描述符 | 个 |
| `node_context_switches_total` | 上下文切换总数 | 次 |
| `node_intr_total` | 中断总数 | 次 |

### 时间与熵池

| 指标名 | 说明 | 单位 |
|--------|------|------|
| `node_time_seconds` | 系统时间 | 秒 |
| `node_boot_time_seconds` | 启动时间 | 秒 |
| `node_entropy_available_bits` | 熵池可用位数 | 位 |
| `node_entropy_pool_size_bits` | 熵池大小 | 位 |

### 连接跟踪

| 指标名 | 说明 | 单位 |
|--------|------|------|
| `node_nf_conntrack_entries` | 连接跟踪条目数 | 个 |
| `node_nf_conntrack_entries_limit` | 连接跟踪限制 | 个 |

### PromQL 查询示例

```promql
# 运行时间（天）
(node_time_seconds - node_boot_time_seconds) / 86400

# 运行时间（小时）
(node_time_seconds - node_boot_time_seconds) / 3600

# 文件描述符使用率
node_filefd_allocated / node_filefd_maximum * 100

# 上下文切换速率
rate(node_context_switches_total[5m])

# 中断速率
rate(node_intr_total[5m])

# 进程 fork 速率
rate(node_forks_total[5m])

# 熵池可用率
node_entropy_available_bits / node_entropy_pool_size_bits * 100

# 连接跟踪使用率
node_nf_conntrack_entries / node_nf_conntrack_entries_limit * 100
```

### 告警规则

```yaml
- alert: LowEntropy
  expr: node_entropy_available_bits < 1000
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "熵池不足 ({{ $value }} bits)"
    description: "实例 {{ $labels.instance }} 的熵池可用位数低于 1000"

- alert: HighFileDescriptorUsage
  expr: (node_filefd_allocated / node_filefd_maximum) * 100 > 80
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "高文件描述符使用率 ({{ $value }}%)"
    description: "实例 {{ $labels.instance }} 的文件描述符使用率超过 80%"

- alert: HighConntrackUsage
  expr: (node_nf_conntrack_entries / node_nf_conntrack_entries_limit) * 100 > 80
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "高连接跟踪使用率 ({{ $value }}%)"
    description: "实例 {{ $labels.instance }} 的连接跟踪使用率超过 80%"
```

---

## 🟤 TCP/IP 监控指标

### TCP 连接指标

| 指标名 | 说明 | 单位 |
|--------|------|------|
| `node_netstat_Tcp_CurrEstab` | 当前 TCP 连接数 | 个 |
| `node_netstat_Tcp_ActiveOpens` | TCP 主动打开数 | 个 |
| `node_netstat_Tcp_PassiveOpens` | TCP 被动打开数 | 个 |
| `node_netstat_Tcp_InSegs` | TCP 接收段数 | 个 |
| `node_netstat_Tcp_OutSegs` | TCP 发送段数 | 个 |
| `node_netstat_Tcp_RetransSegs` | TCP 重传段数 | 个 |
| `node_netstat_Tcp_InErrs` | TCP 接收错误数 | 个 |
| `node_netstat_Tcp_OutRsts` | TCP 发送 RST 数 | 个 |

### TCP 扩展指标

| 指标名 | 说明 | 单位 |
|--------|------|------|
| `node_netstat_TcpExt_ListenOverflows` | 监听队列溢出 | 次 |
| `node_netstat_TcpExt_ListenDrops` | 监听队列丢弃 | 次 |
| `node_netstat_TcpExt_SyncookiesSent` | SYN Cookie 发送数 | 个 |
| `node_netstat_TcpExt_SyncookiesRecv` | SYN Cookie 接收数 | 个 |
| `node_netstat_TcpExt_SyncookiesFailed` | SYN Cookie 失败数 | 个 |
| `node_netstat_TcpExt_TCPSynRetrans` | SYN 重传数 | 个 |
| `node_netstat_TcpExt_TCPTimeouts` | TCP 超时数 | 个 |
| `node_netstat_TcpExt_TCPRcvQDrop` | 接收队列丢弃 | 个 |
| `node_netstat_TcpExt_TCPOFOQueue` | 乱序队列数 | 个 |

### Socket 指标

| 指标名 | 说明 | 单位 |
|--------|------|------|
| `node_sockstat_TCP_alloc` | TCP 分配套接字 | 个 |
| `node_sockstat_TCP_inuse` | TCP 使用套接字 | 个 |
| `node_sockstat_TCP_tw` | TCP TIME_WAIT 数 | 个 |
| `node_sockstat_TCP_orphan` | TCP 孤立连接 | 个 |
| `node_sockstat_TCP_mem` | TCP 内存页 | 页 |
| `node_sockstat_TCP_mem_bytes` | TCP 内存字节 | 字节 |
| `node_sockstat_UDP_inuse` | UDP 使用套接字 | 个 |
| `node_sockstat_sockets_used` | 总套接字使用数 | 个 |

### PromQL 查询示例

```promql
# 当前 TCP 连接数
node_netstat_Tcp_CurrEstab

# TCP 连接速率
rate(node_netstat_Tcp_ActiveOpens[5m]) + rate(node_netstat_Tcp_PassiveOpens[5m])

# TCP 重传率
rate(node_netstat_Tcp_RetransSegs[5m]) / rate(node_netstat_Tcp_OutSegs[5m]) * 100

# TCP 错误率
rate(node_netstat_Tcp_InErrs[5m]) / rate(node_netstat_Tcp_InSegs[5m]) * 100

# SYN Cookie 使用
rate(node_netstat_TcpExt_SyncookiesSent[5m])

# SYN 重传速率
rate(node_netstat_TcpExt_TCPSynRetrans[5m])

# TCP 超时速率
rate(node_netstat_TcpExt_TCPTimeouts[5m])

# TIME_WAIT 连接数
node_sockstat_TCP_tw

# 孤立 TCP 连接数
node_sockstat_TCP_orphan

# UDP 使用套接字数
node_sockstat_UDP_inuse
```

### 告警规则

```yaml
- alert: HighTCPRetransmission
  expr: (rate(node_netstat_Tcp_RetransSegs[5m]) / rate(node_netstat_Tcp_OutSegs[5m])) * 100 > 3
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "高 TCP 重传率 ({{ $value }}%)"
    description: "实例 {{ $labels.instance }} 的 TCP 重传率超过 3%"

- alert: HighTCPTimeWait
  expr: node_sockstat_TCP_tw > 1000
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "高 TIME_WAIT 连接数 ({{ $value }})"
    description: "实例 {{ $labels.instance }} 有 {{ $value }} 个 TIME_WAIT 连接"

- alert: HighSynCookies
  expr: rate(node_netstat_TcpExt_SyncookiesSent[5m]) > 10
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "SYN Cookie 使用频繁 ({{ $value }}/秒)"
    description: "实例 {{ $labels.instance }} 可能正在遭受 SYN 洪水攻击"
```

---

## 🟠 压力监控指标 (PSI)

### 核心指标

| 指标名 | 说明 | 单位 |
|--------|------|------|
| `node_pressure_cpu_waiting_seconds_total` | CPU 压力等待时间 | 秒 |
| `node_pressure_io_waiting_seconds_total` | IO 压力等待时间 | 秒 |
| `node_pressure_io_stalled_seconds_total` | IO 压力停滞时间 | 秒 |
| `node_pressure_memory_waiting_seconds_total` | 内存压力等待时间 | 秒 |
| `node_pressure_memory_stalled_seconds_total` | 内存压力停滞时间 | 秒 |

### PromQL 查询示例

```promql
# CPU 压力等待时间增长率
rate(node_pressure_cpu_waiting_seconds_total[5m])

# IO 压力停滞时间增长率
rate(node_pressure_io_stalled_seconds_total[5m])

# 内存压力停滞时间增长率
rate(node_pressure_memory_stalled_seconds_total[5m])

# 综合压力指数
(rate(node_pressure_cpu_waiting_seconds_total[5m]) + 
 rate(node_pressure_io_stalled_seconds_total[5m]) + 
 rate(node_pressure_memory_stalled_seconds_total[5m])) / 3
```

### 告警规则

```yaml
- alert: HighPressureStall
  expr: rate(node_pressure_io_stalled_seconds_total[5m]) > 0.5
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "高 IO 压力停滞"
    description: "实例 {{ $labels.instance }} 的 IO 压力停滞时间超过 50%"
```

---

## 📊 Grafana Dashboard 面板配置

### 推荐面板布局

```
┌─────────────────────────────────────────────────────────────┐
│  系统概览 (Stat/Graph)                                      │
│  运行时间 | 负载 | 进程数 | 连接数 | 文件描述符              │
├─────────────────────────────────────────────────────────────┤
│  CPU 使用率 (Time series)    │  内存使用率 (Time series)    │
│  [按核心拆分 + 各模式]        │  [含 Swap/缓存]              │
├─────────────────────────────────────────────────────────────┤
│  系统负载 (Time series)       │  磁盘使用率 (Bar/Pie)        │
│  [1/5/15 分钟 + 核心数对比]    │  [按挂载点]                  │
├─────────────────────────────────────────────────────────────┤
│  磁盘 IO (Time series)        │  网络流量 (Time series)      │
│  [读写速率 + IOPS + 延迟]      │  [接收/发送 + 丢包率]        │
├─────────────────────────────────────────────────────────────┤
│  TCP 连接 (Time series)       │  进程状态 (Stat)             │
│  [连接数 + 重传率 + TIME_WAIT] │  [运行/阻塞]                 │
├─────────────────────────────────────────────────────────────┤
│  文件描述符 (Gauge)           │  熵池 (Gauge)                │
│  [使用率]                     │  [可用位数]                  │
├─────────────────────────────────────────────────────────────┤
│  压力监控 (Time series)       │  告警列表 (Table)            │
│  [CPU/IO/内存压力]            │  [最近告警]                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔗 参考资源

- [Node Exporter GitHub](https://github.com/prometheus/node_exporter)
- [Prometheus 官方文档](https://prometheus.io/docs/)
- [Grafana 官方文档](https://grafana.com/docs/)
- [Awesome Prometheus Dashboards](https://grafana.com/grafana/dashboards)
- [Linux 性能监控](https://www.brendangregg.com/linuxperf.html)

---

**维护者：** OpenClaw 子节点 1  
**最后更新：** 2026-03-23  
**状态：** ✅ 完整
