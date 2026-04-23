# 项目索引

_所有已完成/运行中的项目详细配置_

---

## ✅ 运行中项目

### NetBox CMDB (SRE 基础数据源)
**状态：** 运行中 (方案 A 完成)
**位置：** 子节点1 (海外服务器)
**用途：** 虚拟机 + 服务业务信息 CMDB，SRE 基础数据来源

**部署信息：**
- 部署路径：`/data/netbox/` (子节点1)
- Docker Compose: netbox-docker 官方镜像
- 版本：NetBox v4.0.2
- 本地端口：8082
- 访问地址：http://cmdb.mubai.top
- Nginx 配置：`/etc/nginx/conf.d/cmdb.mubai.top.conf`

**登录信息：**
- 用户名：`admin`
- 密码：`NetBox@****`
- API Token: `****`

**数据模型 (方案 A)：**
```
虚拟机 (Virtualization)
├── Infrastructure 标签 (7 台) - 基础设施服务器
│   ├── ser280729144889 (堡垒机)
│   ├── ser493590849885 (主节点)
│   ├── ser154-12-54-207 (子节点1)
│   └── master1/node1/node2/node3 (K8s 集群)
└── Application 标签 (5 个) - 应用服务
    ├── netbox-cmdb
    ├── jenkins-ci
    ├── prometheus
    ├── grafana
    └── openclaw-gateway
```

**自定义字段：**
- Infrastructure: SSH 用户名/密码、外部 IP、内部 IP、SSH 端口、负责人
- Application: 管理员用户名/密码、外部访问、内部地址、服务负责人

**快速访问：**
- 基础设施：http://cmdb.mubai.top/virtualization/virtual-machines/?tag=infrastructure
- 应用服务：http://cmdb.mubai.top/virtualization/virtual-machines/?tag=application

**记录时间：** 2026-03-25
**更新时间：** 2026-03-25 (方案 A 迁移完成 - 设备→虚拟机，虚拟机→服务)

---

### 国内堡垒机 (OpenClaw 子节点)
**状态：** 运行中（Gateway 已启动）
**位置：** 国内机房
**角色：** 堡垒机/跳板机 + OpenClaw 子节点 + **监控/CI/CD 平台**

**连接信息：**
- 主机名：ser280729144889
- 公网 IP: 222.211.80.222
- SSH 端口：22
- SSH 用户：root
- SSH 密码：`***（见本地TOOLS.md）`
- Gateway 端口：18789
- 访问地址：http://222.211.80.222:18789

**系统信息：**
- 操作系统：Ubuntu 22.04 LTS
- 内核：5.15.0-30-generic
- CPU: 4 核 (Intel Xeon Platinum 8259CL @ 2.50GHz)
- 内存：3.8 GB
- 磁盘：30 GB

**OpenClaw 配置：**
- 版本：2026.3.22
- Gateway 模式：local (LAN 绑定)
- Token: `***`
- 模型：qwen3.5-plus (阿里云百炼)

**已安装 Skills：**
- skill-vetter (安全审查)
- self-improving-agent (持续改进)

**Docker 服务（/data/monitoring/）：**
- **Jenkins** (8080, 50000) - CI/CD
- **Prometheus** (9090) - 监控指标采集
- **Grafana** (3000) - 可视化 Dashboard
- **Node Exporter** (9100) - 节点指标采集

**Grafana Dashboard：**
- **Dashboard UID:** `linux-system-monitor`
- **访问路径:** `/d/linux-system-monitor/linux-system-monitor-dashboard`
- **监控指标:** CPU/内存/磁盘/网络/负载/进程/IOPS 等 16 个面板（中文界面）
- **特性:** 节点选择器、30 秒刷新、阈值告警
- **登录:** admin / admin123

**监控节点状态：**
| 节点 | 地址 | 状态 | 说明 |
|------|------|------|------|
| 子节点1 | localhost:9100 | ✅ up | 监控中心本地 |
| 堡垒机 | 222.211.80.222:9100 | ✅ up | 外网 IP 访问 |
| 主节点 | 38.246.245.32:9100 | ✅ up | 外网 IP 访问 |

**用途：**
- 国内机器访问跳板
- SSH 堡垒机
- 中转代理
- OpenClaw 子节点（国内访问）
- **监控与 CI/CD 平台**（2026-03-24 迁移）

**访问方式：**
- 国内用户：直接访问 `http://222.211.80.222:8080/9090/3000`
- 海外用户：通过子节点1 SSH 隧道代理（域名访问）
- Grafana 域名：http://grafana.mubai.top
- **子节点1 直连:** http://154.193.217.121:3000

**记录时间：** 2026-03-23
**更新时间：** 2026-03-25 (监控系统重构，子节点1 为监控中心)

---

### 前端代码仓库

**仓库：** https://github.com/muba0321/vue-portal  
**框架：** vue-element-admin v4.4.0  
**本地路径：** `/data/frontend/portal-vue/`

**部署状态：**
- ✅ 代码已推送到 GitHub
- ✅ Docker 容器化部署
- ✅ Nginx 反向代理（portal.mubai.top）

**访问方式：**
- 域名：http://portal.mubai.top
- 直连：http://154.193.217.121:8081

**默认账号：** admin / admin

---

### OpenClaw 主节点 (server)
**状态：** 运行中
**位置：** 当前主机
**角色：** 文档归档 + Git 推送

**连接信息：**
- 主机名：ser493590849885
- 内网 IP: 10.0.118.4
- SSH 用户：root
- SSH 密码：`***（见本地TOOLS.md）`

**系统信息：**
- 操作系统：Ubuntu 22.04.5 LTS

**Git 配置：**
- 仓库：https://github.com/muba0321/notes-by-ai
- 用户：muba0321
- 推送方式：HTTPS + Token

**记录时间：** 2026-03-23

---

### OpenClaw 子节点1 (海外流量转发)
**状态：** 运行中（Gateway 已启动）
**位置：** 海外服务器
**用途：** 海外流量转发代理 + Nginx 反向代理

**同步配置：**
- 已同步记忆文件：`projects.md`, `lessons.md`, `MEMORY.md`, `TOOLS.md`
- 文档路径规范：与主节点一致 (`/data/openclaw-dist/`)

**连接信息：**
- 主机名：ser154-12-54-207
- IP 地址：154.193.217.121
- SSH 端口：22
- SSH 用户：root
- Gateway 端口：18789
- 访问地址：http://154.193.217.121:18789

**凭证：**
- SSH 密码：`***（见本地TOOLS.md）`
- **⚠️ 安全提示：** 敏感信息仅存储在记忆文件中，不提交到 Git 仓库

**部署配置：**
- 部署脚本：/data/openclaw/openclaw-deploy/deploy-subagent.sh
- IP 配置文件：/data/openclaw/openclaw-deploy/ip-subagent.txt

**已安装服务：**
- OpenClaw 2026.3.13
- Docker + containerd
- **Nginx（反向代理）**

**Nginx 代理配置（/etc/nginx/conf.d/）：**
- `jenkins.mubai.top` → 127.0.0.1:18080 (SSH 隧道 → 堡垒机 8080)
- `promethus.mubai.top` → 127.0.0.1:19090 (SSH 隧道 → 堡垒机 9090)
- `grafana.mubai.top` → 127.0.0.1:13000 (SSH 隧道 → 堡垒机 3000)

**SSH 隧道（systemd 服务）：**
- 服务名：`ssh-tunnel.service`
- 状态：开机自启 + 自动重连
- 隧道端口：18080→8080, 19090→9090, 13000→3000
- 作用：加密跨境流量，避免防火墙内容篡改

**记录时间：** 2026-03-18
**更新时间：** 2026-03-24 (SSH 隧道配置完成)

---

## 📋 待办项目

（暂无）

---

## 🗄️ 已归档项目

（暂无）

---

## 🔧 Ansible 集群管理

**控制端：** 子节点1 (154.193.217.121)
**用途：** 批量管理局域网 4 台机器（K8s 集群）

### 被管机器清单

| 主机名 | 公网 IP:端口 | SSH 用户 | SSH 密码 | 用途 |
|--------|-------------|----------|----------|------|
| master1 | 124.132.136.17:9005 | root | `***（见本地TOOLS.md）` | K8s Master |
| node1 | 124.132.136.17:9191 | root | `***（见本地TOOLS.md）` | K8s Worker 1 |
| node2 | 124.132.136.17:9053 | root | `***（见本地TOOLS.md）` | K8s Worker 2 |
| node3 | 124.132.136.17:9010 | root | `***（见本地TOOLS.md）` | K8s Worker 3 |

**网络说明：**
- 所有机器在同一局域网，通过路由器端口映射暴露公网
- 通过 `IP:端口` 形式 SSH 访问
- 内网 IP 用于集群内部通信（已配置）

**内网 IP 配置：**
| 主机名 | 内网 IP | 用途 |
|--------|---------|------|
| master1 | 172.16.0.42 | K8s Control Plane |
| node1 | 172.16.0.98 | K8s Worker 1 |
| node2 | 172.16.0.40 | K8s Worker 2 |
| node3 | 172.16.0.x | 预留（MHA 部署） |

**⚠️ 安全提示：** SSH 密码仅存储在记忆文件中，不提交到 Git 仓库

**记录时间：** 2026-03-18  
**更新时间：** 2026-03-25 (内网 IP 配置完成)

---

## 🔌 已安装 Skills

### skill-vetter
**用途：** 安全审查其他 Skills
**安装位置：** 主节点 + 子节点1 + 堡垒机
**安装时间：** 2026-03-23
**风险等级：** 🟢 LOW
**说明：** 在安装其他 Skills 前进行安全审计，生成风险评估报告
**文档路径：** `/data/openclaw-dist/OpenClaw/Skills/skill-vetter.md`

### self-improving-agent
**用途：** 记录学习、错误、功能请求，促进持续改进
**安装位置：** 子节点1 + 堡垒机
**安装时间：** 2026-03-23
**风险等级：** 🟡 MEDIUM（需要人工监督）
**说明：** 日志驱动的自我改进，提升到核心文件前需人工批准
**文档路径：** `/data/openclaw-dist/OpenClaw/Skills/self-improving-agent.md`
**安全限制：**
- ❌ 禁止修改 `SOUL.md`
- ❌ 不安装自动 Hook
- 👁️ 提升前必须人工审核
- 📅 每周审查日志

---

## 📚 文档路径与 GitHub 同步

### 本地笔记仓库（Git）
- **路径：** `/data/openclaw-dist/`
- **用途：** 本地 Git 仓库，与 GitHub 同步
- **GitHub 仓库：** `https://github.com/muba0321/notes-by-ai`
- **同步节点：** 主节点 (server)

### 产品设计文档（子节点1 专用）

**工作流程：**
```
子节点1 (生成) → 主节点 (归档) → GitHub 备份
```

| 节点 | 角色 | 路径 |
|------|------|------|
| **子节点1** | 生成产品文档 | `/root/.openclaw/workspace/products/` |
| **主节点** | 归档 + Git 推送 | `/data/openclaw-dist/products/` |

**同步命令（主节点执行）：**
```bash
# 从子节点1 拉取文档
rsync -avz root@154.193.217.121:/root/.openclaw/workspace/products/ /data/openclaw-dist/products/

# 或者使用 scp + tar
ssh root@154.193.217.121 "tar czf - /root/.openclaw/workspace/products/*" | \
tar xzf - -C /data/openclaw-dist/products/
```

**目录结构：**
```
products/
├── README.md             # 目录说明 + 文档索引 + 工作流程
├── PRD/                  # 产品需求文档
│   └── template.md       # PRD 模板
├── research/             # 调研分析
│   ├── market/           # 市场调研
│   ├── competitors/      # 竞品分析
│   └── users/            # 用户研究
├── features/             # 功能设计
├── reviews/              # 评审记录
└── archive/              # 已归档产品
```

**创建时间：** 2026-03-23  
**文档规范：** 详见 `products/README.md`
- **结构：**
  ```
  /data/openclaw-dist/
  ├── k8s-ansible/             # K8s 集群部署文档
  │   ├── ansible-setup.md     # Ansible 安装配置
  │   ├── inventory.md         # 主机清单配置
  │   ├── playbooks.md         # Playbook 示例
  │   └── k8s-deploy.md        # K8s 部署指南
  ├── ansible/                 # Ansible 工具文档
  │   ├── index.md             # 工具首页
  │   ├── ansible-setup.md     # 安装配置
  │   ├── inventory.md         # 主机清单
  │   ├── playbooks.md         # Playbook 示例
  │   └── test-report.md       # 测试报告
  ├── OpenClaw/                # OpenClaw 相关文档
  │   ├── 服务端/              # 主节点部署
  │   ├── 子节点/              # 子节点部署
  │   └── 配置/                # 配置文件与说明 ⭐
  │       ├── CONFIG.md        # 配置说明总览
  │       ├── README.md        # 配置目录索引
  │       ├── ip-subagent.txt  # 子节点服务器列表
  │       └── lessons.md       # 踩坑记录
  ├── Wiki/                    # Wiki 相关文档
  ├── Nginx/                   # Nginx 相关文档
  ├── 归档/                    # 已归档文档
  ├── README.md
  └── .git/                    # Git 仓库
  ```

---

## 🔄 完整工作流（2026-03-25 新增）⭐

### 三仓库协同架构

```
┌─────────────────────────────────────────────────────────┐
│                    开发工作流                            │
└─────────────────────────────────────────────────────────┘

你 (Webchat)
   ↓
子节点1 (154.193.217.121)
   ↓
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│ product-designs  │────▶│   coder-api      │────▶│  notes-by-ai     │
│ (产品设计)        │     │ (代码仓库)        │     │ (文档仓库)        │
└──────────────────┘     └──────────────────┘     └──────────────────┘
```

### 仓库位置

| 仓库 | URL | 用途 | 本地路径 |
|------|-----|------|----------|
| **product-designs** | github.com/muba0321/product-designs | 产品 PRD/设计方案 | `/data/openclaw-dist/products/product-designs/` |
| **coder-api** | github.com/muba0321/coder-api | 代码实现/Docker | `/data/openclaw-dist/code/coder-api/` |
| **notes-by-ai** | github.com/muba0321/notes-by-ai | 文档记录/方案 | `/data/openclaw-dist/` |

### 完整工作流程

**开发新工具（如"用户管理系统"）：**

```
1. 产品设计
   → 创建 /data/openclaw-dist/products/product-designs/user-management/PRD.md
   → git commit → push → product-designs 仓库

2. 代码生成
   → aliyun-coder 读取 PRD
   → 调用阿里云 API 生成代码
   → 写入 /data/openclaw-dist/code/coder-api/user-management/
   → git commit → push → coder-api 仓库

3. 容器部署
   → Docker 打包镜像
   → 容器运行
   → 返回访问地址

4. 文档记录
   → 创建 /data/openclaw-dist/CI-CD/服务方案/用户管理系统.md
   → git commit → push → notes-by-ai 仓库
```

### 核心工具

| 工具 | 用途 | 配置 |
|------|------|------|
| **aliyun-coder** | 代码生成 | API Key: sk-sp-7e6f845b******** |
| **GitHub CLI** | Git 操作 | Token: ghp_*** |
| **Docker** | 容器打包 | 端口映射部署 |

### 测试验证

**测试项目：** test-api

- ✅ PRD 已创建：`/data/openclaw-dist/products/product-designs/test-api/PRD.md`
- ✅ 代码已生成：`/data/openclaw-dist/code/test-api/`
- ✅ 容器已部署：http://154.193.217.121:8001
- ✅ 文档已记录：`CI-CD/变更单/工作流测试报告 -20260325.md`

---

## 📋 CI/CD 文档规范（2026-03-24 新增）

### 文档目录结构

```
/data/openclaw-dist/CI-CD/
├── 服务部署方案规范模板.md      # 主模板（v2.0）
├── 常规变更单模板.md            # 简化版变更模板（v1.0）
├── 服务方案/                   # 新服务部署方案
│   ├── K8s-部署方案-v1.1.md    # K8s 集群部署方案（3 节点）
│   └── [服务名]-部署方案-vX.X.md
├── 变更单/                     # 常规变更单
│   └── CHANGE-YYYYMMDD-序号.md
├── 故障报告/                   # 故障处理报告
│   └── INCIDENT-YYYYMMDD-序号.md
└── 巡检记录/                   # 日常巡检记录
    └── YYYY-Www-巡检记录.md
```

### 文档使用规范

| 操作类型 | 使用模板 | 填写要求 | 评审流程 | 归档位置 |
|----------|----------|----------|----------|----------|
| **新服务部署** | 服务部署方案规范模板 | 完整填写 11 章 | 子节点1 复核 → 用户确认 | `服务方案/` |
| **常规变更** | 常规变更单模板 | 填写变更内容、回滚方案 | 子节点1 复核 → 用户确认 | `变更单/` |
| **故障处理** | 故障报告模板 | 故障原因、处理过程、预防措施 | 事后 review | `故障报告/` |
| **日常巡检** | 巡检记录模板 | 检查结果、异常记录 | 无需评审 | `巡检记录/` |

### 评审流程

```
┌─────────────────────────────────────────────────────────┐
│                    方案评审流程                          │
└─────────────────────────────────────────────────────────┘

1. 方案负责人填写模板
         ↓
2. 子节点1 复核（技术可行性、风险评估）
         ↓
3. 用户确认（业务需求、资源审批）
         ↓
4. 执行部署/变更
         ↓
5. 归档更新（Git 提交）
```

### Git 提交规范

```bash
# 新服务部署
git commit -m "feat: 添加 [服务名] 部署方案

- 服务架构设计
- 资源规划
- 备份恢复方案
- 监控告警配置

评审：子节点1 已复核，用户已确认"

# 常规变更
git commit -m "chore: [服务名] 配置变更

变更单号：CHANGE-YYYYMMDD-序号
变更内容：[简述]
评审：子节点1 已复核，用户已确认"

# 故障修复
git commit -m "fix: [服务名] 故障修复

故障单号：INCIDENT-YYYYMMDD-序号
故障原因：[简述]
预防措施：[简述]"
```

### 核心要求

1. **操作留痕** - 每次集群操作必须有文档记录
2. **双重确认** - 子节点1 复核 + 用户确认
3. **Git 归档** - 所有文档提交 GitHub 仓库
4. **备份恢复** - 方案必须包含详细备份恢复流程

### 现有文档清单

| 文档 | 位置 | 版本 | 状态 |
|------|------|------|------|
| 服务部署方案规范模板 | `CI-CD/服务部署方案规范模板.md` | v2.0 | 已评审 |
| 常规变更单模板 | `CI-CD/常规变更单模板.md` | v1.0 | 已评审 |
| K8s 部署方案 | `CI-CD/服务方案/K8s-部署方案-v1.1.md` | v1.1 | 子节点1 已复核 |

**记录时间：** 2026-03-24  
**维护者：** OpenClaw Agent

---

## 💬 群聊协作规范（2026-03-27 更新）⭐

### 角色分工

| 角色 | 职责 | 响应规则 |
|------|------|---------|
| **咨询助手** | 群聊任务协调者 | 只有被@或其他 Agent 请求时才介入 |
| **专业 Agent** | 特定领域专家 | 只有被@时才回答 |

### 咨询助手响应规则

| 情况 | 响应策略 |
|------|---------|
| 用户**不@任何人** | ❌ **沉默**（不主动回复） |
| 用户**@咨询助手** | ✅ 回答并协调 |
| 用户**@其他 Agent** | ❌ 沉默（让该 Agent 回答） |
| **其他 Agent 梳理方案后请求分配任务** | ✅ 回复并分配 |

### 专业 Agent 响应规则

| 情况 | 响应策略 |
|------|---------|
| 用户**@该 Agent** | ✅ 回答 |
| 用户**不@任何人** | ❌ 沉默（不主动回复） |
| 用户**@其他 Agent** | ❌ 沉默（让被@的 Agent 回答） |
| 需要协调其他 Agent 协助 | ✅ 用 `<at>` 点名 + `sessions_send` 通知 |

### 协作流程

```
群聊中：
1. 用户@特定 Agent → 该 Agent 回答
2. 该 Agent 需要其他 Agent 协助 → 用 <at> 点名 + sessions_send 通知
3. 需要任务分配/协调 → 咨询助手介入
4. 咨询助手汇总结果 → 回复用户

私聊中：
- 任何问题 → 正常响应
```

### 实现逻辑

```javascript
if (群聊 && 被@但不是@我) → NO_REPLY
if (群聊 && 未被@) → NO_REPLY（不主动回复）
if (群聊 && 被@我） → 响应
if (群聊 && 其他 Agent 请求协调) → 响应并分配
if (私聊) → 正常响应
```

### 专业 Agent 列表

- @产品经理
- @前端研发
- @开发助手

（咨询助手是协调者，不在专业 Agent 列表中）

**记录时间：** 2026-03-27  
**更新文件：** `SOUL.md`, `AGENTS.md`, `IDENTITY.md`
