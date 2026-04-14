# 飞书多 Agent 协作系统部署文档

**文档版本：** v1.0  
**创建时间：** 2026-03-26  
**作者：** OpenClaw 多 Agent 部署团队

---

## 📋 目录

1. [项目概述](#项目概述)
2. [架构设计](#架构设计)
3. [飞书应用配置](#飞书应用配置)
4. [OpenClaw 配置](#openclaw-配置)
5. [多 Agent 协作协议](#多-agent-协作协议)
6. [Skills 安装清单](#skills-安装清单)
7. [部署步骤](#部署步骤)
8. [遇到的问题与解决方案](#遇到的问题与解决方案)
9. [运维指南](#运维指南)
10. [附录](#附录)

---

## 项目概述

### 背景

需要在飞书群聊中部署多个 AI Agent，分别承担不同角色：
- **咨询助手**：群聊协调者，负责任务分发
- **产品助手**：产品需求分析、PRD 撰写
- **开发助手**：后端 API 设计、数据库设计
- **前端开发助手**：前端页面开发、UI 实现

### 需求

1. 群聊中只有一个接口人（咨询助手），避免多机器人同时回复
2. 用户点名特定 Agent 时，只有被点名的 Agent 回复
3. 私聊时每个 Agent 独立工作
4. 支持跨节点部署（主节点协调，子节点执行）

---

## 架构设计

### 节点分工

| 节点 | 主机名 | IP | Agent | 职责 |
|------|--------|-----|-------|------|
| **主节点** | ser493590849885 | 38.246.245.32 | `consult` | 群聊消息接收、任务协调分发 |
| **子节点 1** | mubai-subagent1 | 38.246.245.39 | `product`/`backend`/`frontend` | 专业任务执行、飞书对接 |

### 消息流转

```
┌─────────────┐
│  沐白在群里  │
│   发消息     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────┐
│  主节点 - 咨询助手        │
│  (唯一接收群消息)        │
└──────┬──────────────────┘
       │ 分析任务类型
       ├──────────────────┬──────────────────┐
       ▼                  ▼                  ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ 产品需求     │  │ 后端开发     │  │ 前端开发     │
│ sessions_send│  │ sessions_send│  │ sessions_send│
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │
       ▼                ▼                ▼
┌─────────────────────────────────────────────────┐
│           子节点 1 - 专业 Agent                   │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐   │
│  │ 产品助手   │  │ 后端助手   │  │ 前端助手   │   │
│  └───────────┘  └───────────┘  └───────────┘   │
└─────────────────────────────────────────────────┘
```

---

## 飞书应用配置

### 应用列表

| 应用名称 | App ID | App Secret | 绑定 Agent | 用途 |
|---------|--------|-----------|-----------|------|
| openclaw-总助手 | `cli_a94fa973abb85bcd` | `usYqzJQJ4BHJlqbD89IrwcuL8ISVLfHM` | consult | 群聊协调 |
| 产品助手 | `cli_a94fa042dc381bd7` | `d7kbf6MtMIYi4XSaWh7JGAYTbh7TC5bH` | product | 产品管理 |
| 开发助手 | `cli_a94fa7ad17f65bc6` | `xHVrxwkm7ihmzxzV9pd7GpCW62KvhIlU` | backend | 后端开发 |
| 前端开发助手 | `cli_a94fa0f666381bd8` | `6zubQYhtVvXUohiLLduC3emQiu2DxYQd` | frontend | 前端开发 |

### 配置步骤

1. 登录 [open.feishu.cn](https://open.feishu.cn)
2. 创建企业自建应用
3. 添加机器人能力
4. 配置事件订阅（WebSocket 长连接）
5. 发布上线

---

## OpenClaw 配置

### 主节点配置 (`/root/.openclaw/openclaw.json`)

```json
{
  "agents": {
    "list": [
      {"id": "main", "default": true, "workspace": "/root/.openclaw/workspace"},
      {"id": "consult", "name": "咨询助手", "workspace": "/root/.openclaw/workspace-consult"}
    ]
  },
  "channels": {
    "feishu": {
      "accounts": {
        "consult": {
          "appId": "cli_a94fa973abb85bcd",
          "appSecret": "usYqzJQJ4BHJlqbD89IrwcuL8ISVLfHM",
          "dmPolicy": "open",
          "groupPolicy": "open",
          "allowFrom": ["*"]
        }
      }
    }
  },
  "bindings": [
    {"agentId": "consult", "match": {"channel": "feishu", "accountId": "consult"}}
  ],
  "tools": {
    "sessions": {"visibility": "all"},
    "agentToAgent": {
      "enabled": true,
      "allow": ["consult", "product", "backend", "frontend"]
    }
  }
}
```

### 子节点 1 配置 (`/root/.openclaw/openclaw.json`)

```json
{
  "agents": {
    "list": [
      {"id": "product", "name": "产品助手", "workspace": "/root/.openclaw/workspace-product"},
      {"id": "backend", "name": "后端开发助手", "workspace": "/root/.openclaw/workspace-backend"},
      {"id": "frontend", "name": "前端开发助手", "workspace": "/root/.openclaw/workspace-frontend"}
    ]
  },
  "channels": {
    "feishu": {
      "accounts": {
        "product": {
          "appId": "cli_a94fa042dc381bd7",
          "appSecret": "d7kbf6MtMIYi4XSaWh7JGAYTbh7TC5bH",
          "dmPolicy": "open",
          "groupPolicy": "open"
        },
        "backend": {
          "appId": "cli_a94fa7ad17f65bc6",
          "appSecret": "xHVrxwkm7ihmzxzV9pd7GpCW62KvhIlU",
          "dmPolicy": "open",
          "groupPolicy": "open"
        },
        "frontend": {
          "appId": "cli_a94fa0f666381bd8",
          "appSecret": "6zubQYhtVvXUohiLLduC3emQiu2DxYQd",
          "dmPolicy": "open",
          "groupPolicy": "open"
        }
      }
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "bailian": {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "sk-sp-7e6f845b069f486d9b18aa8366579f1e",
        "api": "openai-completions"
      }
    }
  }
}
```

---

## 多 Agent 协作协议

### 回复规则

| 场景 | 咨询助手 | 产品助手 | 后端助手 | 前端助手 |
|------|---------|---------|---------|---------|
| **群聊 - 未@** | ✅ 回复 | ❌ 静默 | ❌ 静默 | ❌ 静默 |
| **群聊 - @产品助手** | ✅ 可补充 | ✅ 回复 | ❌ 静默 | ❌ 静默 |
| **群聊 - @后端助手** | ✅ 可补充 | ❌ 静默 | ✅ 回复 | ❌ 静默 |
| **群聊 - @前端助手** | ✅ 可补充 | ❌ 静默 | ❌ 静默 | ✅ 回复 |
| **私聊** | ✅ | ✅ | ✅ | ✅ |

### SOUL.md 静默规则模板

```markdown
## ⚠️ 群聊静默规则（最高优先级）

### 在群聊中，你**只回复**当：
1. ✅ 用户明确 `@<Agent 名称>`
2. ✅ 咨询助手通过 `sessions_send` 转发任务给你

### 在群聊中，你**保持静默**当：
- ❌ 用户没有@任何人（咨询助手会回答）
- ❌ 用户@了其他 agent
- ❌ 咨询助手已经回复了

### 私聊中：
- ✅ 始终正常响应
```

---

## Skills 安装清单

### 共享 Skills (30 个)

**产品类：**
- `prd-writer-pro` - PRD 文档撰写
- `prd-to-ddd-design` - PRD 转 DDD 领域设计
- `requirement-analysis-system` - 需求分析系统
- `product-manager` - 产品经理
- `market-research` - 市场调研
- `competitor-analyst` - 竞品分析

**开发类：**
- `code-review-fix` - 代码审查与修复
- `api-generator` - API 生成
- `database-designer` - 数据库设计
- `developer` - 开发者
- `aliyun-coder` - 阿里云代码助手

**前端类：**
- `elite-frontend-design` - 前端设计专家
- `expert-frontend-developer` - 前端开发专家
- `frontend-design-pro` - 前端设计专业版
- `frontend-doctor` - 前端医生
- `vue-expert` - Vue 专家
- `react-expert` - React 专家

**安全审计：**
- `security-auditor` - 安全审计员
- `security-audit-toolkit` - 安全审计工具包
- `openclaw-security-audit` - OpenClaw 安全审计
- `healthcheck` - 健康检查

**多 Agent 协作：**
- `feishu-multi-agent` - 飞书多 Agent 编排
- `openclaw-feishu-multi-agent` - OpenClaw 多 Agent 协作
- `multi-agent-coordinator` - 多 Agent 协调器

**工具类：**
- `skill-finder-cn-pro` - 技能查找器
- `skill-creator` - 技能创建器
- `ui-ux-design` - UI/UX 设计
- `ai-researcher` - AI 研究员

---

## 部署步骤

### 1. 主节点部署

```bash
# 1.1 配置 openclaw.json
cd /root/.openclaw
# 编辑 openclaw.json，只保留 main 和 consult

# 1.2 重启 Gateway
openclaw gateway restart

# 1.3 验证状态
openclaw gateway status
curl http://localhost:18789/health
```

### 2. 子节点 1 部署

```bash
# 2.1 配置 openclaw.json
# 配置 product/backend/frontend 三个 agent
# 添加 models.bailian 配置（API Key）

# 2.2 同步 Skills
scp -r /root/.openclaw/workspace/skills/* root@38.246.245.39:/root/.openclaw/workspace/skills/

# 2.3 同步 SOUL.md（带静默规则）
scp /root/.openclaw/workspace-product/SOUL.md root@38.246.245.39:/root/.openclaw/workspace-product/SOUL.md
scp /root/.openclaw/workspace-dev/SOUL.md root@38.246.245.39:/root/.openclaw/workspace-backend/SOUL.md
scp /root/.openclaw/workspace-frontend/SOUL.md root@38.246.245.39:/root/.openclaw/workspace-frontend/SOUL.md

# 2.4 重启 Gateway
systemctl --user restart openclaw-gateway

# 2.5 验证
curl http://localhost:18789/health
```

### 3. 飞书配对

```bash
# 主节点
openclaw pairing approve feishu <配对码>

# 子节点 1（每个 agent 都需要配对）
openclaw pairing approve feishu <配对码>
```

---

## 遇到的问题与解决方案

### 问题 1：多 Agent 同时回复

**症状：** 群里发一条消息，所有 Agent 都回复

**原因：** 所有 Agent 的 `groupPolicy` 都是 `"open"`，都能收到群消息

**解决方案：**
1. 主节点只保留 `consult` 的 `groupPolicy: "open"`
2. 子节点 Agent 的 SOUL.md 添加静默规则
3. 通过 `sessions_send` 实现任务转发

---

### 问题 2：子节点缺少 API Key

**症状：** `No API key found for provider "bailian"`

**原因：** 子节点 `openclaw.json` 缺少 `models` 配置

**解决方案：**
```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "bailian": {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "sk-sp-7e6f845b069f486d9b18aa8366579f1e",
        "api": "openai-completions"
      }
    }
  }
}
```

---

### 问题 3：binding 配置无效

**症状：** 尝试在 binding 中添加 `chatType: "p2p"` 报错

**原因：** OpenClaw schema 不支持 binding 中的 `chatType` 字段

**解决方案：** 改用 SOUL.md 静默规则控制回复行为

---

### 问题 4：Skills 未同步

**症状：** 子节点 Agent 无法使用已安装的 Skills

**原因：** Skills 只安装在主节点，未同步到子节点

**解决方案：**
```bash
scp -r /root/.openclaw/workspace/skills/* root@子节点 IP:/root/.openclaw/workspace/skills/
```

---

## 运维指南

### 日常检查

```bash
# 主节点
openclaw gateway status
openclaw sessions --agent consult --active 60

# 子节点 1
ssh root@38.246.245.39 "openclaw gateway status"
ssh root@38.246.245.39 "openclaw sessions --agent product --active 60"
```

### 日志查看

```bash
# 主节点
tail -f /tmp/openclaw/openclaw-*.log

# 子节点 1
ssh root@38.246.245.39 "tail -f /tmp/openclaw/openclaw-*.log"
```

### 故障恢复

```bash
# Gateway 重启
openclaw gateway restart

# 子节点 Gateway 重启
ssh root@38.246.245.39 "systemctl --user restart openclaw-gateway"

# 检查飞书连接
grep "WebSocket client started" /tmp/openclaw/openclaw-*.log | tail -10
```

---

## 附录

### A. 快速命令参考

| 命令 | 用途 |
|------|------|
| `openclaw gateway status` | 查看 Gateway 状态 |
| `openclaw gateway restart` | 重启 Gateway |
| `openclaw sessions --agent <id>` | 查看 Agent 会话 |
| `openclaw pairing approve feishu <code>` | 飞书配对 |
| `clawhub install <skill>` | 安装 Skill |

### B. 文件路径

| 文件 | 主节点路径 | 子节点 1 路径 |
|------|-----------|------------|
| openclaw.json | `/root/.openclaw/openclaw.json` | `/root/.openclaw/openclaw.json` |
| Gateway 日志 | `/tmp/openclaw/openclaw-*.log` | `/tmp/openclaw/openclaw-*.log` |
| Skills 目录 | `/root/.openclaw/workspace/skills/` | `/root/.openclaw/workspace/skills/` |
| Agent Workspace | `/root/.openclaw/workspace-consult/` | `/root/.openclaw/workspace-product/` 等 |

### C. 联系信息

- **项目负责人：** 沐白
- **部署时间：** 2026-03-26
- **GitHub 仓库：** https://github.com/muba0321/notes-by-ai

---

**文档结束**
