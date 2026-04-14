# 手机 Node 配对指南

**更新时间：** 2026-03-24  
**状态：** 配置完成，等待配对

---

## 📱 配对方式

### 方式一：二维码配对（推荐）⭐

#### 步骤 1：下载 Node App

**Android：**
- 下载地址：https://github.com/openclaw/openclaw-node-android/releases
- 或 Google Play: 搜索 "OpenClaw Node"

**iOS：**
- App Store: 搜索 "OpenClaw Node"

**macOS：**
- 下载地址：https://github.com/openclaw/openclaw-node-macos/releases

#### 步骤 2：打开 Node App

1. 安装并打开 Node App
2. 点击 "配对新设备" 或 "Pair New Device"
3. 进入扫码界面

#### 步骤 3：生成配对二维码

**在 Webchat 页面：**
1. 点击右上角 "Nodes" 或 "设备"
2. 点击 "Generate Setup Code" 或 "生成配对码"
3. 显示二维码

**或使用命令行：**
```bash
# 生成配对码
openclaw nodes pairing generate
```

#### 步骤 4：扫描二维码

1. 用手机 App 扫描二维码
2. 确认配对信息
3. 点击 "确认配对"

#### 步骤 5：配对成功

```
✅ 配对成功！

设备信息：
- 设备名称：iPhone 15 Pro
- 设备类型：iOS
- 连接状态：已连接
```

---

### 方式二：手动输入配对码

#### 步骤 1：生成配对码

**在 Webchat 页面：**
```
配对码：XXXX-XXXX-XXXX
（6 位数字或字母）
```

**或使用命令行：**
```bash
# 生成 6 位配对码
openclaw nodes pairing code
```

#### 步骤 2：手机输入配对码

1. 打开 Node App
2. 选择 "手动输入配对码"
3. 输入 6 位配对码
4. 点击 "连接"

#### 步骤 3：确认配对

```
配对请求：
设备：iPhone 15 Pro
IP: 192.168.1.100

[批准] [拒绝]
```

---

### 方式三：局域网自动发现

#### 条件

- 手机和 Gateway 在同一局域网
- 已启用自动发现功能

#### 步骤

1. 打开 Node App
2. 点击 "扫描附近设备"
3. 选择发现的 Gateway
4. 确认配对

---

## 🔧 配置说明

### Gateway 配置

```json
{
  "plugins": {
    "entries": {
      "device-pair": {
        "enabled": true
      }
    }
  },
  "gateway": {
    "bind": "lan",  // 绑定局域网所有接口
    "port": 18789
  }
}
```

### 网络要求

| 项目 | 要求 |
|------|------|
| Gateway 端口 | 18789 (TCP) |
| 网络类型 | 局域网/公网 |
| 防火墙 | 允许 18789 端口 |

---

## 🌐 远程连接配置

### 场景：手机用 4G/5G 连接（不在同一局域网）

#### 配置公网访问

**方式 1：公网 IP + 端口映射**

```bash
# 路由器配置
端口映射：18789 → 10.0.118.4:18789

# 防火墙开放
ufw allow 18789/tcp
```

**方式 2：内网穿透（推荐）**

```bash
# 使用 frp
[openclaw]
type = tcp
local_ip = 10.0.118.4
local_port = 18789
remote_port = 18789

# 手机连接
frp 服务器 IP:18789
```

**方式 3：Tailscale（最简单）**

```bash
# Gateway 服务器安装 Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# 手机安装 Tailscale App
# 登录同一账号

# 手机连接 Tailscale IP:18789
```

---

## 📊 配对状态查看

### Webchat 页面

```
Nodes 页面
├── Paired Devices (已配对设备)
│   └── iPhone 15 Pro - 在线
├── Pending Requests (待批准请求)
│   └── Android - 等待批准
└── Generate Setup Code (生成配对码)
```

### 命令行

```bash
# 查看已配对设备
openclaw nodes status

# 查看待批准请求
openclaw nodes pending

# 批准配对请求
openclaw nodes approve <device-id>

# 拒绝配对请求
openclaw nodes reject <device-id>
```

---

## 🔍 故障排查

### 问题 1：扫码无反应

**原因：** 网络不通

**解决：**
1. 检查 Gateway 是否运行
2. 检查防火墙是否开放 18789
3. 确认手机和 Gateway 网络连通

### 问题 2：配对码无效

**原因：** 配对码过期

**解决：**
1. 重新生成配对码
2. 配对码有效期 5 分钟
3. 尽快输入

### 问题 3：连接后掉线

**原因：** 网络不稳定

**解决：**
1. 检查网络质量
2. 使用 Tailscale 等稳定连接
3. 配置自动重连

---

## 📝 当前配置状态

### Gateway 状态

```
✅ 设备配对功能：已启用
✅ Gateway 端口：18789
✅ 绑定地址：0.0.0.0 (局域网所有接口)
⚠️ 公网访问：未配置
```

### 已配对设备

```
当前：无设备
```

### 待批准请求

```
当前：无请求
```

---

## 🚀 快速开始

### 立即配对（同一局域网）

1. **手机下载 Node App**
   - Android: https://github.com/openclaw/openclaw-node-android/releases
   - iOS: App Store 搜索 "OpenClaw Node"

2. **打开 Webchat 页面**
   - http://10.0.118.4:18789
   - 或 http://38.246.245.39:18789

3. **生成配对码**
   - 点击 Nodes → Generate Setup Code

4. **手机扫码连接**
   - 打开 Node App → 扫描二维码

5. **配对成功！**
   - 手机可以聊天、语音、推送

---

**文档版本：** 1.0  
**最后更新：** 2026-03-24  
**维护者：** OpenClaw Agent
