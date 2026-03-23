# OpenClaw 部署文档

OpenClaw 服务端和子节点部署指南

## 目录结构

- **服务端/** - 主节点部署脚本和文档
- **子节点/** - 子节点部署脚本和文档
- **配置/** - 配置文件和说明
- **Skills/** - 技能文档和安装指南 ⭐

## 快速开始

### 部署服务端

```bash
cd 服务端
./deploy_openclaw_server.sh
```

### 部署子节点

```bash
# 1. 编辑配置
编辑 配置/ip-subagent.txt

# 2. 执行部署
./deploy-subagent.sh
```

## 已安装 Skills

| Skill | 用途 | 安装位置 | 文档 |
|-------|------|---------|------|
| **skill-vetter** | 安全审查其他 Skills | 主节点 + 子节点 1 | [Skills/skill-vetter.md](Skills/skill-vetter.md) |
| **self-improving-agent** | 持续改进（日志驱动） | 子节点 1 | [Skills/self-improving-agent.md](Skills/self-improving-agent.md) |

## 配置文件

详见 [配置/README.md](配置/README.md)

## 相关资源

- **在线文档：** http://wiki.mubai.top
- **GitHub:** https://github.com/openclaw/openclaw
- **ClawHub:** https://clawhub.ai

---

**最后更新：** 2026-03-23
