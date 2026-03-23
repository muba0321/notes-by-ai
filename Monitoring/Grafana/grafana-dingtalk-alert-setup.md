# Grafana 钉钉告警配置指南

_配置钉钉机器人接收监控告警通知_

**创建日期：** 2026-03-23  
**状态：** ✅ 已配置联系人

---

## 📱 钉钉机器人配置

### 1. 创建钉钉机器人

1. 打开钉钉群 → 群设置 → 智能群助手
2. 添加机器人 → 自定义
3. 设置机器人名称：`监控告警`
4. 获取 Webhook URL

**Webhook 格式：**
```
https://oapi.dingtalk.com/robot/send?access_token=YOUR_ACCESS_TOKEN
```

### 2. 安全设置（三选一）

| 方式 | 说明 | 推荐度 |
|------|------|--------|
| **自定义关键词** | 消息包含"告警"即可 | ⭐⭐⭐ |
| **加签** | 使用 HMAC-SHA256 签名 | ⭐⭐⭐⭐ |
| **IP 地址** | 限制来源 IP | ⭐⭐ |

**推荐配置：** 自定义关键词 `告警`

---

## ⚙️ Grafana 配置

### 已创建配置

| 配置项 | 值 |
|--------|-----|
| **联系人名称** | DingTalk |
| **类型** | dingding |
| **UID** | afguz68weawaof |
| **状态** | ✅ 已创建 |

### 配置位置

**Grafana UI:**
```
Alerting → Contact points → DingTalk
```

**API 路径：**
```
/api/v1/provisioning/contact-points
```

---

## 🔔 告警规则配置

### 系统告警规则

| 告警名称 | 条件 | 持续时间 | 级别 |
|---------|------|---------|------|
| **InstanceDown** | `up == 0` | 2 分钟 | 🔴 Critical |
| **HighCPUUsage** | CPU > 80% | 5 分钟 | 🟡 Warning |
| **HighMemoryUsage** | 内存 > 85% | 5 分钟 | 🟡 Warning |
| **HighDiskUsage** | 磁盘 > 85% | 10 分钟 | 🟡 Warning |

---

### 告警规则 YAML

```yaml
groups:
  - name: system_alerts
    rules:
      - alert: InstanceDown
        expr: up{job=~"node-.*"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "实例 {{ $labels.instance }} 宕机"
          description: "实例 {{ $labels.instance }} 已宕机超过 2 分钟"

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
```

---

## 📋 手动配置步骤（UI 方式）

### 步骤 1：更新钉钉 Webhook

1. 登录 Grafana：http://grafana.mubai.top
2. 进入 **Alerting** → **Contact points**
3. 点击 **DingTalk**
4. 编辑 URL，填入你的钉钉机器人 Webhook
5. 点击 **Test** 测试
6. 保存

### 步骤 2：创建告警规则

1. 进入 **Alerting** → **Alert rules**
2. 点击 **New alert rule**
3. 配置查询：
   - Data source: Prometheus
   - Query: `up{job=~"node-.*"} == 0`
4. 设置条件：
   - When: Last value
   - Is above: 0
5. 设置评估：
   - Folder: General
   - Group: system-alerts
   - Evaluate every: 1m
   - Evaluate for: 2m
6. 添加详情：
   - Summary: `实例 {{ $labels.instance }} 宕机`
   - Description: `实例 {{ $labels.instance }} 已宕机超过 2 分钟`
7. 添加标签：
   - severity: critical
8. 选择联系人：
   - DingTalk
9. 保存

---

## 🧪 测试告警

### 测试命令

```bash
# 测试钉钉联系人
curl -X POST 'http://localhost:3000/api/v1/provisioning/contact-points/test' \
  -H 'Content-Type: application/json' \
  -u 'admin:Grafana12345' \
  -d '{
    "name": "DingTalk",
    "type": "dingding",
    "settings": {
      "url": "YOUR_WEBHOOK_URL"
    }
  }'
```

### 触发测试告警

```bash
# 临时停止 node-exporter（测试用）
ssh root@38.246.245.39 "systemctl stop node-exporter"

# 等待 2-3 分钟，应该收到告警

# 恢复 node-exporter
ssh root@38.246.245.39 "systemctl start node-exporter"
```

---

## 📊 告警通知示例

### 钉钉消息格式

```
🚨 告警通知

实例 38.246.245.39:9100 宕机
实例 38.246.245.39:9100 已宕机超过 2 分钟

级别：critical
时间：2026-03-23 06:35:00
```

---

## ⚠️ 注意事项

### 钉钉限制

| 限制 | 值 |
|------|-----|
| 每分钟消息数 | 20 条 |
| 每个机器人 | 10 个群组 |
| 消息长度 | 20KB |

### 告警优化

1. **避免告警风暴**
   - 设置合理的 `group_wait` (30s)
   - 设置 `repeat_interval` (4h)

2. **分级告警**
   - Warning: 邮件/钉钉
   - Critical: 钉钉 + 电话

3. **静默规则**
   - 维护期间静默
   - 已知问题静默

---

## 🔗 相关文档

- [Grafana 告警文档](https://grafana.com/docs/grafana/latest/alerting/)
- [钉钉机器人文档](https://open.dingtalk.com/document/robots/custom-robot-access)
- [监控指标文档](./cicd-monitoring-metrics.md)
- [Linux 系统监控指标全集](./linux-monitoring-metrics-full.md)

---

**维护者：** OpenClaw 子节点 1  
**最后更新：** 2026-03-23
