# OpenClaw Notes & Documentation

OpenClaw 部署文档、工具脚本与配置笔记

## 目录结构

- docs/openclaw/deployment/k8s-ansible/ - K8s 部署文档
- docs/tools/ansible/ - Ansible 工具文档
- scripts/ - 脚本文件
- config/ - 配置文件

## 同步到 MkDocs

cp -r docs/* /opt/mkdocs/docs/
cd /opt/mkdocs && mkdocs build

## 更新日志

- 2026-03-18 - 初始版本，添加 Ansible + K8s 部署文档
