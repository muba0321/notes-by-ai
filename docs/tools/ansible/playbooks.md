# 常用 Playbook 示例

_Ansible Playbook 编写与执行_

---

## 一、基础环境初始化

`/root/ansible/playbooks/init.yml`:

```yaml
---
- name: 初始化所有节点
  hosts: k8s_cluster
  become: yes
  gather_facts: yes
  
  tasks:
    - name: 更新 apt 缓存
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: 安装基础工具
      apt:
        name:
          - curl
          - wget
          - vim
          - net-tools
          - apt-transport-https
          - ca-certificates
        state: present

    - name: 关闭 swap
      shell: |
        swapoff -a
        sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
      changed_when: false

    - name: 加载内核模块
      modprobe:
        name: "{{ item }}"
        state: present
      loop:
        - overlay
        - br_netfilter

    - name: 设置内核参数
      sysctl:
        name: "{{ item.name }}"
        value: "{{ item.value }}"
        state: present
        reload: yes
      loop:
        - { name: 'net.bridge.bridge-nf-call-iptables', value: '1' }
        - { name: 'net.bridge.bridge-nf-call-ip6tables', value: '1' }
        - { name: 'net.ipv4.ip_forward', value: '1' }

    - name: 设置时区
      timezone:
        name: Asia/Shanghai
```

**执行：**
```bash
ansible-playbook -i inventory/hosts.ini playbooks/init.yml
```

---

## 二、部署 k3s 集群

`/root/ansible/playbooks/k3s-deploy.yml`:

```yaml
---
- name: 部署 k3s Server
  hosts: master1
  become: yes
  
  tasks:
    - name: 下载 k3s 安装脚本
      get_url:
        url: https://get.k3s.io
        dest: /tmp/k3s-install.sh
        mode: '0755'

    - name: 安装 k3s server
      shell: |
        INSTALL_K3S_EXEC="--cluster-init \
          --node-ip {{ ansible_host }} \
          --flannel-backend=wireguard-native \
          --disable traefik" \
        /tmp/k3s-install.sh
      args:
        creates: /usr/local/bin/k3s

    - name: 等待 k3s 启动
      wait_for:
        path: /var/lib/rancher/k3s/server/node-token
        timeout: 60

    - name: 获取 node token
      command: cat /var/lib/rancher/k3s/server/node-token
      register: k3s_token
      changed_when: false

    - name: 创建 token 文件（供 agent 使用）
      copy:
        content: "{{ k3s_token.stdout }}"
        dest: /tmp/k3s_token.txt
        mode: '0600'

    - name: 配置 kubectl
      shell: |
        mkdir -p $HOME/.kube
        cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
        chmod 600 $HOME/.kube/config

- name: 部署 k3s Agent
  hosts: workers
  become: yes
  
  tasks:
    - name: 从 master 获取 token
      fetch:
        src: /tmp/k3s_token.txt
        dest: /tmp/k3s_token.txt
        flat: yes
      delegate_to: master1

    - name: 读取 token
      command: cat /tmp/k3s_token.txt
      register: k3s_token
      changed_when: false

    - name: 下载 k3s 安装脚本
      get_url:
        url: https://get.k3s.io
        dest: /tmp/k3s-install.sh
        mode: '0755'

    - name: 安装 k3s agent
      shell: |
        INSTALL_K3S_EXEC="--server https://124.132.136.17:9005 \
          --token {{ k3s_token.stdout }} \
          --node-ip {{ ansible_host }}" \
        /tmp/k3s-install.sh
      args:
        creates: /usr/local/bin/k3s
```

**执行：**
```bash
ansible-playbook -i inventory/hosts.ini playbooks/k3s-deploy.yml
```

---

## 三、验证集群

`/root/ansible/playbooks/verify.yml`:

```yaml
---
- name: 验证 k3s 集群
  hosts: master1
  become: yes
  
  tasks:
    - name: 检查节点状态
      command: kubectl get nodes -o wide
      register: nodes
      changed_when: false

    - name: 显示节点
      debug:
        var: nodes.stdout_lines

    - name: 检查系统 Pod
      command: kubectl get pods -A
      register: pods
      changed_when: false

    - name: 显示 Pod 状态
      debug:
        var: pods.stdout_lines
```

---

## 四、批量管理任务

### 1. 批量更新系统
```yaml
- name: 批量更新
  hosts: k8s_cluster
  become: yes
  tasks:
    - name: 更新所有包
      apt:
        upgrade: dist
        update_cache: yes
```

### 2. 批量重启
```yaml
- name: 批量重启
  hosts: k8s_cluster
  become: yes
  serial: 1  # 一次一台
  tasks:
    - name: 重启
      reboot:
        reboot_timeout: 300
```

### 3. 部署文件
```yaml
- name: 部署配置文件
  hosts: k8s_cluster
  tasks:
    - name: 拷贝配置
      copy:
        src: /root/config/app.conf
        dest: /etc/app/
        mode: '0644'
```

---

## 五、执行 Playbook

```bash
# 基础执行
ansible-playbook -i inventory/hosts.ini playbooks/init.yml

# 带变量执行
ansible-playbook -i inventory/hosts.ini playbooks/k3s.yml \
  -e 'k3s_version=v1.29.0'

# 只运行特定标签
ansible-playbook -i inventory/hosts.ini playbooks/init.yml \
  --tags "packages,kernel"

# 检查模式（不实际执行）
ansible-playbook -i inventory/hosts.ini playbooks/init.yml \
  --check

# 详细日志
ansible-playbook -i inventory/hosts.ini playbooks/init.yml \
  -vvv
```

---

## 六、Playbook 调试

```bash
# 单步调试
ansible-playbook -i inventory/hosts.ini playbooks/init.yml \
  --step

# 从指定任务开始
ansible-playbook -i inventory/hosts.ini playbooks/init.yml \
  --start-at-task="安装基础工具"

# 只运行失败的任务
ansible-playbook -i inventory/hosts.ini playbooks/init.yml \
  --retry
```

---

**上一篇：** [主机清单配置](inventory.md)  
**下一篇：** [K8s 集群部署](k8s-deploy.md)
