# OpenClaw 配置中心

所有配置文件和使用说明

## 文件列表

| 文件 | 用途 | 说明 |
|------|------|------|
| CONFIG.md | 配置说明总览 | 所有配置文件的详细文档 |
| AGENTS.md | Agent 工作规范 | OpenClaw Agent 的行为准则 |
| ip-subagent.txt | 子节点服务器列表 | 部署脚本使用的服务器清单 |
| lessons.md | 踩坑记录 | 部署和运维问题总结 |

## 快速开始

### 配置服务器列表

编辑 ip-subagent.txt：

    vi ip-subagent.txt

添加服务器信息（格式：IP:端口：用户名：密码：主机名）

### 执行部署

    cd /data/openclaw-dist/OpenClaw/子节点
    ./deploy-subagent.sh

### 查看配置说明

    cat CONFIG.md

## 安全提示

ip-subagent.txt 包含敏感信息：
- 不要提交到公共 Git 仓库
- 部署后建议删除或加密
- 可使用 .gitignore 忽略

## 相关目录

- 子节点部署 - ../子节点/
- 服务端部署 - ../服务端/

最后更新：2026-03-18
