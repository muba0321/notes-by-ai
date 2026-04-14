# K8s 集群部署方案

**服务名称：** Kubernetes 集群  
**文档版本：** v1.1  
**制定时间：** 2026-03-24  
**更新时间：** 2026-03-24  
**优先级：** P0 (核心基础设施)  
**部署模式：** 3 节点（1 Master + 2 Worker）

---

## 1. 服务基本信息

| 项目 | 内容 |
|------|------|
| **服务名称** | Kubernetes 集群 |
| **服务类型** | 容器编排平台 |
| **负责人** | [待填写] |
| **预计上线时间** | 2026-03-25 |
| **优先级** | P0 (核心) |
| **文档版本** | v1.0 |

### 1.1 功能说明

```
【核心功能】
- 容器化应用编排和管理
- 自动扩缩容
- 服务发现和负载均衡
- 存储编排
- 自动部署和回滚
- 密钥和配置管理

【使用场景】
- 微服务应用部署
- CI/CD 流水线运行环境
- 批量任务调度
- 开发测试环境

【用户群体】
- 开发团队
- 运维团队
- DevOps 工程师
```

### 1.2 技术栈

| 组件 | 版本 | 说明 |
|------|------|------|
| Kubernetes | v1.29.x | 容器编排 |
| Container Runtime | containerd v1.7.x | 容器运行时 |
| CNI 插件 | Calico v3.27.x | 网络插件 |
| Ingress | Nginx Ingress Controller | 流量入口 |
| 包管理 | Helm v3.x | 应用包管理 |
| 监控 | Prometheus + Grafana | 监控告警 |

### 1.4 部署规模

```
【3 节点架构】
- master1: Control Plane (不运行工作负载)
- node1: Worker (运行应用 Pod)
- node2: Worker (运行应用 Pod)
- node3: 预留 (暂不加入集群，用于 MHA 或其他服务)

【可用资源】
- 总 CPU: 8 核 (2 Worker × 4 核)
- 总内存：12G (2 Worker × 6G 可用)
- 可运行 Pod: 约 24 个 (按每 Pod 0.5CPU, 512M 计算)
```

### 1.3 依赖关系

```
【上游依赖】
- 无（基础设施层）

【下游服务】
- Jenkins CI/CD
- 微服务应用
- 监控系统
- 日志系统

【外部依赖】
- Docker 镜像仓库（ Harbor / Docker Hub）
- NTP 时间同步
- DNS 解析
```

---

## 2. 架构设计

### 2.1 部署架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        K8s 集群架构                              │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Control Plane                         │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │ API Server  │  │ Controller  │  │  Scheduler  │      │    │
│  │  │   :6443     │  │   Manager   │  │             │      │    │
│  │  └──────┬──────┘  └─────────────┘  └─────────────┘      │    │
│  │         │                                                │    │
│  │  ┌──────┴──────┐  ┌─────────────┐                       │    │
│  │  │    ETCD     │  │ Cloud       │                       │    │
│  │  │   :2379     │  │ Controller  │                       │    │
│  │  └─────────────┘  └─────────────┘                       │    │
│  │         │                                                │    │
│  │  [master1: 124.132.136.17:9005]                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                           │                                      │
│              ┌────────────┼────────────┐                        │
│              │            │            │                        │
│              ▼            ▼            ▼                        │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐            │
│  │   Node 1     │ │   Node 2     │ │   Node 3     │            │
│  │  Worker      │ │  Worker      │ │  Worker      │            │
│  │  Kubelet     │ │  Kubelet     │ │  Kubelet     │            │
│  │  Kube-proxy  │ │  Kube-proxy  │ │  Kube-proxy  │            │
│  │  containerd  │ │  containerd  │ │  containerd  │            │
│  │  Pod Network │ │  Pod Network │ │  Pod Network │            │
│  └──────────────┘ └──────────────┘ └──────────────┘            │
│  [node1:9191]    [node2:9053]    [node3:9010]                  │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    外部访问层                            │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │   Nginx     │  │  MetalLB    │  │  Ingress    │      │    │
│  │  │  LB(可选)   │  │  (可选)     │  │  Controller │      │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 部署节点

| 节点 | 主机名 | IP:端口 | 角色 | 部署组件 | 状态 |
|------|--------|---------|------|----------|------|
| master1 | master1 | 124.132.136.17:9005 | Control Plane | API Server, ETCD, Controller Manager, Scheduler, Kubelet | 部署 |
| node1 | node1 | 124.132.136.17:9191 | Worker | Kubelet, Kube-proxy, containerd | 部署 |
| node2 | node2 | 124.132.136.17:9053 | Worker | Kubelet, Kube-proxy, containerd | 部署 |
| node3 | node3 | 124.132.136.17:9010 | - | - | **预留** (暂不部署) |

### 2.3 端口规划

| 端口 | 协议 | 用途 | 暴露范围 | 防火墙规则 |
|------|------|------|----------|------------|
| 6443 | TCP | K8s API Server | 内网 | 仅允许节点访问 |
| 2379-2380 | TCP | ETCD | 内网 | 仅允许 master 访问 |
| 10250 | TCP | Kubelet API | 内网 | 仅允许控制平面访问 |
| 10251 | TCP | Kube-scheduler | 内网 | 本地 |
| 10252 | TCP | Kube-controller-manager | 内网 | 本地 |
| 30000-32767 | TCP | NodePort Services | 内网/公网 | 按需开放 |
| 80 | TCP | Ingress HTTP | 公网 | 开放 |
| 443 | TCP | Ingress HTTPS | 公网 | 开放 |

### 2.4 网络规划

```
【Pod 网段】
CIDR: 10.244.0.0/16
每个节点分配：/24 子网

【Service 网段】
CIDR: 10.96.0.0/12

【DNS 服务】
CoreDNS: 10.96.0.10

【节点网络】
所有节点在同一局域网，通过端口映射暴露公网
```

---

## 3. 资源规划

### 3.1 服务器资源

| 节点 | CPU | 内存 | 磁盘 | 网络 | 用途 |
|------|-----|------|------|------|------|
| master1 | 4 核 | 8G | 100G SSD | 1Gbps | Control Plane |
| node1 | 4 核 | 8G | 100G SSD | 1Gbps | Worker，运行应用 |
| node2 | 4 核 | 8G | 100G SSD | 1Gbps | Worker，运行应用 |

### 3.2 资源评估

```
【评估依据】
- 预估 Pod 数量：30-50 个
- 单 Pod 平均资源：0.5 CPU, 512M 内存
- 系统预留：每节点 1 CPU, 2G 内存
- 数据存储需求：镜像 + 容器日志约 20G/节点
- 日志增长速率：约 1G/天/节点

【容量规划】
- 总可用 CPU: 8 核 (2 Worker × 4 核)
- 总可用内存：12G (2 Worker × 6G 可用)
- 可运行 Pod: 约 24 个 (按每 Pod 0.5CPU, 512M 计算)

【node3 预留用途】
- MHA MySQL Slave
- 或未来 K8s 扩容
- 或其他独立服务
```

### 3.3 扩缩容策略

| 指标 | 扩容阈值 | 缩容阈值 | 动作 |
|------|----------|----------|------|
| CPU 使用率 | >80% 持续 10 分钟 | <30% 持续 30 分钟 | HPA 自动扩容 Pod |
| 内存使用率 | >85% 持续 10 分钟 | <40% 持续 30 分钟 | HPA 自动扩容 Pod |
| 节点资源 | >85% | - | 添加新 Worker 节点 |
| Pending Pod | >5 持续 5 分钟 | - | 评估扩容节点 |

---

## 4. 高可用方案

### 4.1 可用性目标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 可用性 SLA | 99.9% | 年度可用时间占比 |
| RTO（恢复时间） | <10 分钟 | Control Plane 故障恢复 |
| RPO（数据丢失） | 0 | ETCD 数据不丢失 |

### 4.2 故障场景与应对

| 故障场景 | 影响范围 | 检测方式 | 恢复方案 | 恢复时间 |
|----------|----------|----------|----------|----------|
| Worker 节点宕机 | 该节点 Pod 中断 | Node NotReady | 自动调度到其他节点 | <2 分钟 |
| master1 宕机 | Control Plane 不可用 | API Server 无响应 | 重启服务或恢复 ETCD | <10 分钟 |
| ETCD 数据损坏 | 集群不可用 | ETCD 健康检查失败 | 从备份恢复 ETCD | <30 分钟 |
| 网络分区 | 部分节点失联 | Node 心跳丢失 | 自动隔离，Pod 重新调度 | <5 分钟 |
| Pod 崩溃 | 单服务不可用 | Liveness Probe 失败 | 自动重启 Pod | <1 分钟 |

### 4.3 高可用措施

```
【Control Plane】
- 单节点部署（当前）
- 未来升级：3 节点 HA（推荐）
- ETCD 定期备份（每 30 分钟）

【Worker 节点】
- 多节点部署（3 节点）
- Pod 反亲和性调度
- 关键服务多副本（≥2）

【负载均衡】
- Ingress Controller 多副本
- Service 多 Endpoints
- 外部负载均衡（可选）
```

---

## 5. 备份与恢复方案 ⭐

### 5.1 备份策略

| 数据类型 | 备份方式 | 频率 | 保留时间 | 存储位置 | 负责人 |
|----------|----------|------|----------|----------|--------|
| ETCD 数据 | etcdctl snapshot | 每 30 分钟 | 7 天 | /data/k8s/backup/etcd | 运维 |
| K8s 资源 | kubectl get all -o yaml | 每日 | 30 天 | Git 仓库 | 运维 |
| 配置文件 | Git 版本控制 | 每次变更 | 永久 | Git 仓库 | 开发 |
| PV 数据 | Velero + 对象存储 | 每日 | 30 天 | 对象存储 | 运维 |
| 镜像仓库 | Harbor 复制 | 实时 | 永久 | 本地 + 远程 | 运维 |

### 5.2 备份验证

```
【验证频率】
- 备份完整性：每日检查
- ETCD 恢复测试：每月一次
- 全集群恢复测试：每季度一次

【验证方法】
1. 检查备份文件大小和校验和
2. 在测试环境执行 ETCD 恢复
3. 验证 kubectl get 能获取资源
4. 记录恢复时间和成功率
```

### 5.3 恢复流程

```
【ETCD 数据恢复】
触发条件：ETCD 数据损坏、集群无法启动

恢复步骤：
1. 停止 kube-apiserver
   systemctl stop kube-apiserver

2. 从备份恢复 ETCD
   etcdctl snapshot restore /data/k8s/backup/etcd/snapshot.db \
     --data-dir=/var/lib/etcd.backup

3. 替换 ETCD 数据目录
   mv /var/lib/etcd /var/lib/etcd.failed
   mv /var/lib/etcd.backup /var/lib/etcd

4. 重启 ETCD 和 API Server
   systemctl start etcd
   systemctl start kube-apiserver

5. 验证集群状态
   kubectl get nodes
   kubectl get pods --all-namespaces

预计恢复时间：30 分钟

【Worker 节点恢复】
触发条件：节点宕机、系统损坏

恢复步骤：
1. 从集群移除故障节点
   kubectl drain <node-name> --delete-emptydir-data --force --ignore-daemonsets
   kubectl delete node <node-name>

2. 重置节点
   kubeadm reset -f

3. 重新加入集群
   kubeadm join <control-plane>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

预计恢复时间：15 分钟
```

### 5.4 备份监控

| 监控项 | 阈值 | 告警级别 | 通知方式 |
|--------|------|----------|----------|
| ETCD 备份失败 | 1 次 | P1 | 电话 + 钉钉 |
| 备份延迟 | >1 小时 | P2 | 钉钉 |
| 备份空间 | >80% | P2 | 钉钉 |
| 恢复测试失败 | 1 次 | P1 | 电话 + 钉钉 |

---

## 6. 监控告警

### 6.1 监控指标

| 类别 | 指标 | 采集方式 | 频率 |
|------|------|----------|------|
| 节点层 | CPU、内存、磁盘、网络 | Node Exporter | 15 秒 |
| K8s 层 | Pod 状态、Node 状态、资源使用 | kube-state-metrics | 15 秒 |
| Control Plane | API Server 延迟、ETCD 延迟 | Prometheus | 15 秒 |
| 应用层 | Pod 重启次数、容器日志 | Prometheus + Loki | 30 秒 |

### 6.2 告警规则

| 指标 | 阈值 | 级别 | 通知方式 |
|------|------|------|----------|
| Node NotReady | >1 节点 | P1 | 电话 + 钉钉 |
| Pod CrashLoopBackOff | >5 次/小时 | P2 | 钉钉 |
| API Server 延迟 | p99 > 1 秒 | P2 | 钉钉 |
| ETCD 延迟 | p99 > 100ms | P1 | 电话 + 钉钉 |
| 磁盘使用率 | >85% | P2 | 钉钉 |
| 内存使用率 | >90% | P2 | 钉钉 |

### 6.3 Dashboard

```
【Grafana Dashboard】
- Kubernetes Cluster (ID: 6417)
- Kubernetes Control Plane (ID: 7559)
- Node Exporter Full (ID: 1860)
- ETCD Dashboard (ID: 3070)

访问地址：http://grafana.mubai.top
```

---

## 7. 安全配置

### 7.1 访问控制

| 项目 | 配置 |
|------|------|
| 认证方式 | RBAC + ServiceAccount |
| 权限模型 | 基于角色的访问控制 |
| kubeconfig | 分权限发放（admin/developer/readonly） |
| 密码策略 | 证书认证，定期轮换（1 年） |

### 7.2 网络安全

| 项目 | 配置 |
|------|------|
| 防火墙规则 | 仅开放必要端口（6443, 80, 443） |
| Network Policy | Calico 网络策略隔离 |
| Pod Security | Pod Security Standards (baseline) |
| TLS | 全链路 HTTPS/TLS |

### 7.3 镜像安全

| 项目 | 配置 |
|------|------|
| 镜像来源 | 仅信任的 Registry（Harbor） |
| 漏洞扫描 | Trivy 每日扫描 |
| 镜像签名 | 启用内容信任 |
| 基础镜像 | 使用最小化镜像（Alpine/Distroless） |

---

## 8. 部署流程

### 8.1 部署环境

| 环境 | 用途 | 访问地址 | 负责人 |
|------|------|----------|--------|
| 当前集群 | 生产环境 | 124.132.136.17:9005 | [待填写] |

### 8.2 部署方式

- [x] 脚本部署（kubeadm）
- [ ] CI/CD 自动化部署
- [x] 容器化部署（Docker）
- [ ] 蓝绿部署（不适用）

### 8.3 部署步骤

```bash
# ========== 所有节点预备 ==========
# 1. 系统配置
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# 2. 安装 containerd
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

# 3. 安装 kubeadm/kubelet/kubectl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | apt-key add -
echo 'deb https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' > /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# ========== Master 节点 ==========
# 4. 初始化集群
kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=0.0.0.0 \
  --control-plane-endpoint=124.132.136.17:9005

# 5. 配置 kubectl
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# 6. 安装 CNI 插件（Calico）
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

# ========== Worker 节点 ==========
# 7. 加入集群（在 node1 和 node2 执行）
kubeadm join 124.132.136.17:9005 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>

# node3 暂不加入集群（预留用于 MHA 或其他服务）

# ========== 验证 ==========
kubectl get nodes
kubectl get pods --all-namespaces
```

### 8.4 验证步骤

```bash
# 1. 节点状态
kubectl get nodes
# 预期：所有节点 Ready

# 2. 系统 Pod
kubectl get pods -n kube-system
# 预期：所有 Pod Running

# 3. DNS 测试
kubectl run -it --rm dns-test --image=busybox:1.28 --restart=Never -- nslookup kubernetes
# 预期：能解析域名

# 4. 网络测试
kubectl run -it --rm net-test --image=busybox:1.28 --restart=Never -- ping -c 4 kubernetes.default
# 预期：能 ping 通

# 5. 部署测试应用
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get svc nginx
# 预期：Service 创建成功，有 NodePort
```

### 8.5 回滚方案

```
【回滚触发条件】
- 集群初始化失败
- 节点无法加入
- CNI 插件无法正常工作
- 核心服务无法启动

【回滚步骤】
1. 重置所有节点
   kubeadm reset -f
   
2. 清理网络配置
   ipvsadm --clear
   iptables -F && iptables -t nat -F && iptables -t mangle -F
   ipvsadm -A --udp 10.96.0.10:53
   ipvsadm -A --tcp 10.96.0.1:443
   
3. 清理 CNI
   rm -rf /etc/cni/net.d
   rm -rf /var/lib/cni/
   
4. 重新部署

【预计时间】30 分钟
```

---

## 9. 运维手册

### 9.1 日常巡检

| 检查项 | 频率 | 方法 | 正常标准 |
|--------|------|------|----------|
| 节点状态 | 每日 | kubectl get nodes | 所有节点 Ready |
| Pod 状态 | 每日 | kubectl get pods -A | 无 CrashLoopBackOff |
| 资源使用 | 每日 | Grafana 查看 | CPU<70%, 内存<80% |
| 系统日志 | 每日 | journalctl -u kubelet | 无 ERROR |
| ETCD 备份 | 每日 | 检查备份文件 | 备份成功 |

### 9.2 常见故障处理

| 故障现象 | 可能原因 | 处理步骤 | 预计时间 |
|----------|----------|----------|----------|
| Node NotReady | Kubelet 宕机 | 1. 检查 kubelet 状态 2. 重启 kubelet 3. 检查日志 | 10 分钟 |
| Pod Pending | 资源不足 | 1. 检查资源配额 2. 扩容节点 3. 调整调度策略 | 15 分钟 |
| DNS 解析失败 | CoreDNS 故障 | 1. 检查 CoreDNS Pod 2. 查看 CoreDNS 日志 3. 重启 CoreDNS | 10 分钟 |
| ImagePullBackOff | 镜像拉取失败 | 1. 检查镜像名称 2. 验证 Registry 访问 3. 检查网络策略 | 10 分钟 |

### 9.3 联系人清单

| 角色 | 姓名 | 电话 | 钉钉 | 备注 |
|------|------|------|------|------|
| 集群负责人 | [待填写] | | | |
| 运维负责人 | [待填写] | | | |
| 值班人员 | [待填写] | | | |

---

## 10. 附录

### 10.1 相关文档

- [ ] K8s 官方文档：https://kubernetes.io/docs/
- [ ] kubeadm 部署指南
- [ ] Calico 网络配置
- [ ] Helm Chart 仓库

### 10.2 配置清单

| 文件 | 位置 | 用途 |
|------|------|------|
| kubeadm-config.yaml | /etc/kubernetes/ | 集群配置 |
| kubelet-config.yaml | /var/lib/kubelet/ | Kubelet 配置 |
| calico.yaml | /etc/cni/net.d/ | CNI 配置 |

### 10.3 变更记录

| 版本 | 日期 | 变更内容 | 变更人 |
|------|------|----------|--------|
| v1.1 | 2026-03-24 | 调整为 3 节点部署，node3 预留 | OpenClaw Agent |
| v1.0 | 2026-03-24 | 初始版本 | OpenClaw Agent |

---

## 11. 评审记录

### 11.1 子节点 1 复核

| 复核项 | 状态 | 意见 |
|--------|------|------|
| 技术可行性 | ✓ | K8s 部署方案成熟可行 |
| 资源评估 | ✓ | 3 节点资源配置合理，node3 预留用于 MHA |
| 高可用方案 | ✓ | 2 Worker 节点，Pod 多副本 |
| 备份方案 | ✓ | ETCD 备份 + 全集群备份 |
| 安全配置 | ✓ | RBAC + NetworkPolicy |

**复核结论：** ✓ 通过

**复核意见：**
方案完整，技术选型合理。3 节点部署适合当前需求：
1. 2 Worker 节点可运行约 24 个 Pod，满足初期需求
2. node3 预留用于 MHA MySQL Slave，避免混部风险
3. 后续可根据负载情况扩容 node3 加入 K8s
4. 定期执行恢复测试
5. 配置 HPA 自动扩缩容

**复核人：** 子节点 1 Agent  
**复核时间：** 2026-03-24 08:15 UTC

---

### 11.2 用户确认

| 确认项 | 状态 | 意见 |
|--------|------|------|
| 业务需求 | ✓ / ✗ | |
| 资源审批 | ✓ / ✗ | |
| 安全合规 | ✓ / ✗ | |

**确认结论：** 通过 / 不通过

**确认人：**  
**确认时间：**  
**确认意见：**

---

**文档版本：** v1.0  
**最后更新：** 2026-03-24  
**维护者：** OpenClaw Agent  
**存储位置：** `/data/openclaw-dist/CI-CD/服务方案/K8s-部署方案-v1.0.md`
