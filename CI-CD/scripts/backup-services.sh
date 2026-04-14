#!/bin/bash
# CI/CD 服务备份脚本
# 用法：./backup-services.sh [备份目录]

set -e

BACKUP_DIR=${1:-/data/backup}
DATE=$(date +%Y%m%d_%H%M%S)
MONITORING_DIR=/data/monitoring

echo "=========================================="
echo "  CI/CD 服务备份"
echo "=========================================="
echo "备份目录：$BACKUP_DIR"
echo "日期：$DATE"
echo

# 创建备份目录
mkdir -p $BACKUP_DIR

echo "【1. 备份 Jenkins 数据】"
JENKINS_BACKUP="$BACKUP_DIR/jenkins-backup-$DATE.tar.gz"
tar czf $JENKINS_BACKUP -C $MONITORING_DIR jenkins/home
echo "✓ Jenkins 备份完成：$JENKINS_BACKUP"
ls -lh $JENKINS_BACKUP

echo
echo "【2. 备份 Grafana 数据】"
GRAFANA_BACKUP="$BACKUP_DIR/grafana-backup-$DATE.tar.gz"
tar czf $GRAFANA_BACKUP -C $MONITORING_DIR grafana/data
echo "✓ Grafana 备份完成：$GRAFANA_BACKUP"
ls -lh $GRAFANA_BACKUP

echo
echo "【3. 备份 Prometheus 数据】"
PROMETHEUS_BACKUP="$BACKUP_DIR/prometheus-backup-$DATE.tar.gz"
docker exec prometheus tar czf - /prometheus > $PROMETHEUS_BACKUP
echo "✓ Prometheus 备份完成：$PROMETHEUS_BACKUP"
ls -lh $PROMETHEUS_BACKUP

echo
echo "【4. 备份配置文件】"
CONFIG_BACKUP="$BACKUP_DIR/configs-backup-$DATE.tar.gz"
tar czf $CONFIG_BACKUP \
    $MONITORING_DIR/docker-compose.yml \
    $MONITORING_DIR/prometheus/prometheus.yml \
    2>/dev/null || true
echo "✓ 配置文件备份完成：$CONFIG_BACKUP"
ls -lh $CONFIG_BACKUP

echo
echo "【5. 清理旧备份（保留最近 7 天）】"
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
echo "✓ 旧备份已清理"

echo
echo "=========================================="
echo "  备份完成"
echo "=========================================="
echo
echo "备份文件列表:"
ls -lh $BACKUP_DIR/*.tar.gz
