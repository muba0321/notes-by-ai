# Grafana 监控系统踩坑记录

**创建时间：** 2026-03-25  
**最后更新：** 2026-03-25 08:58 UTC  
**关联项目：** Grafana 监控系统  
**严重程度：** 中（已解决）

---

## 坑点汇总

### 🔴 严重问题

#### 1. 内网 IP 跨网段不可达

**问题描述：**  
配置 Prometheus 采集主节点指标时，使用内网 IP `10.0.118.4:9100`，但堡垒机无法访问该地址，target 状态持续 down。

**排查过程：**
```bash
# 堡垒机测试
timeout 3 bash -c 'echo > /dev/tcp/10.0.118.4/9100'
# 结果：失败

# 子节点 1 测试（同一网段）
timeout 3 bash -c 'echo > /dev/tcp/10.0.118.4/9100'
# 结果：成功

# Ping 测试（堡垒机→主节点）
ping -c 2 10.0.118.4
# 结果：100% packet loss

# 检查主节点网络
ip addr show | grep global
# 结果：inet 10.0.118.4/24（仅内网 IP）

# 检查主节点外网 IP
curl -s ifconfig.me
# 结果：38.246.245.32

# 外网 IP 测试
curl -s http://38.246.245.32:9100/metrics
# 结果：成功
```

**根本原因：**  
堡垒机（222.211.80.222）与主节点（10.0.118.4）不在同一网段，内网 IP 无法跨网段路由。主节点实际有外网 IP `38.246.245.32`，与子节点 1（38.246.245.39）在同一网段。

**解决方案：**  
使用外网 IP 替代内网 IP：
```yaml
# 错误配置
targets: ['10.0.118.4:9100']

# 正确配置
targets: ['38.246.245.32:9100']
```

**经验教训：**
- ✅ 配置前必须确认网络拓扑和路由可达性
- ✅ 跨网段通信优先使用外网 IP
- ✅ 使用 `ping` 和 `tcp port test` 双重验证连通性
- ✅ 记忆文件中应同时记录内网 IP 和外网 IP

**影响范围：** 监控数据采集  
**解决时间：** 30 分钟  
**预防措施：** 在网络拓扑文档中明确标注各节点的内外网 IP 及可达性

---

### 🟡 中等问题

#### 2. Grafana 页面加载失败

**问题描述：**  
访问 Grafana 时页面显示错误：
```
If you're seeing this Grafana has failed to load its application files
This could be caused by your reverse proxy settings.
```

**排查过程：**
```bash
# 检查 Grafana 状态
docker ps | grep grafana
# 结果：运行中

# 检查健康状态
curl -s http://localhost:3000/api/health
# 结果：正常

# 检查配置
docker exec grafana grep serve_from_sub_path /etc/grafana/grafana.ini
# 结果：;serve_from_sub_path = false（注释状态，默认 false）
```

**根本原因：**  
通过 Nginx 反向代理访问 Grafana 时，未启用 `serve_from_sub_path` 配置，导致静态资源路径错误。

**解决方案：**
```yaml
# docker-compose.yml
environment:
  - GF_SERVER_SERVE_FROM_SUB_PATH=true
```

```bash
# 重启生效
docker compose restart grafana
```

**经验教训：**
- ✅ 反向代理场景必须设置 `GF_SERVER_SERVE_FROM_SUB_PATH=true`
- ✅ Grafana 配置优先级：环境变量 > grafana.ini
- ✅ 修改配置后必须重启容器

**影响范围：** Grafana 访问  
**解决时间：** 15 分钟  
**预防措施：** 在部署方案中明确标注反向代理配置要求

---

#### 3. 节点选择器无选项

**问题描述：**  
Dashboard 顶部"节点"下拉菜单为空，无法切换节点。

**排查过程：**
```bash
# 检查变量查询
curl -s 'http://localhost:9090/api/v1/query?query=node_uname_info'
# 结果：空数组

# 检查 targets 状态
curl -s 'http://localhost:9090/api/v1/targets' | python3 -m json.tool | grep health
# 结果：部分 down

# 检查数据源
curl -s -u admin:admin123 http://localhost:3000/api/datasources
# 结果：空数组（数据源未配置）
```

**根本原因：**  
1. Prometheus 数据源未配置
2. targets 状态 down，无指标数据

**解决方案：**
```bash
# 1. 添加数据源
curl -X POST -u admin:admin123 -H 'Content-Type: application/json' \
  http://localhost:3000/api/datasources \
  -d '{"name":"Prometheus","type":"prometheus","url":"http://localhost:9090","access":"proxy","isDefault":true}'

# 2. 修复 targets
# 检查 node-exporter 状态
docker ps | grep node-exporter

# 检查网络连通性
timeout 3 bash -c 'echo > /dev/tcp/IP/9100'

# 重新加载 Prometheus 配置
docker exec prometheus kill -HUP 1

# 3. 等待指标采集（约 30s）
sleep 30

# 4. 验证
curl -s 'http://localhost:9090/api/v1/query?query=node_uname_info'
```

**经验教训：**
- ✅ Dashboard 导入前必须先配置数据源
- ✅ 节点选择器依赖 `node_uname_info` 指标，需确保 targets 正常
- ✅ 配置变更后需等待至少一个 scrape_interval（15s）

**影响范围：** Dashboard 功能  
**解决时间：** 20 分钟  
**预防措施：** 按顺序执行：数据源 → targets → Dashboard

---

#### 4. Grafana 容器权限错误

**问题描述：**  
Grafana 容器持续重启，日志显示：
```
mkdir: can't create directory '/var/lib/grafana/plugins': Permission denied
GF_PATHS_DATA='/var/lib/grafana' is not writable.
```

**排查过程：**
```bash
# 检查目录权限
ls -la /data/monitoring/grafana/
# 结果：drwxr-xr-x（755，容器内用户无写权限）

# 检查容器日志
docker logs grafana | tail -20
# 结果：大量 Permission denied
```

**根本原因：**  
宿主机挂载目录权限为 755，Grafana 容器内用户（默认 UID 472）无写权限。

**解决方案：**
```bash
# 方法 1：放宽权限（测试环境）
chmod -R 777 /data/monitoring/grafana/data

# 方法 2：修改所有者（生产环境推荐）
chown -R 472:472 /data/monitoring/grafana/data

# 重启容器
docker restart grafana
```

**经验教训：**
- ✅ Docker 挂载目录需提前设置正确权限
- ✅ 生产环境不应使用 777，应匹配容器用户 UID
- ✅ Grafana 容器默认 UID 为 472

**影响范围：** Grafana 服务可用性  
**解决时间：** 10 分钟  
**预防措施：** 在部署脚本中自动设置目录权限

---

### 🟢 轻微问题

#### 5. Prometheus 配置重载无效

**问题描述：**  
修改 `prometheus.yml` 后执行 `kill -HUP 1`，但 targets 未更新。

**排查过程：**
```bash
# 检查配置文件
cat /data/monitoring/prometheus/prometheus.yml
# 结果：已更新

# 检查容器内配置
docker exec prometheus cat /etc/prometheus/prometheus.yml
# 结果：未更新（挂载问题）
```

**根本原因：**  
配置文件挂载路径错误或未正确挂载。

**解决方案：**
```bash
# 确认挂载
docker inspect prometheus | grep -A5 prometheus.yml

# 正确挂载
volumes:
  - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml

# 重新加载
docker exec prometheus kill -HUP 1

# 验证
curl -s 'http://localhost:9090/api/v1/targets' | python3 -m json.tool
```

**经验教训：**
- ✅ 修改配置前确认挂载路径
- ✅ 重载后验证 targets 状态
- ✅ 必要时重启容器确保配置生效

**影响范围：** 配置更新  
**解决时间：** 5 分钟  
**预防措施：** 使用 `docker inspect` 验证挂载配置

---

#### 6. Node Exporter 端口冲突

**问题描述：**  
主节点启动 node_exporter 时报错：
```
listen tcp :9100: bind: address already in use
```

**排查过程：**
```bash
# 检查端口占用
ss -tlnp | grep 9100
# 结果：已有进程监听

# 查找进程
ps aux | grep node_exporter
# 结果：多个进程
```

**根本原因：**  
之前部署的 node_exporter 仍在运行，新进程无法绑定端口。

**解决方案：**
```bash
# 停止旧进程
pkill -9 node_exporter

# 等待端口释放
sleep 2

# 重新启动
nohup /usr/local/bin/node_exporter --web.listen-address=:9100 > /var/log/node_exporter.log 2>&1 &

# 验证
ss -tlnp | grep 9100
```

**经验教训：**
- ✅ 启动前检查端口占用
- ✅ 使用 systemd 管理进程避免重复启动
- ✅ 日志重定向便于排查问题

**影响范围：** 单节点监控  
**解决时间：** 5 分钟  
**预防措施：** 使用 systemd 服务管理 node_exporter

---

## 踩坑统计

| 严重程度 | 数量 | 平均解决时间 | 总耗时 |
|----------|------|--------------|--------|
| 🔴 严重 | 1 | 30 分钟 | 30 分钟 |
| 🟡 中等 | 3 | 15 分钟 | 45 分钟 |
| 🟢 轻微 | 2 | 5 分钟 | 10 分钟 |
| **合计** | **6** | **14 分钟** | **85 分钟** |

---

## 最佳实践总结

### 部署前检查

```bash
# 1. 网络连通性
timeout 3 bash -c 'echo > /dev/tcp/IP/9100' && echo '可达' || echo '不可达'

# 2. 端口占用
ss -tlnp | grep 9100

# 3. 目录权限
ls -la /data/monitoring/

# 4. Docker 资源
docker ps --filter "status=running" | wc -l
```

### 配置验证清单

- [ ] Prometheus targets 全部 up
- [ ] Grafana 数据源配置正确
- [ ] Dashboard 变量查询有结果
- [ ] 节点选择器显示所有节点
- [ ] 指标数据实时刷新
- [ ] 阈值告警颜色正确

### 故障排查流程

```
1. 检查服务状态 (docker ps)
   ↓
2. 查看日志 (docker logs)
   ↓
3. 验证网络 (ping/tcp test)
   ↓
4. 检查配置 (cat config)
   ↓
5. 测试 API (curl endpoint)
   ↓
6. 重新加载/重启服务
```

---

## 相关文档

- [Grafana 监控系统部署方案 v2.0](./服务方案/Grafana 监控系统部署方案-v2.0.md)
- [变更单 CHANGE-20260325-001](./变更单/CHANGE-20260325-001.md)
- [常规变更单模板](./常规变更单模板.md)

---

**维护者：** OpenClaw Agent  
**审查周期：** 每次监控系统变更后更新  
**最后审查：** 2026-03-25
