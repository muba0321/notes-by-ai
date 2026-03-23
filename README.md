# 📚 OpenClaw Notes

> OpenClaw 部署文档、工具脚本与配置笔记
> 
> 🌐 在线文档：http://wiki.mubai.top

---

## 🚀 快速导航

| 主题 | 文档 | 说明 |
|------|------|------|
| 🤖 **Ansible** | [`ansible/`](ansible/) | Ansible 安装配置、Playbook 示例 |
| ☸️ **K8s 集群** | [`k8s-ansible/`](k8s-ansible/) | k3s 集群部署完整指南 |
| 🦎 **OpenClaw** | [`OpenClaw/`](OpenClaw/) | OpenClaw 部署、配置与 Skills |
| 📖 **Wiki** | [`Wiki/`](Wiki/) | Wiki.js 相关文档 |
| 🌐 **Nginx** | [`Nginx/`](Nginx/) | Nginx 配置与管理 |

---

## 📁 目录结构

```
openclaw-dist/
├── ansible/              # Ansible 自动化工具
│   ├── index.md          # 工具首页
│   ├── ansible-setup.md  # 安装配置手册
│   ├── inventory.md      # 主机清单配置
│   ├── playbooks.md      # 常用 Playbook 示例
│   └── test-report.md    # 部署测试报告
│
├── k8s-ansible/          # K8s 集群部署
│   ├── ansible-setup.md  # Ansible 配置
│   ├── inventory.md      # 主机清单
│   ├── playbooks.md      # 部署 Playbook
│   └── k8s-deploy.md     # K8s 部署指南
│
├── OpenClaw/             # OpenClaw 相关
│   ├── 服务端/           # 主节点部署
│   ├── 子节点/           # 子节点部署
│   ├── 配置/             # 配置文件与说明 ⭐
│   │   ├── CONFIG.md     # 配置说明总览
│   │   ├── README.md     # 配置目录索引
│   │   ├── ip-subagent.txt
│   │   └── lessons.md    # 踩坑记录
│   └── Skills/           # 技能文档 ⭐ 新增
│       ├── skill-vetter.md
│       └── self-improving-agent.md
│
├── Wiki/                 # Wiki.js 相关
├── Nginx/                # Nginx 配置
├── 归档/                 # 历史文档
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

### OpenClaw 部署

```bash
# 部署服务端
cd /data/openclaw-dist/OpenClaw/服务端
./deploy_openclaw_server.sh

# 部署子节点
cd /data/openclaw-dist/OpenClaw/子节点
# 1. 编辑 ../配置/ip-subagent.txt
# 2. ./deploy-subagent.sh
```

### 同步到 MkDocs

```bash
# 复制文档到 MkDocs
cp -r /data/openclaw-dist/ansible/* /opt/mkdocs/docs/tools/ansible/
cp -r /data/openclaw-dist/k8s-ansible/* /opt/mkdocs/docs/openclaw/deployment/k8s-ansible/

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
| 2026-03-23 | 添加 Skills 文档（skill-vetter, self-improving-agent） |
| 2026-03-18 | 整理配置文件到 OpenClaw/配置/ 目录 |
| 2026-03-18 | 添加 config/lessons.md 踩坑记录 |
| 2026-03-18 | 简化目录结构，k8s-ansible 和 ansible 移至根目录 |
| 2026-03-18 | 添加 Ansible + K8s 完整部署文档 |

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
