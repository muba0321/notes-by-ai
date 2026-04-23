# 网络配置记录

## 服务器信息

| 服务器 | 公网 IP | 域名 | 用途 |
|--------|---------|------|------|
| 主服务器 | 38.246.245.32 | openclaw.mubai.top | OpenClaw Gateway |
| 子节点 1 | 39.246.245.39 | product.mubai.top | 需要 nginx 反向代理 |

## 端口配置

- OpenClaw Gateway 端口：`18789`
- Nginx 反向代理：`product.mubai.top` → `localhost:18789`

## 配置要点

1. 子节点 1 (39.246.245.39) 需要配置 nginx 反向代理
2. 域名 `product.mubai.top` 指向 39.246.245.39
3. Gateway 配置需要设置 `gateway.remote.url` 为 `wss://product.mubai.top`

## 历史问题

- Ping 超时但 SSH 可用（ICMP 被阻止，正常）
- Gateway 默认 bind=lan，只广告局域网 IP，远程节点无法连接
- 需要配置公网 URL 或 Tailscale Serve
