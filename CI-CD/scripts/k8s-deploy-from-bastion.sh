#!/bin/bash
# K8s 集群部署脚本 - 从堡垒机执行
# 部署目标：3 节点集群 (1 Master + 2 Worker)

set -e

K8S_VERSION="1.29"
POD_NETWORK_CIDR="10.244.0.0/16"
MASTER_HOST="124.132.136.17"
MASTER_PORT="9005"
NODE1_PORT="9191"
NODE2_PORT="9053"
SSH_PASS="Huanxin0321"

echo "=========================================="
echo "  K8s 集群部署 - 3 节点"
echo "  Master: ${MASTER_HOST}:${MASTER_PORT}"
echo "  Node1:  ${MASTER_HOST}:${NODE1_PORT}"
echo "  Node2:  ${MASTER_HOST}:${NODE2_PORT}"
echo "=========================================="

# 阶段 1：所有节点预备
echo
echo "【阶段 1/5】所有节点预备配置..."

for port in 9005 9191 9053; do
    echo "  → 配置节点 :${port}..."
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no root@$MASTER_HOST -p $port << 'SSHSCRIPT'
# 关闭防火墙
systemctl stop firewalld || true
systemctl disable firewalld || true

# 关闭 SELinux
setenforce 0 || true
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# 配置系统参数
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# 安装 containerd
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y containerd.io
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# 安装 Kubernetes
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable kubelet
echo "节点 :${port} 预备完成"
SSHSCRIPT
done

echo "✅ 所有节点预备完成"

# 阶段 2：Master 节点初始化
echo
echo "【阶段 2/5】初始化 Master 节点..."

sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no root@$MASTER_HOST -p $MASTER_PORT << SSHSCRIPT
# 初始化集群
kubeadm init \
  --pod-network-cidr=$POD_NETWORK_CIDR \
  --apiserver-advertise-address=0.0.0.0 \
  --control-plane-endpoint=${MASTER_HOST}:${MASTER_PORT} \
  --upload-certs

# 配置 kubectl
mkdir -p \$HOME/.kube
cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
chown \$(id -u):\$(id -g) \$HOME/.kube/config

# 安装 Calico CNI
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

# 保存 join 命令
kubeadm token create --print-join-command > /tmp/join-command.sh
chmod +x /tmp/join-command.sh

echo "Master 节点初始化完成"
SSHSCRIPT

echo "✅ Master 节点初始化完成"

# 阶段 3：Worker 节点加入
echo
echo "【阶段 3/5】Worker 节点加入集群..."

# 获取 join 命令
JOIN_COMMAND=\$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no root@$MASTER_HOST -p $MASTER_PORT 'cat /tmp/join-command.sh')

# 在 node1 和 node2 执行
for port in $NODE1_PORT $NODE2_PORT; do
    echo "  → 加入 node :${port}..."
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no root@$MASTER_HOST -p $port << SSHSCRIPT
$JOIN_COMMAND
echo "Node :${port} 已加入集群"
SSHSCRIPT
done

echo "✅ Worker 节点加入完成"

# 阶段 4：验证集群
echo
echo "【阶段 4/5】验证集群状态..."

sleep 30  # 等待节点加入

sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no root@$MASTER_HOST -p $MASTER_PORT << 'SSHSCRIPT'
echo "节点状态:"
kubectl get nodes -o wide

echo
echo "系统 Pod 状态:"
kubectl get pods -n kube-system -o wide

echo
echo "集群信息:"
kubectl cluster-info
SSHSCRIPT

echo "✅ 集群验证完成"

# 阶段 5：部署测试应用
echo
echo "【阶段 5/5】部署测试应用..."

sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no root@$MASTER_HOST -p $MASTER_PORT << 'SSHSCRIPT'
# 部署 Nginx 测试
kubectl create deployment nginx-test --image=nginx:latest
kubectl expose deployment nginx-test --port=80 --type=NodePort

# 等待 Pod 就绪
sleep 10
kubectl get pods

# 获取 NodePort
NODE_PORT=\$(kubectl get svc nginx-test -o jsonpath='{.spec.ports[0].nodePort}')
echo "Nginx 测试应用已部署"
echo "访问地址：http://${MASTER_HOST}:\${NODE_PORT}"
SSHSCRIPT

echo "✅ 测试应用部署完成"

echo
echo "=========================================="
echo "  K8s 集群部署完成！"
echo "=========================================="
echo
echo "Master: http://${MASTER_HOST}:${MASTER_PORT}"
echo "管理命令:"
echo "  ssh root@${MASTER_HOST} -p ${MASTER_PORT}"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo
