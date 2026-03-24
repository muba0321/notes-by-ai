# Webchat 多 Session 并行沟通指南

**更新时间：** 2026-03-24  
**状态：** 配置说明

---

## 📖 Webchat 多 Session 支持

### ✅ 原生支持

OpenClaw Webchat **原生支持多 Session 并行沟通**，多个人可以同时使用不同的浏览器/设备访问，每个会话独立。

---

## 🎯 工作原理

### Session 隔离架构

```
┌─────────────────────────────────────────────────────────┐
│                    OpenClaw Gateway                      │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  用户 A      │  │  用户 B      │  │  用户 C      │  │
│  │  Session 1   │  │  Session 2   │  │  Session 3   │  │
│  │  webchat_abc │  │  webchat_def │  │  webchat_ghi │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │           │
│         └─────────────────┼─────────────────┘           │
│                           │                             │
│                  ┌────────▼────────┐                    │
│                  │   Agent Core    │                    │
│                  │  (共享记忆)     │                    │
│                  └─────────────────┘                    │
└─────────────────────────────────────────────────────────┘
```

### 隔离与共享

| 隔离项 | 共享项 |
|--------|--------|
| Session ID | MEMORY.md |
| 对话历史 | memory/*.md |
| 上下文窗口 | 项目文件 |
| 临时变量 | 工具配置 |
| 消息队列 | Git 仓库 |

---

## 🧪 测试方法

### 场景 1：两个用户同时访问

```
用户 A:
1. 打开 Chrome 浏览器
2. 访问 http://38.246.245.39:18789
3. 发送"你好，我是用户 A"
4. 得到回复："你好，用户 A！有什么可以帮你？"

用户 B (同时):
1. 打开 Firefox 浏览器（或 Chrome 隐私模式）
2. 访问 http://38.246.245.39:18789
3. 发送"你好，我是用户 B"
4. 得到回复："你好，用户 B！有什么可以帮你？"

结果:
✅ 两个独立 Session
✅ 对话历史不共享
✅ 同时处理无冲突
```

### 场景 2：查看 Sessions

```bash
# 查看当前活跃 Sessions
openclaw sessions list

# 或使用 API
curl http://localhost:18789/api/sessions
```

### 场景 3：跨 Session 记忆共享

```
用户 A (Session 1):
"记住我喜欢 Python"
→ Agent: "好的，已记录你喜欢 Python"
→ 写入 MEMORY.md

用户 B (Session 2):
"用户 A 喜欢什么？"
→ Agent 读取 MEMORY.md
→ 回复："用户 A 喜欢 Python"
```

---

## 🔧 配置说明

### Webchat 配置（Gateway）

```json
{
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan",
    "controlUi": {
      "enabled": true,
      "allowedOrigins": [
        "http://localhost:18789",
        "http://127.0.0.1:18789",
        "http://38.246.245.39:18789",
        "https://openclaw.mubai.top"
      ],
      "allowInsecureAuth": true,
      "dangerouslyDisableDeviceAuth": true
    }
  }
}
```

### Session 配置

- **Session ID 生成：** 自动为每个新连接生成唯一 ID
- **Session 超时：** 默认 30 分钟无活动后过期
- **最大 Sessions：** 无限制（受服务器资源限制）

---

## 📊 使用场景

### 场景 1：团队协作

```
开发团队 (5 人):
- 每个人打开 Webchat
- 独立提问/下指令
- 共享项目记忆
- 协作完成部署
```

### 场景 2：家庭共享

```
家庭成员 (3 人):
- 爸爸：查询天气/新闻
- 妈妈：设置提醒/日历
- 孩子：问问题/学习
- 各自独立对话
```

### 场景 3：多项目管理

```
项目经理:
- Session 1: K8s 项目
- Session 2: MHA 项目
- Session 3: 日常运维
- 每个项目独立上下文
```

---

## 🚀 访问方式

### 本地访问

```
http://localhost:18789
http://127.0.0.1:18789
```

### 远程访问

```
http://38.246.245.39:18789
https://openclaw.mubai.top
```

### 多人同时访问

```
用户 A: http://38.246.245.39:18789 (Chrome)
用户 B: http://38.246.245.39:18789 (Firefox)
用户 C: http://38.246.245.39:18789 (Safari)
用户 D: http://38.246.245.39:18789 (Edge)

所有用户同时访问，各自独立 Session！
```

---

## ⚙️ Session 管理

### 查看 Sessions

```bash
# 列出所有 Sessions
openclaw sessions list

# 查看 Session 详情
openclaw sessions info <session-id>

# 查看历史
openclaw sessions history <session-id>
```

### 清理 Sessions

```bash
# 清理过期 Sessions
openclaw sessions cleanup

# 删除特定 Session
openclaw sessions delete <session-id>
```

---

## 🔍 故障排查

### 问题 1：Session 冲突

**现象：** 两个用户看到对方对话

**原因：** 浏览器缓存/Cookie 共享

**解决：**
1. 使用隐私模式
2. 清除 Cookie
3. 使用不同浏览器

### 问题 2：Session 丢失

**现象：** 刷新页面后对话历史丢失

**原因：** Session 过期或 Cookie 被清除

**解决：**
1. 检查 Session 超时设置
2. 启用 Cookie 持久化
3. 使用书签保存 Session

### 问题 3：并发性能

**现象：** 多人同时使用时响应慢

**原因：** 服务器资源不足

**解决：**
1. 增加服务器资源
2. 优化模型配置
3. 使用缓存

---

## 📝 最佳实践

### 推荐用法

1. **固定浏览器** - 每人固定使用一个浏览器
2. **隐私模式** - 共享电脑时使用隐私模式
3. **定期清理** - 定期清理过期 Sessions
4. **记忆管理** - 重要信息写入 MEMORY.md

### 避免问题

1. **不要共享浏览器** - 避免 Session 混乱
2. **及时保存** - 重要对话导出保存
3. **注意隐私** - 敏感信息加密存储

---

## 📞 支持

| 问题类型 | 解决方案 |
|----------|----------|
| Session 管理 | `openclaw sessions` 命令 |
| 配置问题 | 查看 Gateway 配置 |
| 性能问题 | 检查服务器资源 |

---

**文档版本：** 1.0  
**最后更新：** 2026-03-24  
**维护者：** OpenClaw Agent
