# Linux 系统监控指标全集

_基于 Node Exporter 的完整系统监控指标_

**版本：** 1.0  
**更新日期：** 2026-03-23

---

## 📊 指标分类总览

| 分类 | 指标数量 | 关键指标 |
|------|---------|---------|
| **CPU** | 10+ | 使用率、负载、温度 |
| **内存** | 15+ | 使用率、Swap、缓存 |
| **磁盘** | 25+ | 使用率、IO、读写 |
| **网络** | 20+ | 流量、丢包、错误 |
| **系统** | 15+ | 进程、连接、时间 |
| **硬件** | 10+ | 温度、风扇、电源 |

---

## 🔴 CPU 指标

### 核心指标

| 指标名 | 类型 | 说明 | 单位 |
|--------|------|------|------|
| `node_cpu_seconds_total` | Counter | CPU 各模式累计时间 | 秒 |
| `node_load1` | Gauge | 1 分钟平均负载 | - |
| `node_load5` | Gauge | 5 分钟平均负载 | - |
| `node_load15` | Gauge | 15 分钟平均负载 | - |
| `node_cpu_frequency_hertz` | Gauge | CPU 频率 | Hz |
| `node_cpu_frequency_max_hertz` | Gauge | CPU 最大频率 | Hz |
| `node_cpu_frequency_min_hertz` | Gauge | CPU 最小频率 | Hz |
| `node_cpu_guest_seconds_total` | Counter | 虚拟化 CPU 时间 | 秒 |
| `node_cpu_scaling_frequency_hertz` | Gauge | CPU 缩放频率 | Hz |
| `node_cpu_scaling_frequency_max_hertz` | Gauge | CPU 缩放最大频率 | Hz |

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
| `guest` | 虚拟机时间 |

### 常用查询

```promql
# CPU 使用率（按核心）
100 - (avg by(instance, cpu) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# CPU 总使用率
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# CPU 各模式占比
avg by(instance, mode) (rate(node_cpu_seconds_total[5m])) * 100

# 负载与 CPU 核心数比率
node_load1 / count by(instance) (node_cpu_seconds_total{mode="idle"})

# CPU 频率使用率
node_cpu_frequency_hertz / node_cpu_frequency_max_hertz * 100
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
```

---

## 🟡 内存指标

### 核心指标

| 指标名 | 类型 | 说明 | 单位 |
|--------|------|------|------|
| `node_memory_MemTotal_bytes` | Gauge | 总物理内存 | 字节 |
| `node_memory_MemFree_bytes` | Gauge | 空闲内存 | 字节 |
| `node_memory_MemAvailable_bytes` | Gauge | 可用内存 | 字节 |
| `node_memory_Buffers_bytes` | Gauge | 内核缓冲区 | 字节 |
| `node_memory_Cached_bytes` | Gauge | 页面缓存 | 字节 |
| `node_memory_SwapTotal_bytes` | Gauge | 总交换空间 | 字节 |
| `node_memory_SwapFree_bytes` | Gauge | 空闲交换空间 | 字节 |
| `node_memory_SwapCached_bytes` | Gauge | 交换缓存 | 字节 |
| `node_memory_Active_bytes` | Gauge | 活跃内存 | 字节 |
| `node_memory_Inactive_bytes` | Gauge | 不活跃内存 | 字节 |
| `node_memory_Active_anon_bytes` | Gauge | 活跃匿名内存 | 字节 |
| `node_memory_Inactive_anon_bytes` | Gauge | 不活跃匿名内存 | 字节 |
| `node_memory_Active_file_bytes` | Gauge | 活跃文件缓存 | 字节 |
| `node_memory_Inactive_file_bytes` | Gauge | 不活跃文件缓存 | 字节 |
| `node_memory_Unevictable_bytes` | Gauge | 不可回收内存 | 字节 |
| `node_memory_Mlocked_bytes` | Gauge | 锁定内存 | 字节 |
| `node_memory_Dirty_bytes` | Gauge | 待写入内存 | 字节 |
| `node_memory_Writeback_bytes` | Gauge | 正在写入内存 | 字节 |
| `node_memory_KernelStack_bytes` | Gauge | 内核栈 | 字节 |
| `node_memory_PageTables_bytes` | Gauge | 页表 | 字节 |
| `node_memory_Committed_AS_bytes` | Gauge | 承诺内存 | 字节 |
| `node_memory_VmallocTotal_bytes` | Gauge | 虚拟内存总计 | 字节 |
| `node_memory_VmallocUsed_bytes` | Gauge | 已用虚拟内存 | 字节 |
| `node_memory_Slab_bytes` | Gauge | 内核 SLAB 缓存 | 字节 |
| `node_memory_SReclaimable_bytes` | Gauge | 可回收 SLAB | 字节 |
| `node_memory_SUnreclaim_bytes` | Gauge | 不可回收 SLAB | 字节 |

### 常用查询

```promql
# 内存使用率
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# 已用内存
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes

# 交换空间使用率
(1 - (node_memory_SwapFree_bytes / node_memory_SwapTotal_bytes)) * 100

# 缓存使用率
(node_memory_Cached_bytes / node_memory_MemTotal_bytes) * 100

# 活跃内存占比
(node_memory_Active_bytes / node_memory_MemTotal_bytes) * 100

# 内存压力（脏页比例）
(node_memory_Dirty_bytes / node_memory_MemTotal_bytes) * 100
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

- alert: HighSwapUsage
  expr: (1 - (node_memory_SwapFree_bytes / node_memory_SwapTotal_bytes)) * 100 > 50
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "高 Swap 使用率 ({{ $value }}%)"
    description: "实例 {{ $labels.instance }} 的 Swap 使用率超过 50%"

- alert: LowMemoryAvailable
  expr: node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100 < 10
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "内存严重不足 ({{ $value }}%)"
    description: "实例 {{ $labels.instance }} 可用内存低于 10%"
```

---

## 🔵 磁盘指标

### 文件系统指标

| 指标名 | 类型 | 说明 | 单位 |
|--------|------|------|------|
| `node_filesystem_size_bytes` | Gauge | 文件系统总大小 | 字节 |
| `node_filesystem_avail_bytes` | Gauge | 可用空间 | 字节 |
| `node_filesystem_free_bytes` | Gauge | 空闲空间 | 字节 |
| `node_filesystem_files` | Gauge | 总文件节点数 | 个 |
| `node_filesystem_files_free` | Gauge | 空闲文件节点数 | 个 |
| `node_filesystem_mount_info` | Gauge | 挂载信息 | - |
| `node_filesystem_device_error` | Gauge | 设备错误 | - |
| `node_filesystem_readonly` | Gauge | 只读状态 | - |

### 磁盘 IO 指标

| 指标名 | 类型 | 说明 | 单位 |
|--------|------|------|------|
| `node_disk_read_bytes_total` | Counter | 读取总量 | 字节 |
| `node_disk_written_bytes_total` | Counter | 写入总量 | 字节 |
| `node_disk_reads_completed_total` | Counter | 读取次数 | 次 |
| `node_disk_writes_completed_total` | Counter | 写入次数 | 次 |
| `node_disk_read_time_seconds_total` | Counter | 读取耗时 | 秒 |
| `node_disk_write_time_seconds_total` | Counter | 写入耗时 | 秒 |
| `node_disk_io_time_seconds_total` | Counter | IO 总时间 | 秒 |
| `node_disk_io_time_weighted_seconds_total` | Counter | 加权 IO 时间 | 秒 |
| `node_disk_io_now` | Gauge | 当前 IO 数 | 个 |
| `node_disk_reads_merged_total` | Counter | 合并读取数 | 次 |
| `node_disk_writes_merged_total` | Counter | 合并写入数 | 次 |
| `node_disk_flush_requests_total` | Counter | 刷新请求数 | 次 |
| `node_disk_flush_requests_time_seconds_total` | Counter | 刷新耗时 | 秒 |
| `node_disk_discards_completed_total` | Counter | 丢弃操作数 | 次 |
| `node_disk_discarded_sectors_total` | Counter | 丢弃扇区数 | 扇区 |

### 常用查询

```promql
# 磁盘使用率
(1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100

# 磁盘 IO 使用率
rate(node_disk_io_time_seconds_total[5m]) * 100

# 读取速率 (MB/s)
rate(node_disk_read_bytes_total[5m]) / 1024 / 1024

# 写入速率 (MB/s)
rate(node_disk_written_bytes_total[5m]) / 1024 / 1024

# 平均读取延迟 (ms)
rate(node_disk_read_time_seconds_total[5m]) / rate(node_disk_reads_completed_total[5m]) * 1000

# 平均写入延迟 (ms)
rate(node_disk_write_time_seconds_total[5m]) / rate(node_disk_writes_completed_total[5m]) * 1000

# IOPS
rate(node_disk_reads_completed_total[5m]) + rate(node_disk_writes_completed_total[5m])
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
```

---

## 🟢 网络指标

### 核心指标

| 指标名 | 类型 | 说明 | 单位 |
|--------|------|------|------|
| `node_network_receive_bytes_total` | Counter | 接收总量 | 字节 |
| `node_network_transmit_bytes_total` | Counter | 发送总量 | 字节 |
| `node_network_receive_packets_total` | Counter | 接收包数 | 个 |
| `node_network_transmit_packets_total` | Counter | 发送包数 | 个 |
| `node_network_receive_drop_total` | Counter | 接收丢包数 | 个 |
| `node_network_transmit_drop_total` | Counter | 发送丢包数 | 个 |
| `node_network_receive_errs_total` | Counter | 接收错误数 | 个 |
| `node_network_transmit_errs_total` | Counter | 发送错误数 | 个 |
| `node_network_receive_fifo_total` | Counter | FIFO 错误数 | 个 |
| `node_network_transmit_fifo_total` | Counter | 发送 FIFO 错误 | 个 |
| `node_network_receive_frame_total` | Counter | 帧错误数 | 个 |
| `node_network_receive_compressed_total` | Counter | 压缩包数 | 个 |
| `node_network_transmit_carrier_total` | Counter | 载波错误数 | 个 |
| `node_network_receive_multicast_total` | Counter | 组播包数 | 个 |
| `node_network_transmit_colls_total` | Counter | 冲突数 | 个 |
| `node_network_up` | Gauge | 网卡状态 | - |
| `node_network_speed_bytes` | Gauge | 网卡速度 | 字节/秒 |
| `node_network_mtu_bytes` | Gauge | MTU | 字节 |

### 常用查询

```promql
# 网络接收速率 (MB/s)
sum by(instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m])) / 1024 / 1024

# 网络发送速率 (MB/s)
sum by(instance) (rate(node_network_transmit_bytes_total{device!="lo"}[5m])) / 1024 / 1024

# 网络丢包率（接收）
sum by(instance) (rate(node_network_receive_drop_total[5m])) / sum by(instance) (rate(node_network_receive_packets_total[5m])) * 100

# 网络丢包率（发送）
sum by(instance) (rate(node_network_transmit_drop_total[5m])) / sum by(instance) (rate(node_network_transmit_packets_total[5m])) * 100

# 网络错误率
sum by(instance) (rate(node_network_receive_errs_total[5m]) + rate(node_network_transmit_errs_total[5m])) / sum by(instance) (rate(node_network_receive_packets_total[5m]) + rate(node_network_transmit_packets_total[5m])) * 100

# 网卡状态
node_network_up{device!="lo"}
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

## 🟣 系统指标

### 进程指标

| 指标名 | 类型 | 说明 | 单位 |
|--------|------|------|------|
| `node_procs_running` | Gauge | 运行中进程数 | 个 |
| `node_procs_blocked` | Gauge | 阻塞进程数 | 个 |
| `node_processes_state` | Gauge | 各状态进程数 | 个 |
| `node_processes_pids` | Gauge | 进程 PID 列表 | - |

### 连接指标

| 指标名 | 类型 | 说明 | 单位 |
|--------|------|------|------|
| `node_netstat_Tcp_CurrEstab` | Gauge | 当前 TCP 连接数 | 个 |
| `node_netstat_Tcp_ActiveOpens` | Counter | TCP 主动打开数 | 个 |
| `node_netstat_Tcp_PassiveOpens` | Counter | TCP 被动打开数 | 个 |
| `node_netstat_Tcp_RetransSegs` | Counter | TCP 重传段数 | 个 |
| `node_netstat_Tcp_InSegs` | Counter | TCP 接收段数 | 个 |
| `node_netstat_Tcp_OutSegs` | Counter | TCP 发送段数 | 个 |
| `node_netstat_Udp_InDatagrams` | Counter | UDP 接收数据报 | 个 |
| `node_netstat_Udp_OutDatagrams` | Counter | UDP 发送数据报 | 个 |
| `node_sockstat_TCP_alloc` | Gauge | TCP 分配套接字 | 个 |
| `node_sockstat_TCP_inuse` | Gauge | TCP 使用套接字 | 个 |
| `node_sockstat_TCP_time_wait` | Gauge | TCP TIME_WAIT 数 | 个 |
| `node_sockstat_sockets_used` | Gauge | 总套接字使用数 | 个 |

### 时间指标

| 指标名 | 类型 | 说明 | 单位 |
|--------|------|------|------|
| `node_time_seconds` | Gauge | 系统时间 | 秒 |
| `node_boot_time_seconds` | Gauge | 启动时间 | 秒 |
| `node_clock_synced` | Gauge | 时钟同步状态 | - |
| `node_ntp_offset_seconds` | Gauge | NTP 偏移 | 秒 |
| `node_timex_loop_time_constant` | Gauge | PLL 时间常数 | - |
| `node_timex_maxerror_seconds` | Gauge | 最大误差 | 秒 |
| `node_timex_estimated_error_seconds` | Gauge | 估计误差 | 秒 |
| `node_timex_offset_seconds` | Gauge | 时间偏移 | 秒 |
| `node_timex_frequency_adjustment` | Gauge | 频率调整 | - |
| `node_timex_tick_seconds` | Gauge | 时钟滴答间隔 | 秒 |

### 其他系统指标

| 指标名 | 类型 | 说明 | 单位 |
|--------|------|------|------|
| `node_filefd_allocated` | Gauge | 已分配文件描述符 | 个 |
| `node_filefd_maximum` | Gauge | 最大文件描述符 | 个 |
| `node_context_switches_total` | Counter | 上下文切换总数 | 次 |
| `node_interrupts_total` | Counter | 中断总数 | 次 |
| `node_entropy_available_bits` | Gauge | 熵池可用位数 | 位 |
| `node_entropy_pool_size_bits` | Gauge | 熵池大小 | 位 |
| `node_cooling_device_cur_state` | Gauge | 冷却设备当前状态 | - |
| `node_cooling_device_max_state` | Gauge | 冷却设备最大状态 | - |

### 常用查询

```promql
# 运行时间（天）
(node_time_seconds - node_boot_time_seconds) / 86400

# 运行中进程数
node_procs_running

# 阻塞进程数
node_procs_blocked

# TCP 连接数
node_netstat_Tcp_CurrEstab

# TCP 重传率
rate(node_netstat_Tcp_RetransSegs[5m]) / rate(node_netstat_Tcp_OutSegs[5m]) * 100

# 文件描述符使用率
node_filefd_allocated / node_filefd_maximum * 100

# 上下文切换速率
rate(node_context_switches_total[5m])

# 熵池可用率
node_entropy_available_bits / node_entropy_pool_size_bits * 100

# NTP 时间偏移（毫秒）
node_ntp_offset_seconds * 1000
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

- alert: SystemClockNotSynced
  expr: node_clock_synced == 0
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "系统时钟未同步"
    description: "实例 {{ $labels.instance }} 的系统时钟未与 NTP 同步"
```

---

## 🟤 硬件指标

### 温度指标

| 指标名 | 类型 | 说明 | 单位 |
|--------|------|------|------|
| `node_hwmon_temp_celsius` | Gauge | 温度传感器读数 | 摄氏度 |
| `node_hwmon_temp_max_celsius` | Gauge | 最高温度阈值 | 摄氏度 |
| `node_hwmon_temp_crit_celsius` | Gauge | 临界温度阈值 | 摄氏度 |
| `node_hwmon_temp_label` | Gauge | 温度传感器标签 | - |

### 风扇指标

| 指标名 | 类型 | 说明 | 单位 |
|--------|------|------|------|
| `node_hwmon_fan_rpm` | Gauge | 风扇转速 | RPM |
| `node_hwmon_fan_min_rpm` | Gauge | 最小风扇转速 | RPM |
| `node_hwmon_fan_max_rpm` | Gauge | 最大风扇转速 | RPM |
| `node_hwmon_fan_alarm` | Gauge | 风扇告警状态 | - |
| `node_hwmon_fan_beep` | Gauge | 风扇蜂鸣状态 | - |

### 电压指标

| 指标名 | 类型 | 说明 | 单位 |
|--------|------|------|------|
| `node_hwmon_voltage_volt` | Gauge | 电压读数 | 伏特 |
| `node_hwmon_voltage_min_volt` | Gauge | 最小电压阈值 | 伏特 |
| `node_hwmon_voltage_max_volt` | Gauge | 最大电压阈值 | 伏特 |
| `node_hwmon_voltage_alarm` | Gauge | 电压告警状态 | - |

### 电源指标

| 指标名 | 类型 | 说明 | 单位 |
|--------|------|------|------|
| `node_hwmon_power_watt` | Gauge | 功率读数 | 瓦特 |
| `node_hwmon_power_max_watt` | Gauge | 最大功率阈值 | 瓦特 |
| `node_hwmon_power_avg_watt` | Gauge | 平均功率 | 瓦特 |
| `node_hwmon_power_alarm` | Gauge | 功率告警状态 | - |
| `node_power_supply_online` | Gauge | 电源在线状态 | - |

### 常用查询

```promql
# CPU 温度
node_hwmon_temp_celsius{chip="platform_coretemp_0",sensor="temp1"}

# 最高温度
max(node_hwmon_temp_celsius)

# 风扇转速
node_hwmon_fan_rpm

# 电压
node_hwmon_voltage_volt

# 电源状态
node_power_supply_online

# 功率消耗
node_hwmon_power_watt
```

### 告警规则

```yaml
- alert: HighTemperature
  expr: node_hwmon_temp_celsius > 80
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "高温告警 ({{ $value }}°C)"
    description: "实例 {{ $labels.instance }} 的温度超过 80°C"

- alert: CriticalTemperature
  expr: node_hwmon_temp_celsius > 90
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "严重高温告警 ({{ $value }}°C)"
    description: "实例 {{ $labels.instance }} 的温度超过 90°C，可能硬件损坏"

- alert: FanFailure
  expr: node_hwmon_fan_alarm == 1
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "风扇故障"
    description: "实例 {{ $labels.instance }} 的风扇故障"

- alert: PowerSupplyOffline
  expr: node_power_supply_online == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "电源离线"
    description: "实例 {{ $labels.instance }} 的电源已离线"
```

---

## 📊 Grafana Dashboard 配置

### 推荐面板布局

```
┌─────────────────────────────────────────────────────────────┐
│  系统概览 (Stat)                                            │
│  运行时间 | 负载 | 进程数 | 连接数 | 文件描述符              │
├─────────────────────────────────────────────────────────────┤
│  CPU 使用率 (Time series)    │  内存使用率 (Time series)    │
│  [按核心拆分]                │  [含 Swap]                   │
├─────────────────────────────────────────────────────────────┤
│  系统负载 (Time series)       │  磁盘使用率 (Pie/Bar)        │
│  [1/5/15 分钟]                │  [按挂载点]                  │
├─────────────────────────────────────────────────────────────┤
│  网络流量 (Time series)       │  磁盘 IO (Time series)       │
│  [接收/发送]                 │  [读写速率/IOPS]             │
├─────────────────────────────────────────────────────────────┤
│  进程状态 (Stat)              │  TCP 连接 (Time series)       │
│  [运行/阻塞/休眠]            │  [连接数/重传率]             │
├─────────────────────────────────────────────────────────────┤
│  温度监控 (Gauge)             │  告警列表 (Table)            │
│  [CPU/主板/硬盘]             │  [最近告警]                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔗 参考资源

- [Node Exporter GitHub](https://github.com/prometheus/node_exporter)
- [Prometheus 官方文档](https://prometheus.io/docs/)
- [Grafana 官方文档](https://grafana.com/docs/)
- [Awesome Prometheus Dashboards](https://grafana.com/grafana/dashboards)

---

**维护者：** OpenClaw 子节点 1  
**最后更新：** 2026-03-23  
**状态：** ✅ 完整
