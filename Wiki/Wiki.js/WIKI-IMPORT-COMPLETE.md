# Wiki.js 页面导入完成指南

**重要提示**: Wiki.js 的 API 创建页面需要复杂的 GraphQL 查询，建议通过 Web 界面手动创建页面。

---

## ✅ 已完成的工作

### 1. Wiki.js 部署
- [x] Docker 部署完成
- [x] Nginx 反向代理配置
- [x] 服务正常运行

### 2. 管理员账户
- [x] 账户已创建
- **邮箱**: `admin@mubai.top`
- **密码**: `Admin123456!`

### 3. 站点配置
- [x] 站点名称：OpenClaw Wiki
- [x] 站点 URL：http://wiki.mubai.top

### 4. 语言设置
- [x] 已设置为 zh-CN（中文语言包需手动下载）

---

## 📋 手动导入步骤

### 第 1 步：访问并登录

```
http://38.246.245.39
```

使用管理员账户登录。

### 第 2 步：下载中文语言包

1. 点击左下角 **管理**
2. 左侧菜单：**设置** → **语言环境**
3. 找到 **简体中文 (zh-CN)**
4. 点击 **下载** 按钮
5. 在 **站点语言环境** 选择 **简体中文**
6. 点击 **保存**
7. 按 F5 刷新页面

### 第 3 步：创建页面

按照以下顺序创建 18 个页面：

#### 首页 (1 个)

| 路径 | 标题 | 内容来源 |
|------|------|----------|
| `home` | OpenClaw Wiki - 首页 | 见下方内容模板 |

#### OpenClaw 部署 (3 个)

| 路径 | 标题 | 内容来源 |
|------|------|----------|
| `openclaw/deployment/server` | 服务端部署（带 Nginx 反向代理） | `/data/openclaw/openclaw-deploy/DEPLOYMENT.md` 第 2 章 |
| `openclaw/deployment/subagent` | 子节点部署（任务执行节点） | `/data/openclaw/openclaw-deploy/DEPLOYMENT.md` 第 3 章 |
| `openclaw/deployment/wiki` | Wiki.js 部署 | `/data/openclaw/wiki/WIKI-DEPLOYMENT.md` |

#### 配置文档 (4 个)

| 路径 | 标题 | 内容来源 |
|------|------|----------|
| `openclaw/configuration/gateway` | Gateway 配置 | `DEPLOYMENT.md` 第 5 章 |
| `openclaw/configuration/model` | 模型配置（阿里云百炼） | OpenClaw 配置经验 |
| `openclaw/configuration/dingtalk` | 钉钉集成 | 钉钉配置经验 |
| `openclaw/configuration/subagent` | 子节点管理 | 子节点管理经验 |

#### 故障排除 (4 个)

| 路径 | 标题 | 内容来源 |
|------|------|----------|
| `openclaw/troubleshooting/ssh` | SSH 连接问题 | `DEPLOYMENT.md` 第 4.1 节 |
| `openclaw/troubleshooting/nodejs` | Node.js 安装 | `DEPLOYMENT.md` 第 4.2 节 |
| `openclaw/troubleshooting/openclaw` | OpenClaw 问题 | `DEPLOYMENT.md` 第 4.3 节 |
| `openclaw/troubleshooting/gateway` | Gateway 问题 | `DEPLOYMENT.md` 第 4.4 节 |

#### 脚本库 (6 个)

| 路径 | 标题 | 内容来源 |
|------|------|----------|
| `scripts/deploy/deploy-nginx` | deploy-nginx.sh | `/data/deploy-nginx.sh` |
| `scripts/deploy/deploy-subagent` | deploy-subagent.sh | `/data/deploy-subagent.sh` |
| `scripts/deploy/deploy-wiki` | deploy-wiki.sh | `/data/deploy-wiki.sh` |
| `scripts/config/ip-txt` | ip.txt | `/data/ip.txt` |
| `scripts/config/ip-subagent-txt` | ip-subagent.txt | `/data/ip-subagent.txt` |
| `scripts/tools/set-nginx-password` | set-nginx-password.sh | `/data/set-nginx-password.sh` |

---

## 📝 页面内容模板

### 首页内容

```markdown
# 欢迎来到 OpenClaw Wiki

这是 OpenClaw 的官方文档和脚本库。

## 📦 快速开始

### 部署指南
- [服务端部署](/openclaw/deployment/server)
- [子节点部署](/openclaw/deployment/subagent)
- [Wiki.js 部署](/openclaw/deployment/wiki)

### 配置文档
- [Gateway 配置](/openclaw/configuration/gateway)
- [模型配置](/openclaw/configuration/model)
- [钉钉集成](/openclaw/configuration/dingtalk)

### 脚本库
- [部署脚本](/scripts/deploy)
- [配置文件](/scripts/config)
- [工具脚本](/scripts/tools)

### 故障排除
- [SSH 连接问题](/openclaw/troubleshooting/ssh)
- [Node.js 安装](/openclaw/troubleshooting/nodejs)
- [Gateway 问题](/openclaw/troubleshooting/gateway)
```

### 部署文档页面模板

```markdown
# 页面标题

## 适用场景

- 场景 1
- 场景 2

## 前置要求

- 要求 1
- 要求 2

## 脚本部署

### 步骤

```bash
# 命令
```

## 手工部署

### 步骤 1：标题

详细说明...

```bash
# 命令示例
```

### 步骤 2：标题

详细说明...

## 验证部署

```bash
# 验证命令
```

## 相关文档

- [链接 1]()
- [链接 2]()
```

### 脚本页面模板

```markdown
# 脚本名称

## 用途

这个脚本用于...

## 依赖

- 依赖 1
- 依赖 2

## 使用方法

```bash
./script-name.sh [参数]
```

## 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| arg1 | 说明 | value |

## 示例

```bash
# 示例 1
./script-name.sh arg1 arg2
```

## 完整脚本

```bash
# 粘贴完整脚本内容
```
```

---

## 🎯 导航菜单配置

创建完所有页面后，配置导航菜单：

1. **管理后台** → **导航**
2. 点击 **添加**
3. 按照以下结构添加菜单项：

```
🏠 首页
├── 📦 OpenClaw 部署
│   ├── 服务端部署
│   ├── 子节点部署
│   └── Wiki.js 部署
├── ⚙️ 配置文档
│   ├── Gateway 配置
│   ├── 模型配置
│   ├── 钉钉集成
│   └── 子节点管理
├── 📜 脚本库
│   ├── 部署脚本
│   ├── 配置文件
│   └── 工具脚本
└── 🔧 故障排除
    ├── SSH 连接问题
    ├── Node.js 安装
    ├── OpenClaw 问题
    └── Gateway 问题
```

4. 拖拽调整顺序和层级
5. 点击 **保存**

---

## ✅ 完成检查清单

### 基础配置
- [ ] 登录 Wiki.js
- [ ] 下载中文语言包
- [ ] 设置站点语言为中文
- [ ] 刷新页面确认中文界面

### 页面创建 (18 个)
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
- [ ] deploy-nginx.sh (`/scripts/deploy/deploy-nginx`)
- [ ] deploy-subagent.sh (`/scripts/deploy/deploy-subagent`)
- [ ] deploy-wiki.sh (`/scripts/deploy/deploy-wiki`)
- [ ] ip.txt (`/scripts/config/ip-txt`)
- [ ] ip-subagent.txt (`/scripts/config/ip-subagent-txt`)
- [ ] set-nginx-password.sh (`/scripts/tools/set-nginx-password`)

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
| 下载中文包 | 2 分钟 |
| 创建 18 个页面 | 60-90 分钟 |
| 配置导航菜单 | 15 分钟 |
| 测试验证 | 10 分钟 |
| **总计** | **约 1.5-2 小时** |

---

## 💡 提示

1. **批量操作**：可以先创建所有页面的框架（只填标题和路径），再逐个填充内容
2. **复制粘贴**：从 `/data/openclaw/` 下的 Markdown 文件复制内容
3. **自动保存**：Wiki.js 会自动保存草稿，不用担心丢失
4. **版本历史**：保存后可以查看和恢复历史版本
5. **预览功能**：编辑时可以点击预览查看效果

---

## 🔗 参考文档

- `/data/openclaw/wiki/WIKI-IMPORT-GUIDE.md` - 详细导入指南
- `/data/openclaw/wiki/WIKI-IMPORT-STRUCTURE.md` - 页面结构说明
- `/data/openclaw/openclaw-deploy/DEPLOYMENT.md` - OpenClaw 部署文档
- `/data/openclaw/wiki/WIKI-DEPLOYMENT.md` - Wiki.js 部署文档

---

**开始导入**: http://38.246.245.39

*最后更新：2026-03-16 08:57 UTC*
