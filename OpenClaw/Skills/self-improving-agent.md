# Self-Improving Agent — 自改进技能

_审计日期：2026-03-23 | 风险等级：🟡 MEDIUM | 安装位置：子节点 1_

---

## 📌 概述

**Self-Improving Agent** 是一个持续改进技能，通过记录错误、学习和功能请求到日志文件，帮助 AI 助手从经验中学习并不断改进。

| 属性 | 值 |
|------|-----|
| **用途** | 记录学习、错误、功能请求，促进持续改进 |
| **来源** | GitHub (pskoett/pskoett-ai-skills) |
| **ClawHub** | https://clawhub.ai/pskoett/self-improving-agent |
| **风险等级** | 🟡 MEDIUM（需要人工监督） |
| **安装时间** | 2026-03-23 |
| **安装位置** | 子节点 1（产品设计专用） |

---

## ⚠️ 安全审计摘要

### 风险点

| 风险 | 说明 | 缓解措施 |
|------|------|----------|
| **修改核心文件** | 可写入 `SOUL.md`, `AGENTS.md`, `TOOLS.md` | ❌ 禁止修改 `SOUL.md`，其他需人工批准 |
| **自动 Hook** | 可选安装自动触发 Hook | ❌ 不安装 Hook，手动触发 |
| **文件膨胀** | 日志可能越积越多 | 📅 每周审查清理 |
| **错误提升** | 可能把错误学习提升到核心文件 | 👁️ 提升前必须人工审核 |

### 安全信号

| 检查项 | 结果 |
|--------|------|
| 外部 URL 调用 | ❌ 无（只写本地文件） |
| 请求凭证 | ❌ 无 |
| 数据外传 | ❌ 无 |
| 混淆代码 | ❌ 无（纯 Markdown） |
| 提权请求 | ❌ 无 |

### 审计结论

**VERDICT:** ⚠️ 可以安装，但需要：
1. 仅在子节点测试
2. 禁止修改 `SOUL.md`
3. 提升到核心文件前必须人工批准
4. 不安装自动 Hook

---

## 📦 安装步骤

### 环境准备

**目标机器：** 子节点 1 (38.246.245.39)

### 步骤 1：创建 Skill 目录

```bash
ssh root@38.246.245.39 "mkdir -p /usr/lib/node_modules/openclaw/skills/self-improving-agent"
```

### 步骤 2：写入 SKILL.md

从 GitHub 获取内容并写入：

```bash
# 源文件
https://raw.githubusercontent.com/pskoett/pskoett-ai-skills/main/skills/self-improvement/SKILL.md
```

**OpenClaw 适配版已写入：**
```
/usr/lib/node_modules/openclaw/skills/self-improving-agent/SKILL.md
```

### 步骤 3：创建学习日志目录

```bash
ssh root@38.246.245.39 "mkdir -p /root/.openclaw/workspace/.learnings"
```

### 步骤 4：初始化日志文件

```bash
ssh root@38.246.245.39 "
echo '# Learnings Log' > /root/.openclaw/workspace/.learnings/LEARNINGS.md
echo '# Errors Log' > /root/.openclaw/workspace/.learnings/ERRORS.md
echo '# Feature Requests' > /root/.openclaw/workspace/.learnings/FEATURE_REQUESTS.md
"
```

### 步骤 5：验证安装

```bash
ssh root@38.246.245.39 "
ls -la /usr/lib/node_modules/openclaw/skills/self-improving-agent/
ls -la /root/.openclaw/workspace/.learnings/
"
```

**预期输出：**
```
/usr/lib/node_modules/openclaw/skills/self-improving-agent/
└── SKILL.md

/root/.openclaw/workspace/.learnings/
├── ERRORS.md
├── FEATURE_REQUESTS.md
└── LEARNINGS.md
```

---

## 📖 使用方法

### 调用方式

在对话中直接使用：

```
"记录这个错误到 .learnings/ERRORS.md"
"把这次学习记录到 .learnings/LEARNINGS.md"
"检查 .learnings/ 里有没有相关的问题"
```

### 日志格式

#### 学习条目 (LEARNINGS.md)

```markdown
## [LRN-20260323-001] correction

**Logged**: 2026-03-23T02:45:00Z
**Priority**: medium
**Status**: pending
**Area**: config

### Summary
用户纠正了某个配置项的写法

### Details
原以为配置项是 X，实际应该是 Y

### Suggested Action
更新 TOOLS.md 中的配置说明

### Metadata
- Source: user_feedback
- Related Files: /root/.openclaw/workspace/TOOLS.md
- Tags: configuration, correction

---
```

#### 错误条目 (ERRORS.md)

```markdown
## [ERR-20260323-001] gateway_start

**Logged**: 2026-03-23T02:45:00Z
**Priority**: high
**Status**: pending
**Area**: infra

### Summary
Gateway 启动失败

### Error
```
Error: Port 18789 is already in use
```

### Context
- Command: `openclaw gateway start`
- Environment: 子节点 1

### Suggested Fix
检查端口占用情况

### Metadata
- Reproducible: yes
- Related Files: /tmp/openclaw/openclaw.log

---
```

#### 功能请求 (FEATURE_REQUESTS.md)

```markdown
## [FEAT-20260323-001] web_search_integration

**Logged**: 2026-03-23T02:45:00Z
**Priority**: medium
**Status**: pending
**Area**: backend

### Requested Capability
希望能够搜索微信文章

### User Context
产品设计需要收集竞品信息

### Complexity Estimate
medium

### Suggested Implementation
集成微信搜索 API 或使用浏览器自动化

### Metadata
- Frequency: recurring
- Related Features: web_search

---
```

### ID 生成规则

格式：`TYPE-YYYYMMDD-XXX`

| 部分 | 说明 | 示例 |
|------|------|------|
| TYPE | `LRN` (学习), `ERR` (错误), `FEAT` (功能) | LRN |
| YYYYMMDD | 当前日期 | 20260323 |
| XXX | 序号 | 001, 002, 003 |

示例：`LRN-20260323-001`, `ERR-20260323-001`

---

## 🔄 学习提升流程

### 何时提升

学习条目满足以下条件时，可提升到核心文件：

| 条件 | 说明 |
|------|------|
| 广泛适用 | 不只适用于单一场景 |
| 防止重复错误 | 能避免未来犯同样错误 |
| 项目规范 | 记录项目特定的约定 |
| 经验证有效 | 已解决并验证的方案 |

### 提升目标

| 学习类型 | 提升到 | 示例 |
|---------|--------|------|
| 行为规范 | `SOUL.md` | "简洁回复，避免废话" |
| 工作流程 | `AGENTS.md` | "长任务使用子代理" |
| 工具技巧 | `TOOLS.md` | "Git push 需要先配置认证" |
| 长期记忆 | `MEMORY.md` | 主会话专用 |

### 提升步骤

1. **提炼** — 将学习浓缩为简洁的规则
2. **添加** — 写入目标文件的适当章节
3. **更新原条目** — 标记为 `promoted`

```markdown
### Resolution
- **Resolved**: 2026-03-23T09:00:00Z
- **Promoted**: TOOLS.md
- **Notes**: 已添加到工具配置章节
```

---

## 🛡️ 安全配置（子节点 1 专用）

### 权限限制

```markdown
✅ 允许：
- 写入 .learnings/ 目录
- 读取 workspace 文件
- 建议提升到其他文件（需批准）

❌ 禁止：
- 直接修改 SOUL.md
- 安装自动 Hook
- 外部网络调用
```

### 审查频率

| 审查类型 | 频率 | 内容 |
|---------|------|------|
| 日志审查 | 每周 | 检查 pending 条目 |
| 提升审查 | 按需 | 提升前必须审核 |
| 清理 | 每月 | 删除已解决的旧条目 |

### 快速审查命令

```bash
# 统计 pending 条目数
grep -h "Status\*\*: pending" /root/.openclaw/workspace/.learnings/*.md | wc -l

# 列出高优先级条目
grep -B5 "Priority\*\*: high" /root/.openclaw/workspace/.learnings/*.md | grep "^## \["

# 查找特定领域的学习
grep -l "Area\*\*: config" /root/.openclaw/workspace/.learnings/*.md
```

---

## 🧪 测试方案

### 测试环境

| 项目 | 值 |
|------|-----|
| **测试时间** | 2026-03-23 02:50 UTC |
| **测试机器** | 子节点 1 (38.246.245.39) |
| **测试目标** | 验证日志记录功能正常 |

### 测试步骤

#### 步骤 1：写入测试学习条目

创建测试条目到 LEARNINGS.md：

```markdown
## [LRN-20260323-001] skill_installation_test

**Logged**: 2026-03-23T02:50:00Z
**Priority**: low
**Status**: pending
**Area**: config

### Summary
测试 self-improving-agent 技能安装成功

### Details
- 技能已安装到子节点 1
- 日志目录已创建
- 三个日志文件已初始化
- 笔记文档已写入

### Suggested Action
无需操作，仅测试记录功能

### Metadata
- Source: conversation
- Related Files: /usr/lib/node_modules/openclaw/skills/self-improving-agent/SKILL.md
- Tags: test, skill-installation, self-improving-agent
```

#### 步骤 2：验证写入成功

```bash
cat /root/.openclaw/workspace/.learnings/LEARNINGS.md
```

**预期输出：** 包含新条目，格式正确

#### 步骤 3：测试快速审查命令

```bash
# 统计 pending 条目数
grep -h 'Status\*\*: pending' /root/.openclaw/workspace/.learnings/*.md | wc -l

# 按领域统计
grep -h 'Area\*\*:' /root/.openclaw/workspace/.learnings/*.md | sort | uniq -c
```

**预期输出：**
```
Pending 条目数：1
按领域统计：1 config
```

#### 步骤 4：验证其他日志文件

```bash
cat /root/.openclaw/workspace/.learnings/ERRORS.md
cat /root/.openclaw/workspace/.learnings/FEATURE_REQUESTS.md
```

**预期输出：** 文件存在，内容为空（仅标题）

### 测试结果

| 测试项 | 状态 | 说明 |
|--------|------|------|
| 写入学习日志 | ✅ 成功 | 创建条目 `LRN-20260323-001` |
| 格式正确性 | ✅ 成功 | 包含所有必需字段 |
| 快速审查命令 | ✅ 成功 | 统计 pending 条目 = 1 |
| 领域统计 | ✅ 成功 | config 领域 1 条 |
| 其他日志文件 | ✅ 正常 | ERRORS.md, FEATURE_REQUESTS.md 为空 |

### 测试结论

✅ **所有测试通过** — 技能功能正常，可以投入使用。

---

## ⚠️ 注意事项

1. **SOUL.md 修改必须人工批准** — 这是核心身份定义
2. **不安装自动 Hook** — 避免不受控的自动执行
3. **定期清理日志** — 防止文件膨胀影响性能
4. **提升前仔细审查** — 避免错误知识污染核心文件
5. **先在子节点测试** — 观察稳定后再考虑主节点

---

## 📚 相关文件

| 文件 | 路径 |
|------|------|
| Skill 文件 | `/usr/lib/node_modules/openclaw/skills/self-improving-agent/SKILL.md` |
| 学习日志 | `/root/.openclaw/workspace/.learnings/LEARNINGS.md` |
| 错误日志 | `/root/.openclaw/workspace/.learnings/ERRORS.md` |
| 功能请求 | `/root/.openclaw/workspace/.learnings/FEATURE_REQUESTS.md` |
| 笔记文档 | `/data/openclaw-dist/OpenClaw/Skills/self-improving-agent.md` |

---

## 🔗 参考链接

- **GitHub 源码：** https://github.com/pskoett/pskoett-ai-skills/tree/main/skills/self-improvement
- **ClawHub 页面：** https://clawhub.ai/pskoett/self-improving-agent
- **Agent Skills 规范：** https://agentskills.io/specification

---

**最后更新：** 2026-03-23  
**维护者：** OpenClaw 代理系统  
**安装状态：** ✅ 已安装（子节点 1）
