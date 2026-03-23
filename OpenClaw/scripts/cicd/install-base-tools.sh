#!/bin/bash
# install-base-tools.sh
# 用途：安装 Docker、Ansible、Git、kubectl、Helm 等基础工具
# 适用系统：Ubuntu 22.04+

set -e

echo "=========================================="
echo "  安装 CI/CD 基础工具"
echo "=========================================="

# 更新系统
echo "[1/6] 更新系统..."
apt update && apt upgrade -y

# 安装 Docker
echo "[2/6] 安装 Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    systemctl status docker --no-pager
else
    echo "Docker 已安装，跳过"
fi

# 安装 Ansible
echo "[3/6] 安装 Ansible..."
if ! command -v ansible &> /dev/null; then
    apt install -y software-properties-common
    add-apt-repository --yes --update ppa:ansible/ansible
    apt install -y ansible
    ansible --version
else
    echo "Ansible 已安装，跳过"
fi

# 安装 Git
echo "[4/6] 安装 Git..."
if ! command -v git &> /dev/null; then
    apt install -y git
    git --version
else
    echo "Git 已安装，跳过"
fi

# 安装 kubectl
echo "[5/6] 安装 kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
    kubectl version --client
else
    echo "kubectl 已安装，跳过"
fi

# 安装 Helm
echo "[6/6] 安装 Helm..."
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    helm version
else
    echo "Helm 已安装，跳过"
fi

# 验证安装
echo ""
echo "=========================================="
echo "  验证安装"
echo "=========================================="
echo "Docker: $(docker --version)"
echo "Ansible: $(ansible --version | head -1)"
echo "Git: $(git --version)"
echo "kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
echo "Helm: $(helm version --short)"

# Docker 权限配置
echo ""
echo "=========================================="
echo "  配置 Docker 权限"
echo "=========================================="
if ! getent group docker > /dev/null; then
    groupadd docker
fi
usermod -aG docker $SUDO_USER 2>/dev/null || usermod -aG docker root
echo "已将用户加入 docker 组，请重新登录或执行：newgrp docker"

echo ""
echo "=========================================="
echo "  基础工具安装完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 重新登录或执行：newgrp docker"
echo "2. 运行：./install-jenkins.sh"
echo ""
