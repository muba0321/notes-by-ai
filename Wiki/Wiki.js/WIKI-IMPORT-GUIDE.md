# Wiki.js 内容导入操作指南

本指南说明如何将 `/data` 目录下的文档导入到 Wiki.js。

---

## 📋 快速导入流程

### 第 1 步：完成 Wiki.js 初始化

1. 访问 `http://38.246.245.39`
2. 创建管理员账户
3. 配置站点信息
4. 完成初始化

### 第 2 步：下载中文语言包

1. **Administration** → **Settings** → **Locale**
2. 找到 **简体中文 (zh-CN)**
3. 点击 **Download**
4. 在 **Site Locale** 选择 **简体中文**
5. 点击 **Save**
6. 刷新页面 (F5)

### 第 3 步：创建页面结构

按照以下顺序创建页面：

```
1. 首页
   └─ 路径：home

2. OpenClaw 部署 (分类)
   ├─ 服务端部署
   ├─ 子节点部署
   └─ Wiki.js 部署

3. 配置文档 (分类)
   ├─ Gateway 配置
   ├─ 模型配置
   ├─ 钉钉集成
   └─ 子节点管理

4. 故障排除 (分类)
   ├─ SSH 连接问题
   ├─ Node.js 安装
   ├─ OpenClaw 问题
   └─ Gateway 问题

5. 脚本库 (分类)
   ├─ 部署脚本
   │  ├─ deploy-nginx.sh
   │  ├─ deploy-subagent.sh
   │  └─ deploy-wiki.sh
   ├─ 配置文件
   │  ├─ ip.txt
   │  ├─ ip-subagent.txt
   │  └─ ip-wiki.txt
   └─ 工具脚本
      └─ set-nginx-password.sh
```

### 第 4 步：配置导航菜单

1. **管理后台** → **导航**
2. 添加菜单项
3. 拖拽排序
4. 保存

---

## 📝 详细页面内容

### 页面 1：首页

**路径**: `home`  
**标题**: `OpenClaw Wiki - 首页`

**内容**:
```markdown
# 欢迎来到 OpenClaw 知识库

这是 OpenClaw 的官方文档和脚本库。

## 📦 快速开始

### 部署指南
- [服务端部署（带 Nginx 反向代理）](/openclaw/deployment/server)
- [子节点部署（任务执行节点）](/openclaw/deployment/subagent)
- [Wiki.js 部署](/openclaw/deployment/wiki)

### 配置文档
- [Gateway 配置](/openclaw/configuration/gateway)
- [模型配置（阿里云百炼）](/openclaw/configuration/model)
- [钉钉集成](/openclaw/configuration/dingtalk)

### 脚本库
- [部署脚本](/scripts/deploy)
- [配置文件](/scripts/config)
- [工具脚本](/scripts/tools)

### 故障排除
- [SSH 连接问题](/openclaw/troubleshooting/ssh)
- [Node.js 安装](/openclaw/troubleshooting/nodejs)
- [Gateway 问题](/openclaw/troubleshooting/gateway)

---

## 📊 文档统计

| 分类 | 文档数 |
|------|--------|
| 部署指南 | 3 |
| 配置文档 | 4 |
| 故障排除 | 4 |
| 脚本库 | 7 |
| **总计** | **18** |

---

## 🔗 外部链接

- [OpenClaw 官方文档](https://docs.openclaw.ai/)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Wiki.js 官方文档](https://docs.requarks.io/)
```

---

### 页面 2：服务端部署

**路径**: `openclaw/deployment/server`  
**标题**: `服务端部署（带 Nginx 反向代理）`

**内容来源**: `/data/openclaw/openclaw-deploy/DEPLOYMENT.md` 第 2 章

**内容要点**:
- 适用场景
- 前置要求
- 脚本部署步骤
- 手工部署步骤（详细）
- Nginx 配置示例
- SSL 证书申请
- 验证部署

---

### 页面 3：子节点部署

**路径**: `openclaw/deployment/subagent`  
**标题**: `子节点部署（任务执行节点）`

**内容来源**: `/data/openclaw/openclaw-deploy/DEPLOYMENT.md` 第 3 章 + `deploy-subagent.sh`

**内容要点**:
- 适用场景
- 前置要求
- 脚本部署（含模型配置）
- 手工部署（9 个步骤）
- 阿里云百炼模型配置
- 验证部署

---

### 页面 4：Wiki.js 部署

**路径**: `openclaw/deployment/wiki`  
**标题**: `Wiki.js 部署`

**内容来源**: `/data/openclaw/wiki/WIKI-DEPLOYMENT.md`

**内容要点**:
- Wiki.js 简介
- 脚本部署
- 手工部署（Docker 方式）
- 初始化配置
- 中文化配置
- 页面组织指南
- 常见问题

---

### 页面 5-8：配置文档系列

**Gateway 配置**
- 路径：`openclaw/configuration/gateway`
- 来源：DEPLOYMENT.md 第 5 章

**模型配置**
- 路径：`openclaw/configuration/model`
- 内容：阿里云百炼配置、API Key 管理

**钉钉集成**
- 路径：`openclaw/configuration/dingtalk`
- 内容：钉钉插件安装、配置步骤

**子节点管理**
- 路径：`openclaw/configuration/subagent`
- 内容：子节点连接、任务分配

---

### 页面 9-12：故障排除系列

**SSH 连接问题**
- 路径：`openclaw/troubleshooting/ssh`
- 来源：DEPLOYMENT.md 第 4.1 节

**Node.js 安装**
- 路径：`openclaw/troubleshooting/nodejs`
- 来源：DEPLOYMENT.md 第 4.2 节

**OpenClaw 问题**
- 路径：`openclaw/troubleshooting/openclaw`
- 来源：DEPLOYMENT.md 第 4.3 节

**Gateway 问题**
- 路径：`openclaw/troubleshooting/gateway`
- 来源：DEPLOYMENT.md 第 4.4 节

---

### 页面 13-19：脚本库

**部署脚本** (3 个页面)
- `scripts/deploy/deploy-nginx`
- `scripts/deploy/deploy-subagent`
- `scripts/deploy/deploy-wiki`

**配置文件** (3 个页面)
- `scripts/config/ip-txt`
- `scripts/config/ip-subagent-txt`
- `scripts/config/ip-wiki-txt`

**工具脚本** (1 个页面)
- `scripts/tools/set-nginx-password`

**每个脚本页面包含**:
- 脚本用途
- 依赖要求
- 使用方法
- 完整脚本内容
- 参数说明
- 使用示例

---

## 🎯 导航菜单配置

### 主菜单结构

```
🏠 首页
├── 📦 OpenClaw 部署 ▼
│   ├── 服务端部署
│   ├── 子节点部署
│   └── Wiki.js 部署
├── ⚙️ 配置文档 ▼
│   ├── Gateway 配置
│   ├── 模型配置
│   ├── 钉钉集成
│   └── 子节点管理
├── 📜 脚本库 ▼
│   ├── 部署脚本 ▼
│   │   ├── deploy-nginx.sh
│   │   ├── deploy-subagent.sh
│   │   └── deploy-wiki.sh
│   ├── 配置文件 ▼
│   │   ├── ip.txt
│   │   ├── ip-subagent.txt
│   │   └── ip-wiki.txt
│   └── 工具脚本
│       └── set-nginx-password.sh
└── 🔧 故障排除 ▼
    ├── SSH 连接问题
    ├── Node.js 安装
    ├── OpenClaw 问题
    └── Gateway 问题
```

### 配置步骤

1. **管理后台** → **导航**
2. 点击 **添加**
3. 选择类型：
   - **标题**：用于分类（如 "OpenClaw 部署"）
   - **页面**：链接到具体页面
4. 拖拽调整顺序和层级
5. 点击 **保存**

---

## ✅ 完成检查清单

### 基础配置
- [ ] Wiki.js 初始化完成
- [ ] 管理员账户创建
- [ ] 中文语言包下载
- [ ] 站点语言设置为中文

### 页面创建
- [ ] 首页 (`/home`)
- [ ] 服务端部署 (`/openclaw/deployment/server`)
- [ ] 子节点部署 (`/openclaw/deployment/subagent`)
- [ ] Wiki.js 部署 (`/openclaw/deployment/wiki`)
- [ ] Gateway 配置 (`/openclaw/configuration/gateway`)
- [ ] 模型配置 (`/openclaw/configuration/model`)
- [ ] 钉钉集成 (`/openclaw/configuration/dingtalk`)
- [ ] 子节点管理 (`/openclaw/configuration/subagent`)
- [ ] SSH 连接问题 (`/openclaw/troubleshooting/ssh`)
- [ ] Node.js 安装 (`/openclaw/troubleshooting/nodejs`)
- [ ] OpenClaw 问题 (`/openclaw/troubleshooting/openclaw`)
- [ ] Gateway 问题 (`/openclaw/troubleshooting/gateway`)
- [ ] 所有脚本页面 (7 个)
- [ ] 所有配置文件页面 (3 个)

### 导航配置
- [ ] 主菜单配置完成
- [ ] 菜单层级正确
- [ ] 所有链接可访问

### 测试验证
- [ ] 所有页面无 404
- [ ] 导航菜单正常显示
- [ ] 中文界面正常
- [ ] 搜索功能正常

---

## 📊 预计工作量

| 任务 | 预计时间 |
|------|----------|
| Wiki.js 初始化 | 10 分钟 |
| 中文化配置 | 5 分钟 |
| 创建 19 个页面 | 60-90 分钟 |
| 配置导航菜单 | 15 分钟 |
| 测试验证 | 15 分钟 |
| **总计** | **约 2 小时** |

---

## 💡 提示

1. **批量创建**：可以先创建所有页面的框架，再逐个填充内容
2. **复制粘贴**：从 Markdown 源文件复制内容时，注意调整格式
3. **图片处理**：如果有图片，先上传到资产库，再插入到页面
4. **版本控制**：重要修改后添加版本说明
5. **权限设置**：根据需要设置页面访问权限

---

## 🔗 参考文档

- [Wiki.js 官方文档 - 页面管理](https://docs.requarks.io/features/pages)
- [Wiki.js 官方文档 - 导航配置](https://docs.requarks.io/features/navigation)
- [Wiki.js 官方文档 - 语言环境](https://docs.requarks.io/features/i18n)
