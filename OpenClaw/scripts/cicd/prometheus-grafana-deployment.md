# Prometheus + Grafana 部署记录

**部署日期：** 2026-03-23  
**部署位置：** 子节点 1 (38.246.245.39)  
**部署方式：** Docker 容器

---

## 📦 部署信息

### Prometheus

| 项目 | 值 |
|------|-----|
| **版本** | latest |
| **镜像** | prom/prometheus:latest |
| **容器 ID** | e0e92566687b |
| **数据目录** | /data/prometheus |
| **Web 端口** | 9090 |
| **状态** | ✅ 运行中 |

### Grafana

| 项目 | 值 |
|------|-----|
| **版本** | latest |
| **镜像** | grafana/grafana:latest |
| **容器 ID** | bec3ea273bee |
| **数据目录** | /data/grafana |
| **Web 端口** | 3000 |
| **状态** | ✅ 运行中 |

---

## 🌐 访问信息

### Prometheus

**访问地址：** http://38.246.245.39:9090

**功能：**
- 指标查询 (PromQL)
- 目标状态监控
- 告警规则管理

### Grafana

**访问地址：** http://38.246.245.39:3000

**登录信息：**
- 用户名：`admin`
- 密码：`Grafana12345`

⚠️ **首次登录后请立即修改密码！**

---

## 📊 已配置的监控目标

| 目标 | 端口 | 说明 |
|------|------|------|
| **Prometheus** | 9090 | 自监控 |
| **Jenkins** | 8080 | CI/CD 指标 |
| **Node Exporter** | 9100 | 系统指标（待安装） |

---

## 🚀 启动命令

### Prometheus
```bash
docker run -d \
  --name prometheus \
  --restart unless-stopped \
  -p 9090:9090 \
  -v /data/prometheus:/etc/prometheus \
  -v prometheus-data:/prometheus \
  prom/prometheus:latest
```

### Grafana
```bash
docker run -d \
  --name grafana \
  --restart unless-stopped \
  -p 3000:3000 \
  -v /data/grafana:/var/lib/grafana \
  -e GF_SECURITY_ADMIN_PASSWORD=Grafana12345 \
  grafana/grafana:latest
```

---

## 🔧 常用命令

### 查看状态
```bash
docker ps | grep -E 'prometheus|grafana'
```

### 查看日志
```bash
docker logs prometheus
docker logs grafana
```

### 重启
```bash
docker restart prometheus
docker restart grafana
```

### 停止
```bash
docker stop prometheus grafana
```

### 启动
```bash
docker start prometheus grafana
```

---

## 📈 Grafana Dashboard 推荐

### 导入 ID

| Dashboard | ID | 用途 |
|-----------|----|------|
| **Jenkins Overview** | 9964 | Jenkins 监控 |
| **Node Exporter Full** | 1860 | 系统监控 |
| **Prometheus Stats** | 2 | Prometheus 自身 |
| **Docker and System Monitoring** | 193 | Docker 容器监控 |

### 导入步骤

1. 登录 Grafana
2. 点击 **+** → **Import**
3. 输入 Dashboard ID
4. 选择 Prometheus 数据源
5. 点击 **Import**

---

## 🔌 数据源配置

### Prometheus 配置

**文件位置：** `/data/prometheus/prometheus.yml`

**当前配置：**
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

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
```

### Grafana 数据源

**已配置：**
- Prometheus: http://prometheus:9090

---

## 📋 下一步

### 1. 安装 Node Exporter（系统监控）

```bash
docker run -d \
  --name node-exporter \
  --restart unless-stopped \
  --net="host" \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /:/rootfs:ro \
  prom/node-exporter:latest \
  --path.procfs /host/proc \
  --path.sysfs /host/sys \
  --path.rootfs /rootfs
```

### 2. 配置告警

- 在 Prometheus 中配置告警规则
- 在 Grafana 中配置告警通知

### 3. 添加更多监控目标

- K8s 集群监控
- Harbor 监控
- SonarQube 监控

---

## ⚠️ 注意事项

### 安全配置

1. **修改默认密码** - Grafana 首次登录后立即修改
2. **配置 HTTPS** - 生产环境建议配置 SSL
3. **限制访问** - 配置防火墙只允许信任 IP
4. **定期备份** - 备份 /data/grafana 目录

### 性能优化

1. **保留策略** - 配置 Prometheus 数据保留时间
2. **存储优化** - 定期清理旧数据
3. **采集频率** - 根据需求调整 scrape_interval

### 备份策略

```bash
# 备份 Grafana 数据
tar czf grafana-backup-$(date +%Y%m%d).tar.gz /data/grafana

# 备份 Prometheus 配置
tar czf prometheus-backup-$(date +%Y%m%d).tar.gz /data/prometheus
```

---

## 🔧 故障排除

### Grafana 无法启动

```bash
# 检查权限
ls -la /data/grafana
chown -R 472:472 /data/grafana

# 查看日志
docker logs grafana
```

### Prometheus 无法抓取指标

```bash
# 检查目标状态
# 访问 http://IP:9090/targets

# 检查配置文件
docker exec prometheus cat /etc/prometheus/prometheus.yml
```

### 内存不足

```bash
# 查看容器内存使用
docker stats --no-stream

# 调整 Prometheus 内存限制
docker update --memory=1g prometheus
```

---

## 📚 相关文档

- [Prometheus 官方文档](https://prometheus.io/docs/)
- [Grafana 官方文档](https://grafana.com/docs/)
- [CI/CD 部署完整指南](./cicd-deployment-guide.md)
- [Jenkins 部署记录](./jenkins-deployment-record.md)

---

**部署者：** OpenClaw 子节点 1  
**最后更新：** 2026-03-23  
**状态：** ✅ 运行中
