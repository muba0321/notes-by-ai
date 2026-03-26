# 📚 OpenClaw Notes

> OpenClaw 部署文档、工具脚本与配置笔记
> 
> 🌐 在线文档：http://wiki.mubai.top

---

## 🚀 快速导航

| 主题 | 文档 | 说明 |
|------|------|------|
| 🔄 **CI/CD** | [`CI-CD/`](CI-CD/) | Jenkins + GitHub + Ansible + K8s 持续集成/部署 ⭐ |
| 📊 **Monitoring** | [`Monitoring/`](Monitoring/) | Prometheus + Grafana 监控平台 ⭐ |
| 🤖 **Ansible** | [`ansible/`](ansible/) | Ansible 安装配置、Playbook 示例 |
| ☸️ **K8s 集群** | [`k8s-ansible/`](k8s-ansible/) | k3s 集群部署完整指南 |
| 🦎 **OpenClaw** | [`OpenClaw/`](OpenClaw/) | OpenClaw 部署、配置与 Skills |
| 📖 **Wiki** | [`Wiki/`](Wiki/) | Wiki.js 相关文档 |
| 🌐 **Nginx** | [`Nginx/`](Nginx/) | Nginx 配置与管理 |
| 📒 **Feishu** | [`Feishu/`](Feishu/) | 飞书机器人配置、多 Agent 协作与权限管理 ⭐ |
| 📊 **Products** | [`products/`](products/) | 产品设计文档（子节点 1 生成） |

---

## 📁 目录结构

```
openclaw-dist/
├── CI-CD/                  # CI/CD 平台文档 ⭐
│   ├── README.md           # 目录说明
│   ├── cicd-platform-design.md      # 产品流程设计（5 个场景）
│   ├── cicd-deployment-guide.md     # 完整部署指南
│   ├── cicd-scripts-index.md        # 脚本索引
│   ├── Jenkins/            # Jenkins 文档
│   │   └── jenkins-deployment-record.md
│   └── scripts/            # 安装脚本
│       └── install-jenkins.sh
│
├── Monitoring/             # 监控平台文档 ⭐
│   ├── README.md           # 目录说明
│   ├── Prometheus/         # Prometheus 文档
│   │   ├── prometheus-grafana-deployment.md
│   │   ├── cicd-monitoring-metrics.md
│   │   └── linux-monitoring-metrics-full.md
│   └── Grafana/            # Grafana 文档
│       ├── grafana-dingtalk-alert-setup.md
│       └── nginx-proxy-config.md
│
├── OpenClaw/               # OpenClaw 相关
│   ├── 服务端/             # 主节点部署
│   ├── 子节点/             # 子节点部署
│   ├── 配置/               # 配置文件与说明
│   └── Skills/             # 技能文档
│       ├── skill-vetter.md
│       └── self-improving-agent.md
│
├── products/               # 产品设计文档
│   ├── README.md
│   ├── PRD/                # 产品需求文档
│   ├── research/           # 调研分析
│   ├── features/           # 功能设计
│   ├── reviews/            # 评审记录
│   └── archive/            # 已归档
│
├── ansible/                # Ansible 自动化工具
│   ├── index.md
│   ├── ansible-setup.md
│   ├── inventory.md
│   ├── playbooks.md
│   └── test-report.md
│
├── k8s-ansible/            # K8s 集群部署
│   ├── ansible-setup.md
│   ├── inventory.md
│   ├── playbooks.md
│   └── k8s-deploy.md
│
├── Wiki/                   # Wiki.js 相关
├── Nginx/                  # Nginx 配置
├── Feishu/                 # 飞书机器人配置与多 Agent 协作 ⭐
│   ├── README.md           # 飞书集成完整指南
│   └── 权限配置清单.md     # 权限申请清单
├── 归档/                   # 历史文档
└── README.md
```

---

## 🛠️ 常用命令

### Git 同步

```bash
# 拉取最新代码
cd /data/openclaw-dist
git pull origin main

# 提交更新
git add .
git commit -m "更新文档内容"
git push origin main
```

### CI/CD 部署

```bash
# 部署 Jenkins
cd CI-CD/scripts
./install-jenkins.sh

# 访问 Jenkins
http://jenkins.mubai.top
```

### 监控平台

```bash
# 访问 Grafana
http://grafana.mubai.top
# 默认账号：admin / Grafana12345

# 访问 Prometheus
http://promethus.mubai.top
```

### OpenClaw 部署

```bash
# 部署服务端
cd OpenClaw/服务端
./deploy_openclaw_server.sh

# 部署子节点
cd OpenClaw/子节点
# 1. 编辑 ../配置/ip-subagent.txt
# 2. ./deploy-subagent.sh
```

### 同步到 MkDocs

```bash
# 复制文档到 MkDocs
cp -r /data/openclaw-dist/ansible/* /opt/mkdocs/docs/tools/ansible/
cp -r /data/openclaw-dist/k8s-ansible/* /opt/mkdocs/docs/openclaw/deployment/k8s-ansible/
cp -r /data/openclaw-dist/CI-CD/* /opt/mkdocs/docs/ci-cd/
cp -r /data/openclaw-dist/Monitoring/* /opt/mkdocs/docs/monitoring/

# 构建站点
cd /opt/mkdocs && mkdocs build
```

### 查看文档

- **本地预览：** `mkdocs serve` (在 `/opt/mkdocs/` 目录)
- **在线访问：** http://wiki.mubai.top

---

## 📝 最近更新

| 日期 | 更新内容 |
|------|----------|
| 2026-03-26 | **新增 Feishu/** - 飞书机器人配置、多 Agent 协作与权限管理 ⭐ |
| 2026-03-23 | **重构目录结构** - 按工具分类 (CI-CD/Monitoring/OpenClaw) |
| 2026-03-23 | 完善监控体系（125+ 系统指标、Grafana 面板、钉钉告警） |
| 2026-03-23 | 部署 Prometheus + Grafana 监控平台 |
| 2026-03-23 | 部署 Jenkins CI/CD 平台 |
| 2026-03-23 | 配置 Nginx 反向代理（3 个域名） |
| 2026-03-23 | 添加 Skills 文档（skill-vetter, self-improving-agent） |
| 2026-03-23 | 新增 `products/` 目录（产品设计文档） |
| 2026-03-18 | 整理配置文件到 OpenClaw/配置/ 目录 |

---

## 🔗 相关链接

- **GitHub:** https://github.com/muba0321/notes-by-ai
- **MkDocs:** https://www.mkdocs.org/
- **OpenClaw:** https://github.com/openclaw/openclaw
- **在线文档:** http://wiki.mubai.top

---

<div align="center">

**维护者:** OpenClaw Team  
**许可证:** MIT

</div>
