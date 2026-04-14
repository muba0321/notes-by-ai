#!/bin/bash
# K8s 节点预备脚本
# 用法：bash k8s-prepare.sh

set -e

echo "=========================================="
echo "  K8s 节点预备 - $(hostname)"
echo "=========================================="

# 1. 系统配置
echo "[1/6] 配置系统参数..."
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# 2. 安装 containerd
echo "[2/6] 安装 containerd..."
apt-get update
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# 3. 安装 Kubernetes 工具
echo "[3/6] 安装 kubeadm/kubelet/kubectl..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | apt-key add -
echo 'deb https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' > /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# 4. 启用 kubelet
echo "[4/6] 启用 kubelet..."
systemctl enable kubelet

echo "=========================================="
echo "  预备完成！"
echo "=========================================="
echo
echo "验证命令:"
echo "  containerd --version"
echo "  kubeadm version"
echo "  kubelet --version"
echo "  kubectl version --client"
