# Skill Vetter — 安全审查工具

_审计日期：2026-03-23 | 风险等级：🟢 LOW | 安装位置：主节点 + 子节点 1_

---

## 📌 概述

**Skill Vetter** 是一个安全审查工具，用于在安装其他 OpenClaw Skills 之前进行安全审计。

| 属性 | 值 |
|------|-----|
| **用途** | 审计其他 Skills 的安全性 |
| **来源** | ClawHub (clawhub.ai) |
| **风险等级** | 🟢 LOW |
| **安装时间** | 2026-03-23 |
| **安装位置** | 主节点 (server) + 子节点 1 |

---

## 🔧 功能

### 核心能力

1. **来源检查** — 验证 Skill 来源、作者可信度、更新时间
2. **代码审查** — 扫描 SKILL.md 中的危险信号
3. **权限评估** — 分析需要的文件/网络/命令权限
4. **风险分类** — 生成风险等级和建议

### 危险信号检测

🚨 **自动拒绝**（发现以下任一）：
- curl/wget 到未知 URL
- 发送数据到外部服务器
- 请求凭证/Token/API Key
- 读取敏感文件（~/.ssh, ~/.aws, MEMORY.md 等）
- 使用 base64 解码
- 使用 eval()/exec() 处理外部输入
- 修改系统文件
- 混淆/压缩代码
- 请求 sudo 权限

---

## 📦 安装

### 安装路径

| 节点 | 路径 |
|------|------|
| 主节点 | `/usr/lib/node_modules/openclaw/skills/skill-vetter/SKILL.md` |
| 子节点 1 | `/usr/lib/node_modules/openclaw/skills/skill-vetter/SKILL.md` |

### 安装步骤

```bash
# 1. 创建目录
mkdir -p /usr/lib/node_modules/openclaw/skills/skill-vetter

# 2. 写入 SKILL.md（内容见 ClawHub）

# 3. 重启 Gateway（可选，技能自动加载）
openclaw gateway restart
```

### 验证安装

```bash
ls -la /usr/lib/node_modules/openclaw/skills/skill-vetter/
# 应看到 SKILL.md 文件
```

---

## 📖 使用方法

### 调用方式

在对话中直接使用：

```
"用 skill-vetter 审计一下 [Skill 名称]"
"帮我审查这个 Skill 是否安全：[GitHub 链接]"
```

### 输出格式

审计报告包含：

```
SKILL VETTING REPORT
═══════════════════════════════════════
Skill: [名称]
Source: [来源]
Author: [作者]
Version: [版本]
───────────────────────────────────────
METRICS:
• Downloads/Stars: [数量]
• Last Updated: [日期]
• Files Reviewed: [数量]
───────────────────────────────────────
RED FLAGS: [无 / 列表]

PERMISSIONS NEEDED:
• Files: [文件列表]
• Network: [网络请求]
• Commands: [命令列表]
───────────────────────────────────────
RISK LEVEL: [🟢 LOW / 🟡 MEDIUM / 🔴 HIGH / ⛔ EXTREME]

VERDICT: [✅ SAFE / ⚠️ CAUTION / ❌ DO NOT INSTALL]

NOTES: [备注]
═══════════════════════════════════════
```

---

## 🔍 审计流程

### Step 1: 来源检查
- [ ] 来源是否可信？（官方/社区/个人）
- [ ] 作者是否知名？
- [ ] 有多少下载/Star？
- [ ] 最后更新时间？

### Step 2: 代码审查（必须）
- [ ] 读取所有文件
- [ ] 检查危险信号
- [ ] 确认无外部调用

### Step 3: 权限评估
- [ ] 需要读取哪些文件？
- [ ] 需要写入哪些文件？
- [ ] 需要执行哪些命令？
- [ ] 需要网络访问吗？

### Step 4: 风险分类

| 等级 | 示例 | 操作 |
|------|------|------|
| 🟢 LOW | 笔记、天气、格式化 | 基础审查，可安装 |
| 🟡 MEDIUM | 文件操作、浏览器、API | 完整审查 |
| 🔴 HIGH | 凭证、交易、系统 | 需要人工批准 |
| ⛔ EXTREME | 安全配置、root 权限 | 不要安装 |

---

## 🛠️ 快速审查命令

```bash
# 检查 GitHub 仓库统计
curl -s "https://api.github.com/repos/OWNER/REPO" | jq '{stars: .stargazers_count, forks: .forks_count, updated: .updated_at}'

# 列出 Skill 文件
curl -s "https://api.github.com/repos/OWNER/REPO/contents/skills/SKILL_NAME" | jq '.[].name'

# 获取 SKILL.md 内容
curl -s "https://raw.githubusercontent.com/OWNER/REPO/main/skills/SKILL_NAME/SKILL.md"
```

---

## 📝 信任等级

| 来源 | 审查强度 |
|------|----------|
| OpenClaw 官方 Skills | 低（仍需审查） |
| 高 Star 仓库 (1000+) | 中等 |
| 知名作者 | 中等 |
| 新/未知来源 | 最高 |
| 请求凭证的 Skills | **必须人工批准** |

---

## ⚠️ 注意事项

1. **没有 Skill 值得牺牲安全性** — 有疑问就不装
2. **高风险决策问人类** — 不要自己决定
3. **记录审查过程** — 方便未来参考
4. **保持怀疑** — Paranoia is a feature 🔒

---

## 📚 相关文档

- [OpenClaw Skills 介绍](../配置/CONFIG.md)
- [子节点部署指南](../子节点/)
- [安全最佳实践](../配置/lessons.md)

---

**最后更新：** 2026-03-23  
**维护者：** OpenClaw 代理系统
