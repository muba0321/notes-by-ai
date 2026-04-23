# Bitwarden 密码管理平台部署

## 部署概览

- **部署日期：** 2026-03-31
- **数据服务器：** mubai-subagent2 (154.193.217.121)
- **代理服务器：** mubai-subagent1 (38.246.245.39)
- **状态：** ✅ 运行中 (HTTPS)
- **访问地址：** https://pw.mubai.top

## 技术栈

- **核心服务：** Vaultwarden (Bitwarden 轻量实现)
- **反向代理：** Nginx (子节点 1)
- **SSL 证书：** Let's Encrypt (自动续期)
- **部署方式：** Docker Compose

## 配置详情

### 部署路径
```
/opt/bitwarden/
├── docker-compose.yml
├── nginx.conf
├── data/                 # 密码数据目录
├── backups/              # 自动备份目录
├── backup.sh             # 备份脚本
├── restore.sh            # 恢复脚本
└── docs/
    └── DEPLOYMENT.md     # 详细文档
```

### 备份策略
- **自动备份：** 每天 02:00 (Cron)
- **备份保留：** 7 天
- **备份内容：** data 目录 + 配置文件

### 安全配置
- 注册：关闭（需邀请）
- Admin Token: BitwardenAdmin2026!Secure
- WebSocket: 启用
- 默认语言：zh-CN（中文）
- **HTTPS：** ✅ 已启用 (Let's Encrypt)
- **域名：** https://pw.mubai.top

### 初始账户
- **邮箱：** `1097648946@qq.com`
- **密码：** `huanxin0321`
- **组织：** 我的密码库

## 运维命令

```bash
# 查看状态
cd /opt/bitwarden && docker compose ps

# 查看日志
docker logs bitwarden --tail 100

# 手动备份
/opt/bitwarden/backup.sh

# 恢复数据
/opt/bitwarden/restore.sh <备份文件>
```

## 待办事项

- [ ] 配置 HTTPS (Let's Encrypt)
- [ ] 修改默认 Admin Token
- [ ] 配置防火墙规则
- [ ] 设置监控告警

## 相关文档

- 详细文档：/opt/bitwarden/docs/DEPLOYMENT.md
- GitHub 同步：待推送至 notes-by-ai 仓库
