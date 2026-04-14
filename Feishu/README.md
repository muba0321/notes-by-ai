# 📕 飞书 (Feishu/Lark) 集成文档

> OpenClaw 飞书机器人配置、多 Agent 协作与权限管理完整指南

**最后更新：** 2026-03-26  
**状态：** ✅ 运行中

---

## 📋 目录

- [快速开始](#快速开始)
- [权限配置](#权限配置)
- [多 Agent 架构](#多-agent-架构)
- [多 OpenClaw 协作](#多-openclaw-协作)
- [飞书多维表格协作](#飞书多维表格协作)
- [故障排查](#故障排查)

---

## 🚀 快速开始

### 1️⃣ 创建飞书应用

访问：https://open.feishu.cn/app

```
应用开发 → 企业内部开发 → 创建应用
→ 应用名称：openclaw-总助手
→ 应用图标：上传 OpenClaw Logo
→ 完成创建
```

### 2️⃣ 获取凭证

```
应用管理 → openclaw-总助手 → 凭证与基础信息
→ 记录 App ID 和 App Secret
```

**当前配置：**
| 应用名称 | App ID | App Secret | 绑定 Agent |
|---------|--------|-----------|-----------|
| openclaw-总助手 | `cli_a94e61e51df85bc2` | `SXJEqC9TFpJcKAiTYeb8Xb7gvWU4wofv` | main |

### 3️⃣ 配置 OpenClaw

编辑 `~/.openclaw/openclaw.json`：

```json5
{
  "channels": {
    "feishu": {
      "accounts": {
        "main": {
          "appId": "cli_a94e61e51df85bc2",
          "appSecret": "SXJEqC9TFpJcKAiTYeb8Xb7gvWU4wofv",
          "dmPolicy": "open",
          "groupPolicy": "open",
          "allowFrom": ["*"]
        }
      }
    }
  },
  "bindings": [
    {
      "agentId": "main",
      "match": {
        "channel": "feishu",
        "accountId": "main"
      }
    }
  ]
}
```

### 4️⃣ 启用飞书插件

```bash
openclaw plugins enable feishu
openclaw gateway restart
```

### 5️⃣ 验证状态

```bash
openclaw channels status --probe
```

**期望输出：**
```
- Feishu main: enabled, configured, running, works
```

---

## 🔐 权限配置

### 必需权限（基础对话）

| 权限名称 | 权限代码 | 用途 |
|---------|---------|------|
| 发送消息 | `im:message` | 回复用户消息 |
| 接收消息 | `im:message.receive_v1` | 接收用户消息 |
| 读取用户信息 | `contact:user:readonly` | 获取发送者信息 |
| 机器人管理 | `app:bot` | 机器人基础功能 |

### 推荐权限（协作功能）

| 权限名称 | 权限代码 | 用途 |
|---------|---------|------|
| 云文档读取 | `drive:doc:readonly` | 读取飞书文档 |
| 云文档编辑 | `drive:doc` | 编辑/创建文档 |
| 云文档列表 | `drive:file:readonly` | 列出用户文档 |
| 多维表格读取 | `bitable:app:readonly` | 读取多维表格 |
| 多维表格编辑 | `bitable:app` | 编辑/创建多维表格 |
| 群组信息 | `im:chat` | 获取群组信息 |
| 群成员列表 | `im:chat.member` | 获取群成员列表 |

### 高级权限（多 Agent 协作）

| 权限名称 | 权限代码 | 用途 |
|---------|---------|------|
| 消息回复 | `im:message:reply` | 回复特定消息 |
| 消息编辑 | `im:message.edit` | 编辑已发送消息 |
| 消息撤回 | `im:message.delete` | 撤回消息 |
| 富文本消息 | `im:message:post` | 发送富文本/卡片 |
| 互动卡片 | `im:interactive_card` | 发送可交互卡片 |
| 日历读取 | `calendar:readonly` | 读取日程 |
| 日历编辑 | `calendar` | 创建/修改日程 |

### 配置步骤

```
应用管理 → openclaw-总助手 → 权限管理 → 申请权限
→ 搜索上述权限代码 → 批量添加 → 保存并发布
```

---

## 🤖 多 Agent 架构

### 方案 A：单应用 + 多 Agent 路由

```
飞书应用 (openclaw-main)
├─ Agent: main (默认)
├─ Agent: consult (咨询)
└─ Agent: coding (开发)
```

**绑定规则：**
- 私聊 → main Agent
- 群聊 @咨询 → consult Agent
- 群聊 @开发 → coding Agent

### 方案 B：多应用 + 多 Agent（推荐⭐）

| 应用名称 | App ID | 绑定 Agent | 用途 |
|---------|--------|-----------|------|
| openclaw-总助手 | cli_a94e61e51df85bc2 | main | 通用对话 |
| openclaw-咨询 | (新建) | consult | 咨询业务 |
| openclaw-开发 | (新建) | coding | 代码生成 |

**配置示例：**

```json5
{
  "agents": {
    "list": [
      { id: "main", workspace: "~/.openclaw/workspace" },
      { id: "consult", workspace: "~/.openclaw/workspace-consult" },
      { id: "coding", workspace: "~/.openclaw/workspace-coding" }
    ]
  },
  "channels": {
    "feishu": {
      "accounts": {
        "main": {
          "appId": "cli_a94e61e51df85bc2",
          "appSecret": "***"
        },
        "consult": {
          "appId": "cli_xxx",
          "appSecret": "***"
        },
        "coding": {
          "appId": "cli_yyy",
          "appSecret": "***"
        }
      }
    }
  },
  "bindings": [
    { agentId: "main", match: { channel: "feishu", accountId: "main" } },
    { agentId: "consult", match: { channel: "feishu", accountId: "consult" } },
    { agentId: "coding", match: { channel: "feishu", accountId: "coding" } }
  ]
}
```

**优点：**
- ✅ 权限隔离（每个应用独立权限）
- ✅ 日志清晰（飞书后台可区分）
- ✅ 故障隔离（一个应用挂了不影响其他）
- ✅ 易于扩展

---

## 🏢 多 OpenClaw 协作

### 架构设计

```
┌─────────────────────────────────────────────────────────┐
│                    飞书开放平台                          │
│  应用 1: openclaw-总助手                                 │
│  应用 2: openclaw-咨询                                   │
│  应用 3: openclaw-开发                                   │
└─────────────────────────────────────────────────────────┘
           │                    │                    │
           ↓                    ↓                    ↓
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  主节点           │  │  子节点 1         │  │  堡垒机          │
│  38.246.245.32   │  │  38.246.245.39   │  │  222.211.80.222  │
│  Agent: main     │  │  Agent: product  │  │  Agent: monitor  │
│  Gateway:18789   │  │  Gateway:18789   │  │  Gateway:18789   │
└──────────────────┘  └──────────────────┘  └──────────────────┘
           │                    │                    │
           └────────────────────┼────────────────────┘
                                ↓
                    ┌──────────────────┐
                    │  共享存储/消息    │
                    │  - 飞书多维表格   │
                    │  - Git 仓库       │
                    │  - Redis/数据库   │
                    └──────────────────┘
```

### 配置步骤

**1. 各节点独立配置飞书应用**

**主节点 (~/.openclaw/openclaw.json)：**
```json5
{
  "channels": {
    "feishu": {
      "accounts": {
        "main": {
          "appId": "cli_a94e61e51df85bc2",
          "appSecret": "***"
        }
      }
    }
  }
}
```

**子节点 1 (~/.openclaw/openclaw.json)：**
```json5
{
  "channels": {
    "feishu": {
      "accounts": {
        "product": {
          "appId": "cli_yyy",
          "appSecret": "***"
        }
      }
    }
  }
}
```

**2. 配置 bindings 路由**

每个节点独立配置，确保消息路由到正确的 Agent。

---

## 📊 飞书多维表格协作

### 用途

1. **任务分配** - 多 Agent 共享任务队列
2. **状态同步** - Agent 之间共享上下文
3. **日志记录** - 操作审计和追踪
4. **知识库** - 共享知识和配置

### 创建协作中心表格

**1. 创建多维表格**
```
飞书 → 云文档 → 新建 → 多维表格
→ 命名为 "OpenClaw 协作中心"
```

**2. 设计数据表**

**任务队列表：**

| 字段 | 类型 | 说明 |
|------|------|------|
| 任务 ID | 自动编号 | 唯一标识 |
| 任务描述 | 文本 | 任务内容 |
| 优先级 | 单选 | 高/中/低 |
| 分配给 | 人员 | 负责 Agent |
| 状态 | 单选 | 待处理/进行中/已完成 |
| 创建时间 | 创建时间 | 自动记录 |
| 完成时间 | 日期 | 任务完成时填写 |

**Agent 状态表：**

| 字段 | 类型 | 说明 |
|------|------|------|
| Agent ID | 文本 | main/consult/coding |
| 状态 | 单选 | 在线/离线/忙碌 |
| 当前任务 | 文本 | 正在处理的任务 |
| 最后活跃 | 日期时间 | 最后活跃时间 |
| 负载 | 数字 | 当前任务数 |

**3. 权限配置**
```
多维表格 → 权限 → 添加应用
→ 选择 openclaw-总助手/咨询/开发
→ 授予编辑权限
```

**4. OpenClaw 集成**

使用 `feishu_bitable` 工具操作表格：

```bash
# 读取任务
feishu_bitable_list_records --app_token=xxx --table_id=yyy

# 创建任务
feishu_bitable_create_record --app_token=xxx --fields='{"任务描述":"xxx"}'

# 更新状态
feishu_bitable_update_record --app_token=xxx --record_id=zzz --fields='{"状态":"已完成"}'
```

---

## 🔧 可用工具

OpenClaw 飞书插件提供以下工具：

| 工具 | 用途 | 示例 |
|------|------|------|
| `feishu_doc` | 飞书文档操作 | 读取/编辑/创建文档 |
| `feishu_chat` | 飞书聊天操作 | 发送消息/获取成员 |
| `feishu_wiki` | 飞书知识库操作 | 读取/编辑知识库 |
| `feishu_drive` | 飞书云存储操作 | 上传/下载文件 |
| `feishu_bitable` | 飞书多维表格操作 | CRUD 记录 |
| `feishu_app_scopes` | 查看应用权限 | 调试权限问题 |

---

## 🐛 故障排查

### 问题 1：消息无法接收

**检查：**
```bash
# 1. 插件状态
openclaw plugins list | grep feishu

# 2. Gateway 状态
openclaw gateway status

# 3. 通道状态
openclaw channels status --probe
```

**飞书后台检查：**
```
应用管理 → 事件订阅
→ 确认已订阅 "接收消息" 事件
→ 确认应用已发布
```

### 问题 2：权限不足

**检查：**
```bash
feishu_app_scopes
```

**解决：**
```
应用管理 → 权限管理
→ 添加缺失的权限
→ 保存并发布
```

### 问题 3：多维表格无法访问

**检查：**
```bash
# 获取表格元数据
feishu_bitable_get_meta --url=https://xxx.feishu.cn/base/yyy
```

**解决：**
```
多维表格 → 权限
→ 添加飞书应用为协作者
→ 授予编辑权限
```

---

## 📝 变更记录

| 日期 | 变更内容 | 操作人 |
|------|---------|--------|
| 2026-03-26 | 初始配置完成 | 系统 |
| 2026-03-26 | 添加多 Agent 架构说明 | 系统 |
| 2026-03-26 | 添加多维表格协作方案 | 系统 |

---

## 🔗 相关文档

- [OpenClaw 主节点配置](../OpenClaw/服务端/)
- [多 Agent 配置指南](../OpenClaw/配置/multi-agent.md)
- [飞书开放平台文档](https://open.feishu.cn/document/)

---

**维护者：** OpenClaw Agent  
**最后更新：** 2026-03-26
