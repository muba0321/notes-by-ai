# 节点 1 Qwen-Coder 部署方案

**部署时间：** 2026-03-25  
**部署目标：** 子节点 1 (38.246.245.39) 代码生成能力  
**使用模型：** 阿里云 Qwen-Coder (qwen3-coder-next)

---

## 📊 方案概述

### 架构设计

```
┌─────────────────────────────────────────────────────────┐
│                    子节点 1                              │
│              (38.246.245.39 海外)                        │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  OpenClaw    │  │   Qwen-      │  │   GitHub     │  │
│  │  Gateway     │  │   Coder      │  │   CLI        │  │
│  │  :18789      │  │   Skill      │  │              │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │           │
│         └─────────────────┼─────────────────┘           │
│                           │                             │
│                  ┌────────▼────────┐                    │
│                  │  阿里云 API      │                    │
│                  │  (Qwen-Coder)    │                    │
│                  └─────────────────┘                    │
└─────────────────────────────────────────────────────────┘
                           ↓
                    互联网访问
                           ↓
┌─────────────────────────────────────────────────────────┐
│                    你的电脑                              │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐                     │
│  │  Webchat     │  │     Trae     │                     │
│  │  页面控制    │  │  本地开发     │                     │
│  └──────────────┘  └──────────────┘                     │
└─────────────────────────────────────────────────────────┘
```

### 核心能力

| 能力 | 说明 | 实现方式 |
|------|------|----------|
| **代码生成** | 根据需求生成完整代码 | Qwen-Coder API |
| **代码审查** | 分析代码问题并给出建议 | Qwen-Coder API |
| **Bug 修复** | 定位并修复 Bug | Qwen-Coder + 执行测试 |
| **自动部署** | 生成代码后自动部署 | OpenClaw + Git |
| **文档生成** | 生成技术文档 | Qwen-Coder + MkDocs |

---

## 🔧 环境准备

### 节点 1 当前状态

| 资源 | 状态 | 说明 |
|------|------|------|
| **CPU** | 4 核 | Intel Xeon |
| **内存** | 3.8G (可用 2.3G) | 足够运行 |
| **磁盘** | 30G (可用 20G) | 足够使用 |
| **OpenClaw** | ✅ 已安装 | v2026.3.13 |
| **Docker** | ✅ 已安装 | 容器运行时 |
| **Nginx** | ✅ 已安装 | 反向代理 |
| **Git** | ✅ 已安装 | 版本控制 |

### 需要安装的工具

| 工具 | 用途 | 安装命令 |
|------|------|----------|
| **GitHub CLI** | GitHub 操作 | `apt install gh` |
| **Node.js** | npm 包管理 | 已安装 (v22) |
| **Python3** | Python 项目 | 已安装 |
| **aliyun-coder Skill** | 代码生成 | 手动安装 |

---

## 📦 部署步骤

### 步骤 1：配置阿里云 API Key

```bash
# 在节点 1 执行
# 编辑 ~/.openclaw/openclaw.json
# 在 models.providers.bailian 中添加:
{
  "apiKey": "sk-sp-YOUR_API_KEY",
  "models": [
    {
      "id": "qwen3-coder-next",
      "name": "qwen3-coder-next",
      "input": ["text"],
      "cost": {"input": 0, "output": 0}
    }
  ]
}

# 重启 Gateway
openclaw gateway restart
```

### 步骤 2：安装 aliyun-coder Skill

```bash
# 在节点 1 执行
mkdir -p ~/.openclaw/workspace/skills/aliyun-coder

cat > ~/.openclaw/workspace/skills/aliyun-coder/SKILL.md << 'SKILL'
---
name: aliyun-coder
description: 使用阿里云 Qwen-Coder 生成代码。支持 Python/JS/Go/Java 等。
author: OpenClaw
metadata:
  openclaw:
    emoji: 💻
---

# 阿里云代码生成器

## 配置
- API Key: sk-sp-YOUR_API_KEY
- 模型：qwen3-coder-next
- 端点：https://coding.dashscope.aliyuncs.com/v1

## 使用方式

### 代码生成
用户："用 Python 写一个 FastAPI 用户管理系统"
→ 调用 Qwen-Coder API
→ 生成完整代码
→ 写入文件
→ 安装依赖
→ 启动服务

### 代码审查
用户："审查一下这个代码"
→ 读取代码文件
→ 调用 Qwen-Coder 分析
→ 返回问题列表和改进建议

### Bug 修复
用户："这个 API 有 Bug，帮我修复"
→ 读取错误日志
→ 分析代码
→ 生成修复方案
→ 应用修复
→ 运行测试
SKILL

# 验证安装
openclaw skills list | grep aliyun-coder
```

### 步骤 3：安装 GitHub CLI

```bash
# 在节点 1 执行
apt-get update
apt-get install -y gh

# 配置 GitHub Token
gh auth login --with-token << 'EOF'
ghp_YOUR_GITHUB_TOKEN
EOF

# 验证
gh whoami
```

### 步骤 4：配置工作目录

```bash
# 创建代码工作区
mkdir -p /data/openclaw-dist/workspace
cd /data/openclaw-dist/workspace

# 初始化 Git
git init
git config user.name "OpenClaw Agent"
git config user.email "openclaw@mubai.top"

# 关联远程仓库
git remote add origin https://github.com/muba0321/notes-by-ai.git
git pull origin main
```

### 步骤 5：配置自动同步

```bash
# 创建同步脚本
cat > /data/openclaw-dist/workspace/sync.sh << 'SCRIPT'
#!/bin/bash
cd /data/openclaw-dist/workspace

# 拉取最新
git pull --rebase

# 提交变更
git add -A
git commit -m "auto: $(date '+%Y-%m-%d %H:%M')" || true

# 推送
git push

echo "同步完成：$(date)"
SCRIPT

chmod +x /data/openclaw-dist/workspace/sync.sh

# 配置定时任务（每小时同步）
(crontab -l 2>/dev/null; echo "0 * * * * /data/openclaw-dist/workspace/sync.sh") | crontab -
```

---

## 🚀 使用方式

### 场景 1：代码生成 + 部署

```
你："在节点 1 部署一个 Flask API 服务"

节点 1 执行：
1. aliyun-coder 生成 Flask 代码
2. 写入 /data/openclaw-dist/workspace/flask-api/
3. pip install 依赖
4. 启动服务
5. Git commit + push
6. 返回访问地址
```

### 场景 2：代码审查

```
你："审查一下 /data/openclaw-dist/workspace/api.py"

节点 1 执行：
1. 读取 api.py
2. aliyun-coder 分析代码
3. 返回问题列表和改进建议
```

### 场景 3：Bug 修复

```
你："api.py 有 Bug，帮我修复"

节点 1 执行：
1. 读取错误日志
2. aliyun-coder 分析并生成修复
3. 应用修复
4. 运行测试验证
5. Git commit + push
```

---

## 📊 验证清单

| 检查项 | 命令 | 预期结果 |
|--------|------|----------|
| OpenClaw 运行 | `openclaw gateway status` | running |
| aliyun-coder 安装 | `openclaw skills list` | ✓ ready |
| GitHub 认证 | `gh whoami` | muba0321 |
| Git 配置 | `git config user.name` | OpenClaw Agent |
| API Key 配置 | `cat ~/.openclaw/openclaw.json` | 包含 qwen3-coder-next |

---

## ⚠️ 注意事项

### 1. API 额度监控

```bash
# 查看 API 使用情况
# 登录 https://dashscope.console.aliyun.com/usage
# 免费额度：每月一定额度，超出按量付费
```

### 2. 代码安全

- ✅ 生成的代码需要人工审查
- ✅ 敏感信息不要提交到 Git
- ✅ 定期更新依赖包

### 3. 资源限制

| 资源 | 限制 | 建议 |
|------|------|------|
| 内存 | 2.3G 可用 | 避免同时运行多个大模型 |
| CPU | 4 核 | 代码生成时 CPU 会升高 |
| 磁盘 | 20G 可用 | 定期清理旧项目 |

---

## 📝 后续优化

### 阶段 1：基础能力（当前）

- ✅ Qwen-Coder API 调用
- ✅ GitHub CLI 集成
- ✅ Git 自动同步

### 阶段 2：增强能力

- [ ] 添加代码测试自动生成
- [ ] 集成 Docker 自动部署
- [ ] 添加代码质量检查（lint）

### 阶段 3：高级能力

- [ ] 部署 Tabby 本地模型（离线代码补全）
- [ ] 集成 CI/CD 流水线
- [ ] 多项目并行管理

---

**部署负责人：** OpenClaw Agent  
**方案版本：** v1.0  
**最后更新：** 2026-03-25
