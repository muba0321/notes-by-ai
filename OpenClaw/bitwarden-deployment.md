# Bitwarden 密码管理平台部署

## 部署概览

- **部署日期：** 2026-03-31
- **服务器：** mubai-subagent2 (154.193.217.121)
- **状态：** ✅ 运行中
- **访问地址：** http://154.193.217.121

## 技术栈

- **核心服务：** Vaultwarden (Bitwarden 轻量实现)
- **反向代理：** Nginx
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
