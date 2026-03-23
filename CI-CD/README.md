# CI/CD 平台文档

_基于 Jenkins + GitHub + Ansible + K8s 的持续集成/持续部署平台_

---

## 📁 目录结构

```
CI-CD/
├── README.md                    # 本文件
├── cicd-platform-design.md      # 产品流程设计（5 个场景方案）
├── cicd-deployment-guide.md     # 完整部署指南
├── cicd-scripts-index.md        # 安装脚本索引
├── Jenkins/                     # Jenkins 相关文档
│   └── jenkins-deployment-record.md
└── scripts/                     # 安装脚本
    └── install-jenkins.sh
```

---

## 📄 文档说明

| 文件 | 大小 | 说明 |
|------|------|------|
| **cicd-platform-design.md** | 17 KB | CI/CD 平台产品流程设计（5 个场景方案） |
| **cicd-deployment-guide.md** | 20 KB | 完整部署指南（工具清单/测试验证/故障排除） |
| **cicd-scripts-index.md** | 7.5 KB | 安装脚本索引和使用说明 |
| **jenkins-deployment-record.md** | 4.8 KB | Jenkins 部署记录和配置 |
| **install-jenkins.sh** | 2.3 KB | Jenkins 自动化安装脚本 |

---

## 🎯 场景方案

文档包含 5 个 CI/CD 场景方案：

| 方案 | 名称 | 适用场景 | 特点 |
|------|------|---------|------|
| **A** | 开发环境自动部署 | 快速迭代验证 | 全自动，<10 分钟 |
| **B** | 生产环境受控部署 | 生产发布 | 人工审批，灰度发布 |
| **C** | 多环境分级部署 | 企业级流程 | Dev→Test→Staging→Prod |
| **D** | 微服务多应用部署 | 多服务协调 | 并行/顺序/分组部署 |
| **E** | 回滚与灾备方案 | 故障恢复 | <5 分钟 RTO |

---

## 🚀 快速开始

### 部署 Jenkins

```bash
cd /data/openclaw-dist/CI-CD/scripts
chmod +x install-jenkins.sh
./install-jenkins.sh
```

**预计时间：** 5-10 分钟

### 访问地址

| 服务 | 地址 | 说明 |
|------|------|------|
| **Jenkins** | http://jenkins.mubai.top | CI/CD 平台 |
| **Jenkins (IP)** | http://38.246.245.39:8080 | 直接访问 |

---

## 📋 部署流程

```
1. 安装基础工具 (Docker/Ansible/Git)  → 10 分钟
       ↓
2. 部署 Jenkins                       → 5 分钟
       ↓
3. 配置 Jenkins 插件                   → 10 分钟
       ↓
4. 配置 GitHub Webhook                → 5 分钟
       ↓
5. 创建 Pipeline                      → 10 分钟
       ↓
部署完成
```

**总时间：** 约 40 分钟

---

## 🔧 核心组件

| 组件 | 版本 | 用途 | 部署位置 |
|------|------|------|---------|
| **Jenkins** | 2.541 LTS | CI/CD 编排 | 子节点 1 (Docker) |
| **GitHub** | 云端 | 代码托管、Webhook | 外部服务 |
| **Ansible** | 2.14+ | 自动化部署 | 子节点 1 |
| **K8s** | 1.26+ | 容器编排 | 4 台机器集群 |
| **Docker** | 24+ | 容器构建 | 子节点 1 + K8s 节点 |

---

## 📊 与监控平台集成

CI/CD 平台与监控平台紧密集成：

```
CI-CD/                          Monitoring/
├── Jenkins                     ├── Prometheus
│   └── 构建/部署指标 ─────────→│   └── 采集 Jenkins 指标
│                               │
└── 部署到 K8s                  └── Grafana
    └── 应用状态 ──────────────→    └── 可视化展示
```

**相关文档：**
- [Monitoring/Prometheus/cicd-monitoring-metrics.md](../Monitoring/Prometheus/cicd-monitoring-metrics.md)
- [Monitoring/Grafana/grafana-dingtalk-alert-setup.md](../Monitoring/Grafana/grafana-dingtalk-alert-setup.md)

---

## 🔗 相关文档

- [Monitoring/](../Monitoring/) - Prometheus+Grafana 监控平台
- [OpenClaw/](../OpenClaw/) - OpenClaw 部署文档
- [products/](../products/) - 产品设计文档

---

## 📝 更新记录

| 日期 | 更新内容 |
|------|----------|
| 2026-03-23 | 重构目录结构 - 从 products/PRD/ 和 OpenClaw/scripts/ 迁移到 CI-CD/ |
| 2026-03-23 | 部署 Jenkins 到子节点 1 |
| 2026-03-23 | 创建完整的 CI/CD 产品流程设计文档 |

---

**维护者：** OpenClaw 子节点 1  
**最后更新：** 2026-03-23  
**状态：** ✅ 运行中
