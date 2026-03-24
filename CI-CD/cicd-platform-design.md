# CI/CD 平台产品流程设计方案

_基于 Jenkins + GitHub + Ansible + K8s 的通用持续集成/持续部署平台_

**创建日期：** 2026-03-23  
**最后更新：** 2026-03-23  
**作者：** OpenClaw 子节点 1  
**状态：** approved  
**版本：** 1.0

---

## 📌 概述

### 产品定位

一个**通用的、可扩展的** CI/CD 平台，基于开源组件（Jenkins + GitHub + Ansible + K8s），支持多种部署场景和业务流程。

### 目标用户

| 用户角色 | 需求 |
|----------|------|
| **开发团队** | 快速构建、测试、部署应用 |
| **运维团队** | 自动化部署、配置管理、环境一致性 |
| **测试团队** | 自动化测试、质量门禁 |
| **技术负责人** | 流程可视化、审批控制、审计追踪 |

### 核心价值

- **开源免费** — 无 License 成本
- **灵活可扩展** — 支持多种场景
- **成熟稳定** — 组件均为业界标准
- **与现有工具链集成** — GitHub、K8s、Ansible

---

## 🏗️ 平台架构

### 核心组件

```
┌─────────────────────────────────────────────────────────────┐
│                        GitHub                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  代码仓库   │  │  Webhook    │  │  Pull Request│         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                            │ (Webhook)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                     Jenkins (子节点 1)                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Pipeline   │  │  构建任务   │  │  部署任务   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  测试报告   │  │  质量门禁   │  │  审批流程   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                            │ (SSH/API)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Ansible (自动化引擎)                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Playbooks  │  │  Inventory  │  │  Roles      │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                            │ (SSH/K8s API)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   K8s 集群 (4 台机器)                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Master    │  │   Node 1    │  │   Node 2    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│  ┌─────────────┐                                            │
│  │   Node 3    │                                            │
│  └─────────────┘                                            │
└─────────────────────────────────────────────────────────────┘
```

### 组件说明

| 组件 | 版本 | 用途 | 部署位置 |
|------|------|------|---------|
| **GitHub** | 云端/Enterprise | 代码托管、Webhook 触发 | 外部服务 |
| **Jenkins** | 2.400+ | CI/CD 编排、流水线执行 | 子节点 1 |
| **Ansible** | 2.14+ | 配置管理、自动化部署 | 子节点 1 |
| **K8s** | 1.26+ | 容器编排、应用运行 | 4 台机器集群 |
| **Docker** | 24+ | 容器构建、镜像管理 | 子节点 1 + K8s 节点 |

---

## 🔄 核心流程

### 标准 CI/CD 流程

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│  代码   │ →  │  构建   │ →  │  测试   │ →  │  部署   │ →  │  验证   │
│  Push   │    │  镜像   │    │  运行   │    │  到 K8s │    │  健康   │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
     │              │              │              │              │
     ↓              ↓              ↓              ↓              ↓
  GitHub       Docker         JUnit/        Ansible        K8s
  Webhook      Build          Pytest       Deploy         Health
```

### 详细步骤

| 阶段 | 步骤 | 执行者 | 产出物 |
|------|------|--------|--------|
| **1. 代码提交** | 开发者 Push 代码 | 开发者 | Git Commit |
| **2. 触发流水线** | GitHub Webhook 通知 Jenkins | GitHub | Jenkins Job |
| **3. 代码拉取** | Jenkins 拉取最新代码 | Jenkins | 工作空间 |
| **4. 构建镜像** | Docker build + push | Jenkins | Docker 镜像 |
| **5. 运行测试** | 单元测试、集成测试 | Jenkins | 测试报告 |
| **6. 质量门禁** | 代码覆盖率、静态分析 | Jenkins | 质量报告 |
| **7. 部署审批** | 手动/自动审批 | 负责人 | 审批结果 |
| **8. 执行部署** | Ansible Playbook | Ansible | K8s 资源 |
| **9. 健康检查** | 验证服务可用性 | Ansible | 部署状态 |
| **10. 通知反馈** | 发送部署结果 | Jenkins | 通知消息 |

---

## 📊 场景方案

### 方案 A：开发环境自动部署

**适用场景：** 开发团队频繁迭代，需要快速验证

**流程：**
```
feature branch → Push → Jenkins → 构建 → 测试 → 部署到 dev → 集成测试
```

**特点：**
- ✅ 全自动，无需审批
- ✅ 快速反馈（<10 分钟）
- ✅ 支持多 feature 分支并行
- ⚠️ 仅用于开发验证

**Jenkins Pipeline 关键配置：**
```groovy
pipeline {
    agent any
    triggers {
        pollSCM('*/5 * * * *')  // 每 5 分钟检查
    }
    stages {
        stage('Build') {
            steps { sh 'docker build -t app:$BUILD_ID .' }
        }
        stage('Test') {
            steps { sh 'pytest tests/' }
        }
        stage('Deploy to Dev') {
            steps { sh 'ansible-playbook deploy-dev.yml' }
        }
    }
}
```

---

### 方案 B：生产环境受控部署

**适用场景：** 生产环境，需要严格审批和质量控制

**流程：**
```
main branch → Push+PR → Jenkins → 构建 → 完整测试 → 安全扫描 
           → 人工审批 → 部署到 prod → 冒烟测试 → 回滚检查点
```

**特点：**
- ✅ 严格质量控制
- ✅ 人工审批把关
- ✅ 支持灰度发布
- ✅ 自动回滚保护
- ⚠️ 部署周期较长（30-60 分钟）

**审批流程：**
```
开发提交 → Tech Lead 审批 → QA 审批 → 运维审批 → 部署执行
```

---

### 方案 C：多环境分级部署

**适用场景：** 完整的企业级发布流程

**环境流转：**
```
Dev → Test → Staging → Pre-Prod → Prod
 │     │       │         │         │
自动  自动    手动      手动     手动 + 灰度
部署  部署    审批      审批
```

**环境说明：**

| 环境 | 用途 | 部署方式 | 数据源 |
|------|------|---------|--------|
| **Dev** | 开发自测 | 自动 | Mock 数据 |
| **Test** | 测试团队验证 | 自动 | 测试数据 |
| **Staging** | 预发布验证 | 手动审批 | 生产脱敏数据 |
| **Pre-Prod** | 上线前最后验证 | 手动审批 | 生产数据（只读） |
| **Prod** | 生产环境 | 手动 + 灰度 | 生产数据 |

**部署策略：**
```
1. Dev 环境验证通过 → 自动
2. Test 环境运行完整测试 → 自动
3. Staging 环境业务验证 → Tech Lead 审批
4. Pre-Prod 环境最终确认 → 产品 + 运维审批
5. Prod 环境灰度发布
   - 10% 流量 → 观察 30 分钟
   - 50% 流量 → 观察 1 小时
   - 100% 流量 → 完成
```

---

### 方案 D：微服务多应用部署

**适用场景：** 多个微服务应用，需要协调部署

**部署策略：**

| 策略 | 说明 | 适用场景 |
|------|------|---------|
| **并行部署** | 所有服务同时部署 | 独立服务，无依赖 |
| **顺序部署** | 按依赖顺序部署 | 有上下游依赖 |
| **分组部署** | 相关服务分组部署 | 微服务簇 |

**依赖顺序示例：**
```
1. 数据库迁移 (DB Migration)
       ↓
2. 基础服务 (Auth, Config)
       ↓
3. 核心服务 (User, Order, Product)
       ↓
4. 边缘服务 (API Gateway, Frontend)
```

---

### 方案 E：回滚与灾备方案

**适用场景：** 部署失败或生产事故

**回滚触发条件：**
- □ 健康检查失败 (>50% Pod 异常)
- □ 错误率飙升 (>5% 请求失败)
- □ 响应时间超时 (>3s 占比>20%)
- □ 手动触发回滚
- □ 监控告警触发

**回滚流程：**
```
发现问题 → 确认回滚 (5 分钟内) → 执行回滚 (上一版本) → 验证恢复 (自动验证)
```

**回滚策略：**

| 策略 | 说明 | RTO |
|------|------|-----|
| **快速回滚** | 直接切换回上一版本 | <5 分钟 |
| **灰度回滚** | 逐步切回旧版本 | 10-30 分钟 |
| **部分回滚** | 仅回滚问题服务 | 视情况 |

**灾备方案：**
```
主集群 (K8s-Prod-1)  ←同步→  备集群 (K8s-Prod-2)
       │                        │
       │ 故障检测               │ 待命
       ↓                        ↓
   [故障发生]  →  [自动/手动切换]  →  [备集群接管]
```

---

## 📋 配置示例

### Jenkins Pipeline 模板

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'registry.example.com'
        K8S_NAMESPACE = 'default'
        APP_NAME = 'myapp'
    }
    
    triggers {
        pollSCM('*/5 * * * *')
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/org/repo.git'
            }
        }
        
        stage('Build Image') {
            steps {
                sh 'docker build -t ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_ID} .'
                sh 'docker push ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_ID}'
            }
        }
        
        stage('Unit Test') {
            steps {
                sh 'pytest tests/unit --cov=app --cov-report=html'
            }
            post {
                always {
                    junit 'reports/*.xml'
                    publishHTML target: [
                        reportDir: 'htmlcov',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ]
                }
            }
        }
        
        stage('Deploy to Dev') {
            when { branch 'main' }
            steps {
                sh 'ansible-playbook deploy.yml -e "namespace=${K8S_NAMESPACE}" -e "image_tag=${BUILD_ID}"'
            }
        }
        
        stage('Approval for Prod') {
            when { tag 'release-*' }
            steps {
                input message: 'Deploy to Production?', ok: 'Approve', submitter: 'admin,ops-lead'
            }
        }
        
        stage('Deploy to Prod') {
            when { tag 'release-*' }
            steps {
                sh 'ansible-playbook deploy-prod.yml -e "namespace=production" -e "image_tag=${BUILD_ID}" -e "strategy=canary"'
            }
        }
    }
    
    post {
        always { cleanWs() }
        success { echo 'Deployment successful!' }
        failure { echo 'Deployment failed! Check logs.' }
    }
}
```

---

### Ansible Playbook 模板

```yaml
# deploy.yml
---
- name: Deploy Application to Kubernetes
  hosts: k8s_master
  become: yes
  vars:
    namespace: "default"
    app_name: "myapp"
    image_tag: "latest"
    replicas: 3
    
  tasks:
    - name: Create namespace if not exists
      k8s:
        state: present
        definition:
          apiVersion: v1
          kind: Namespace
          metadata:
            name: "{{ namespace }}"
    
    - name: Deploy application
      k8s:
        state: present
        namespace: "{{ namespace }}"
        definition:
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: "{{ app_name }}"
          spec:
            replicas: "{{ replicas }}"
            template:
              spec:
                containers:
                - name: "{{ app_name }}"
                  image: "registry.example.com/{{ app_name }}:{{ image_tag }}"
                  ports:
                  - containerPort: 8080
                  livenessProbe:
                    httpGet:
                      path: /health
                      port: 8080
                    initialDelaySeconds: 30
                    periodSeconds: 10
    
    - name: Wait for deployment to be ready
      k8s_info:
        api_version: apps/v1
        kind: Deployment
        name: "{{ app_name }}"
        namespace: "{{ namespace }}"
      register: deployment_info
      until: deployment_info.resources[0].status.readyReplicas == {{ replicas }}
      retries: 30
      delay: 10
```

---

## 📊 监控与度量

### 关键指标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| **构建成功率** | >95% | 成功构建次数/总构建次数 |
| **部署成功率** | >98% | 成功部署次数/总部署次数 |
| **平均构建时间** | <5 分钟 | 代码提交到构建完成 |
| **平均部署时间** | <10 分钟 | 构建完成到部署完成 |
| **回滚率** | <5% | 需要回滚的部署占比 |
| **MTTR** | <30 分钟 | 平均恢复时间 |

---

## ⚠️ 风险与缓解

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|---------|
| Jenkins 单点故障 | 高 | 中 | 定期备份 + 热备节点 |
| K8s 集群故障 | 高 | 低 | 多集群灾备方案 |
| 配置错误导致部署失败 | 中 | 中 | 配置审查 + 预发布验证 |
| 镜像仓库不可用 | 高 | 低 | 本地缓存 + 多镜像源 |
| 网络问题 | 中 | 中 | 内网部署 + 超时重试 |

---

## 📝 变更记录

| 版本 | 日期 | 作者 | 变更内容 |
|------|------|------|---------|
| 1.0 | 2026-03-23 | OpenClaw 子节点 1 | 初始版本 |

---

## 🔗 相关文档

- [Jenkins 官方文档](https://www.jenkins.io/doc/)
- [Ansible 官方文档](https://docs.ansible.com/)
- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

---

**审批：**

- [ ] 产品负责人
- [ ] 技术负责人
- [ ] 运维负责人
