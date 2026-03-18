# OpenClaw Notes & Documentation

OpenClaw 部署文档、工具脚本与配置笔记

## 目录结构

/data/openclaw-dist/
├── k8s-ansible/          # K8s 集群部署文档
│   ├── ansible-setup.md  # Ansible 安装配置
│   ├── inventory.md      # 主机清单配置
│   ├── playbooks.md      # Playbook 示例
│   └── k8s-deploy.md     # K8s 部署指南
├── ansible/              # Ansible 工具文档
│   ├── index.md          # 工具首页
│   ├── ansible-setup.md  # 安装配置
│   ├── inventory.md      # 主机清单
│   ├── playbooks.md      # Playbook 示例
│   └── test-report.md    # 测试报告
├── OpenClaw/             # OpenClaw 相关文档
├── Wiki/                 # Wiki 相关文档
├── Nginx/                # Nginx 相关文档
├── 归档/                 # 已归档文档
└── README.md

## 同步到 MkDocs

cp -r k8s-ansible/* /opt/mkdocs/docs/openclaw/deployment/k8s-ansible/
cp -r ansible/* /opt/mkdocs/docs/tools/ansible/
cd /opt/mkdocs && mkdocs build

## 更新日志

- 2026-03-18 - 简化目录结构，k8s-ansible 和 ansible 直接放在根目录

维护者：OpenClaw Team
