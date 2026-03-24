#!/bin/bash
# install-jenkins.sh
# 用途：使用 Docker 部署 Jenkins
# 适用系统：Ubuntu 22.04+

set -e

JENKINS_VERSION="2.400-lts"
JENKINS_HOME="/data/jenkins"

echo "=========================================="
echo "  部署 Jenkins"
echo "=========================================="
echo "版本：$JENKINS_VERSION"
echo "数据目录：$JENKINS_HOME"
echo ""

# 创建数据目录
echo "[1/4] 创建数据目录..."
mkdir -p $JENKINS_HOME
chown -R 1000:1000 $JENKINS_HOME
chmod -R 755 $JENKINS_HOME

# 拉取镜像
echo "[2/4] 拉取 Jenkins 镜像..."
docker pull jenkins/jenkins:$JENKINS_VERSION

# 停止旧容器（如果存在）
echo "[3/4] 清理旧容器..."
if docker ps -a | grep -q jenkins; then
    echo "检测到旧 Jenkins 容器，停止并删除..."
    docker stop jenkins 2>/dev/null || true
    docker rm jenkins 2>/dev/null || true
fi

# 启动容器
echo "[4/4] 启动 Jenkins 容器..."
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v $JENKINS_HOME:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/bin/docker:/usr/bin/docker \
  -e JAVA_OPTS="-Xmx2048m -Dhudson.slaves.NodeProvisioner.initialDelay=0" \
  jenkins/jenkins:$JENKINS_VERSION

# 等待 Jenkins 启动
echo ""
echo "等待 Jenkins 启动..."
sleep 30

# 检查容器状态
if docker ps | grep -q jenkins; then
    echo "✓ Jenkins 容器运行正常"
else
    echo "✗ Jenkins 容器启动失败，请检查日志："
    docker logs jenkins
    exit 1
fi

# 获取初始管理员密码
echo ""
echo "=========================================="
echo "  Jenkins 部署完成！"
echo "=========================================="
echo ""
echo "访问地址：http://<服务器 IP>:8080"
echo ""
echo "初始管理员密码："
echo "----------------------------------------"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
echo "----------------------------------------"
echo ""
echo "下一步："
echo "1. 访问 http://<服务器 IP>:8080"
echo "2. 输入上述密码完成初始化"
echo "3. 安装推荐插件"
echo "4. 创建管理员账号"
echo ""
echo "查看日志：docker logs jenkins"
echo "停止服务：docker stop jenkins"
echo "启动服务：docker start jenkins"
echo ""
