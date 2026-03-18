# OpenClaw 配置文件说明

_所有配置文件的详细说明和使用指南_

---

## 📁 配置文件列表

| 文件 | 用途 | 格式 |
|------|------|------|
| [`ip-subagent.txt`](#ip-subagenttxt) | 子节点服务器列表 | 自定义 |
| [`lessons.md`](#lessonsmd) | 踩坑记录与解决方案 | Markdown |

---

## 📄 配置文件详解

### ip-subagent.txt

**用途：** 存储子节点服务器连接信息，供 `deploy-subagent.sh` 脚本使用

**位置：** `/data/openclaw-dist/OpenClaw/配置/ip-subagent.txt`

**格式：**
```
IP:SSH 端口：用户名：密码：主机名
```

**示例：**
```bash
# 单台服务器
38.246.245.39:22:root:Huanxin0321:mubai-subagent1

# 多台服务器（每行一个）
192.168.1.100:22:root:password123:subagent-1
10.0.0.50:2222:admin:secret456:subagent-2
```

**字段说明：**

| 字段 | 说明 | 示例 |
|------|------|------|
| IP | 服务器 IP 地址（公网或内网） | 38.246.245.39 |
| SSH 端口 | SSH 服务端口 | 22 |
| 用户名 | SSH 登录用户 | root |
| 密码 | SSH 登录密码 | Huanxin0321 |
| 主机名 | 自定义主机名 | mubai-subagent1 |

**使用方法：**
```bash
# 1. 编辑配置文件
vi /data/openclaw-dist/OpenClaw/配置/ip-subagent.txt

# 2. 添加服务器信息
38.246.245.39:22:root:YourPassword:your-hostname

# 3. 执行部署脚本
cd /data/openclaw-dist/OpenClaw/子节点
./deploy-subagent.sh
```

**⚠️ 安全提示：**
- 此文件包含明文密码，请妥善保管
- 建议部署后删除或加密
- 不要提交到公共 Git 仓库

---

### lessons.md

**用途：** 记录部署和运维过程中遇到的问题与解决方案

**位置：** `/data/openclaw-dist/OpenClaw/配置/lessons.md`

**问题分级：**

| 等级 | 图标 | 说明 |
|------|------|------|
| 严重 | 🔴 | 导致服务不可用、数据丢失 |
| 中等 | 🟠 | 影响部分功能、需要变通方案 |
| 轻微 | 🟡 | 小问题、有明确解决方案 |

**记录格式：**
```markdown
### [等级] 问题标题

**时间：** YYYY-MM-DD
**影响范围：** 影响的功能或系统

#### 问题描述
...

#### 环境信息
...

#### 排查过程
...

#### 原因分析
...

#### 解决方案
...

#### 教训总结
...
```

**使用方法：**
```bash
# 1. 编辑配置文件
vi /data/openclaw-dist/OpenClaw/配置/lessons.md

# 2. 添加新问题（按模板格式）

# 3. Git 提交
cd /data/openclaw-dist
git add OpenClaw/配置/lessons.md
git commit -m "docs: 记录 XXX 问题"
git push
```

---

## 🔧 配置文件管理

### Git 版本控制

```bash
# 查看配置文件变更
cd /data/openclaw-dist
git status

# 提交配置变更
git add OpenClaw/配置/
git commit -m "config: 更新配置说明"
git push origin main
```

### ⚠️ 敏感信息处理

**不要提交到 Git 的内容：**
- 明文密码
- API Token
- 密钥文件

**处理方法：**
```bash
# 1. 在 .gitignore 中忽略敏感文件
echo "ip-subagent.txt" >> .gitignore

# 2. 或使用示例文件
cp ip-subagent.txt ip-subagent.txt.example
# 编辑 example 文件，删除真实密码
git add ip-subagent.txt.example
git commit -m "添加配置示例"
```

---

## 📋 配置检查清单

部署前检查：

- [ ] `ip-subagent.txt` 中的 IP 地址正确
- [ ] SSH 端口可访问
- [ ] 用户名密码正确
- [ ] 主机名不重复
- [ ] 已备份原配置

---

## 🔗 相关文档

- [子节点部署](../子节点/openclaw 子节点部署.md)
- [服务端部署](../服务端/openclaw 服务端部署 v2.md)
- [踩坑记录](./lessons.md)

---

**最后更新：** 2026-03-18  
**维护者：** OpenClaw Team
