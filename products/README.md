# 产品设计文档

_子节点 1 生成的产品设计、需求分析与调研报告_

---

## 📌 概述

本目录存储由 **子节点 1 (产品设计专用)** 生成的产品设计文档、需求分析和调研报告。

| 属性 | 值 |
|------|-----|
| **用途** | 产品设计、需求分析、市场调研 |
| **生成代理** | 子节点 1 (38.246.245.39) |
| **创建时间** | 2026-03-23 |
| **同步方式** | Git 推送 → GitHub → MkDocs 发布 |

---

## 📁 目录结构

```
products/
├── README.md              # 本文件 - 目录说明 + 文档索引
├── PRD/                   # 产品需求文档
│   ├── template.md        # PRD 模板
│   └── [产品名]-PRD.md    # 具体产品 PRD
├── research/              # 调研分析
│   ├── market/            # 市场调研
│   ├── competitors/       # 竞品分析
│   └── users/             # 用户研究
├── features/              # 功能设计
│   └── [功能名]/
│       ├── design.md      # 设计文档
│       └── feedback.md    # 用户反馈
├── reviews/               # 评审记录
│   └── [日期]-review.md
└── archive/               # 已归档产品
```

---

## 📂 分类说明

### PRD/ — 产品需求文档

**用途：** 完整的产品需求规格说明

**模板：** `PRD/template.md`

**命名规范：** `[产品名]-PRD.md`

**示例：**
- `PRD/openclaw-subagent-PRD.md`
- `PRD/wiki-search-PRD.md`

---

### research/ — 调研分析

| 子目录 | 用途 | 示例 |
|--------|------|------|
| `market/` | 市场调研、行业分析 | `2026-ai-agent-market.md` |
| `competitors/` | 竞品分析、对比报告 | `openclaw-vs-dify.md` |
| `users/` | 用户研究、需求访谈 | `user-interview-2026-03.md` |

---

### features/ — 功能设计

**用途：** 单个功能的详细设计文档

**结构：**
```
features/
└── [功能名]/
    ├── design.md      # 功能设计（背景、流程、交互）
    ├── technical.md   # 技术方案（可选）
    └── feedback.md    # 用户反馈/迭代记录
```

**示例：**
- `features/self-improving-skill/design.md`
- `features/web-search-integration/design.md`

---

### reviews/ — 评审记录

**用途：** 产品评审会议记录、决策记录

**命名规范：** `YYYY-MM-DD-[主题]-review.md`

**示例：**
- `reviews/2026-03-23-skills-design-review.md`
- `reviews/2026-03-25-q2-roadmap-review.md`

---

### archive/ — 已归档

**用途：** 已下线/废弃的产品文档

**移动规则：**
- 产品已下线
- 方案被废弃
- 文档过时（>1 年未更新）

---

## 📝 文档规范

### 文件命名

| 类型 | 规范 | 示例 |
|------|------|------|
| PRD | `[产品名]-PRD.md` | `chatbot-PRD.md` |
| 调研 | `[主题]-[日期].md` | `ai-market-2026-03.md` |
| 功能 | `design.md` (在功能目录内) | `features/search/design.md` |
| 评审 | `YYYY-MM-DD-[主题]-review.md` | `2026-03-23-roadmap-review.md` |

### 文件头模板

```markdown
# [文档标题]

**创建日期：** YYYY-MM-DD  
**最后更新：** YYYY-MM-DD  
**作者：** OpenClaw 子节点 1  
**状态：** draft | review | approved | archived  
**相关 PRD：** [链接]

---

## 概述

[一句话总结]

---

## 正文

...
```

### 状态说明

| 状态 | 说明 |
|------|------|
| `draft` | 草稿，待完善 |
| `review` | 待评审 |
| `approved` | 已批准，可执行 |
| `archived` | 已归档 |

---

## 🔄 工作流程

```
1. 子节点 1 生成文档草稿
       ↓
2. 保存到对应目录（状态：draft）
       ↓
3. Git commit + push → GitHub
       ↓
4. 用户评审（状态：review）
       ↓
5. 批准后（状态：approved）
       ↓
6. 执行/开发
       ↓
7. 定期归档（状态：archived）
```

---

## 🛠️ 常用命令

### 创建新 PRD

```bash
cd /data/openclaw-dist/products
cp PRD/template.md PRD/[产品名]-PRD.md
# 编辑内容
git add PRD/[产品名]-PRD.md
git commit -m "添加 [产品名] PRD"
git push
```

### 查看待评审文档

```bash
# 查找状态为 review 的文档
grep -r "状态：review" /data/openclaw-dist/products/
```

### 归档旧产品

```bash
# 移动文件到 archive 目录
mv products/PRD/old-product-PRD.md products/archive/
git add -A
git commit -m "归档旧产品：old-product"
git push
```

---

## 📊 文档索引

### PRD 列表

| 产品 | 创建日期 | 状态 | 链接 |
|------|---------|------|------|
| （待补充） | - | - | - |

### 调研报告

| 主题 | 类型 | 日期 | 链接 |
|------|------|------|------|
| （待补充） | - | - | - |

### 功能设计

| 功能 | 状态 | 日期 | 链接 |
|------|------|------|------|
| （待补充） | - | - | - |

---

## 🔗 相关资源

- **主节点：** 38.246.245.39 (server)
- **子节点 1：** 38.246.245.39 (产品设计专用)
- **GitHub:** https://github.com/muba0321/notes-by-ai
- **在线文档：** http://wiki.mubai.top

---

**维护者：** OpenClaw 子节点 1  
**最后更新：** 2026-03-23
