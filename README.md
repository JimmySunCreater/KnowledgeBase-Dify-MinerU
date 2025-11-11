# MinerU ECS - 企业级 PDF 智能处理平台

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![AWS](https://img.shields.io/badge/AWS-ECS-orange.svg)](https://aws.amazon.com/ecs/)
[![GPU](https://img.shields.io/badge/GPU-Tesla%20T4-green.svg)](https://www.nvidia.com/en-us/data-center/tesla-t4/)
[![Python](https://img.shields.io/badge/Python-3.10-blue.svg)](https://www.python.org/)
[![MinerU](https://img.shields.io/badge/MinerU-2.1.0-blue.svg)](https://github.com/opendatalab/MinerU)

基于 AWS Serverless 架构和 MinerU AI 引擎的企业级 PDF 文档智能处理平台，支持 GPU 加速、自动扩缩容和事件驱动处理。

---

## 📋 目录

- [项目概述](#-项目概述)
- [核心特性](#-核心特性)
- [系统架构](#-系统架构)
- [快速开始](#-快速开始)
- [部署指南](#-部署指南)
- [使用说明](#-使用说明)
- [配置管理](#-配置管理)
- [监控运维](#-监控运维)
- [成本优化](#-成本优化)
- [故障排除](#-故障排除)
- [相关文档](#-相关文档)

---

## 🚀 项目概述

MinerU ECS 是一个云原生的 PDF 文档智能处理平台，专为企业级 RAG（检索增强生成）应用设计。通过结合 MinerU 专业文档解析引擎和 AWS Serverless 架构，提供高准确率、高性能、低成本的文档处理解决方案。

### 为什么选择 MinerU ECS？

**1. 专业文档解析能力**
- 表格识别准确率 96%（vs GPT-4o 72%）
- 公式识别准确率 94%（vs GPT-4o 68%）
- 多栏布局处理准确率 98%（vs GPT-4o 50%）
- 确定性输出，避免生成式模型的随机性

**2. Serverless 架构优势**
- 按需扩缩容（0-10 实例）
- 低频使用场景成本节省 89%
- 无任务时自动缩容至 0，零成本待机
- 事件驱动，自动化处理流程

**3. GPU 加速性能**
- 处理速度提升 10 倍
- 32 页复杂文档仅需 1.7 分钟
- 支持 NVIDIA T4 GPU（g4dn.xlarge）

---

## ✨ 核心特性

### 1. 智能文档解析

**支持的文档类型**
- 文本密集型文档（报告、论文、合同）
- 图表密集型文档（财务报表、数据分析）
- 混合型文档（技术手册、产品说明书）
- 扫描文档（OCR 自动识别）

**解析能力**
- ✅ 智能文档结构识别（标题、段落、列表）
- ✅ 表格智能转换（HTML/Markdown 格式）
- ✅ 图片自动提取（图表、示意图）
- ✅ 公式识别（LaTeX 格式）
- ✅ 多栏布局处理
- ✅ 语义连贯性保证（自动删除页眉页脚）
- ✅ 多语言支持（109 种语言）

**输出格式**
- **Markdown**: 结构化文本，适用于 RAG 应用
- **JSON**: 完整的文档结构数据，便于程序化处理
- **图片**: 提取的图表和图像（PNG/JPG）
- **元数据**: 页数、处理时间、文件信息

### 2. 图片服务与 CDN 加速

**完整的多模态 RAG 支持**

系统通过 CloudFront + Lambda 后处理架构，实现图片的自动化处理和全球加速访问：

**处理流程**
```
MinerU 处理 PDF → 生成 MD 文件（相对路径）
  ![表格](images/table_1.png)
    ↓
上传到 S3 → 触发 Lambda 后处理
    ↓
Lambda 自动替换为 CloudFront URL
  ![表格](https://d123.cloudfront.net/processed/job-123/images/table_1.png)
    ↓
RAG Agent 直接渲染图片
```

**核心功能**
- ✅ **自动路径替换**: Lambda 自动将相对路径转换为 CloudFront URL
- ✅ **全球 CDN 加速**: CloudFront 分发，毫秒级响应
- ✅ **安全访问控制**: 通过 OAI（Origin Access Identity）保护 S3
- ✅ **智能缓存**: 默认 1 天缓存，最长 1 年，降低成本
- ✅ **HTTPS 加密**: 自动 HTTPS 重定向
- ✅ **RAG 友好**: 保留完整 Markdown 语法，前端直接渲染

**技术实现**
- **CloudFront Distribution**: 全球边缘节点分发
- **Lambda 后处理**: 正则匹配替换图片路径
- **S3 事件触发**: 自动检测 `.md` 文件创建
- **OAI 访问控制**: 只允许通过 CloudFront 访问 S3

**示例输出**

处理前（MinerU 生成）:
```markdown
# 财务报表分析

下表展示了公司的资产负债情况：

![资产负债表](images/table_001.png)

营收趋势如下图所示：

![营收趋势图](images/chart_002.png)
```

处理后（Lambda 自动替换）:
```markdown
# 财务报表分析

下表展示了公司的资产负债情况：

![资产负债表](https://d1234567890.cloudfront.net/processed/job-abc123/images/table_001.png)

营收趋势如下图所示：

![营收趋势图](https://d1234567890.cloudfront.net/processed/job-abc123/images/chart_002.png)
```

**成本优化**
- 前 10TB 流量: $0.085/GB
- HTTPS 请求: $0.01/万次
- 小规模（500 文档/月）: ~$5-10/月
- 中规模（2000 文档/月）: ~$15-25/月

### 2. Serverless 架构

**核心组件**
- **Amazon ECS + Auto Scaling**: 智能容器编排，自动扩缩容
- **Amazon SQS**: 可靠消息队列，支持重试和死信队列
- **Amazon DynamoDB**: 实时任务状态跟踪
- **AWS Lambda**: 
  - S3 事件触发，自动创建处理任务
  - Markdown 后处理，自动替换图片路径为 CloudFront URL
- **Amazon S3**: 文件存储
- **Amazon CloudFront**: 全球 CDN 加速，图片快速访问
- **Amazon CloudWatch**: 日志和监控

**自动化处理流程**
```
用户上传 PDF → S3 触发 Lambda → 创建 SQS 消息 + DynamoDB 记录
    ↓
ECS 容器轮询队列 → GPU 处理文档 → 结果上传 S3
    ↓
S3 触发 Lambda 后处理 → 替换图片路径为 CloudFront URL
    ↓
更新 Markdown 文件 → RAG Agent 可直接使用
```

### 3. GPU 加速

**性能对比**

| 文档类型 | 页数 | GPU 处理时间 | CPU 处理时间 | 加速比 |
|---------|------|-------------|-------------|--------|
| 简单文档 | 10页 | 30秒 | 5分钟 | **10x** |
| 复杂文档 | 32页 | 1.7分钟 | 17分钟 | **10x** |
| 图表密集 | 50页 | 3分钟 | 30分钟 | **10x** |

**GPU 配置**
- 实例类型: g4dn.xlarge
- GPU: NVIDIA Tesla T4 (16GB VRAM)
- CUDA: 12.6
- PyTorch: 2.7.1

---

## 🏗️ 系统架构

### 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                         用户层                               │
│                    (上传 PDF 文件)                           │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                        存储层                                │
│  S3 存储桶: mineru-ecs-{env}-data-{account-id}              │
│  ├── input/          (输入 PDF 文件)                        │
│  └── processed/      (处理结果: MD/JSON/图片)               │
└─────────────────────────────────────────────────────────────┘
                              ↓ (S3 事件)
┌─────────────────────────────────────────────────────────────┐
│                       触发层                                 │
│  Lambda 1: S3 事件处理 → 创建任务记录 + 发送 SQS 消息      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                       消息层                                 │
│  SQS 主队列 (长轮询 20秒) + 死信队列 (失败重试 3 次)        │
└─────────────────────────────────────────────────────────────┘
                              ↓ (ECS 轮询)
┌─────────────────────────────────────────────────────────────┐
│                       计算层                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  ECS 集群 (Auto Scaling: 0-10 实例)                   │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │  MinerU 容器 (Docker)                           │  │  │
│  │  │  ├── main.py         (任务调度与健康检查)        │  │  │
│  │  │  ├── processor.py    (PDF 处理引擎)             │  │  │
│  │  │  ├── queue_manager   (SQS 队列管理)             │  │  │
│  │  │  ├── job_manager     (DynamoDB 状态管理)        │  │  │
│  │  │  └── health_checker  (健康检查)                 │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                        ↓                              │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │  NVIDIA Tesla T4 GPU (16GB VRAM)                │  │  │
│  │  │  CUDA 12.6 + PyTorch 2.7.1                      │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ↓ (上传结果)
┌─────────────────────────────────────────────────────────────┐
│                    后处理层                                  │
│  Lambda 2: Markdown 后处理                                  │
│  ├── 检测 .md 文件创建事件                                   │
│  ├── 正则匹配图片相对路径                                    │
│  ├── 替换为 CloudFront URL                                  │
│  └── 更新 Markdown 文件                                     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    CDN 加速层                                │
│  CloudFront Distribution                                    │
│  ├── 全球边缘节点分发                                        │
│  ├── OAI 访问控制 (只允许 CloudFront 访问 S3)               │
│  ├── HTTPS 自动加密                                         │
│  └── 智能缓存 (1天-1年)                                     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      数据层                                  │
│  DynamoDB: mineru-ecs-{env}-processing-jobs                 │
│  (任务状态、处理时间、结果元数据、错误信息)                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      监控层                                  │
│  CloudWatch 日志 + Prometheus 指标 + 健康检查端点           │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    应用层 (RAG Agent)                        │
│  ├── 检索 Markdown 内容                                     │
│  ├── 渲染图片 (CloudFront URL)                              │
│  └── 展示完整的多模态内容                                    │
└─────────────────────────────────────────────────────────────┘
```

### 技术栈

| 组件 | 技术 | 版本/规格 |
|------|------|----------|
| **AI 引擎** | MinerU | 2.1.0 |
| **GPU** | NVIDIA Tesla T4 | 16GB VRAM |
| **深度学习** | PyTorch + CUDA | 2.7.1 + 12.6 |
| **容器** | Docker | - |
| **编排** | AWS ECS | EC2 启动类型 |
| **实例** | g4dn.xlarge | 4 vCPU, 16GB RAM |
| **存储** | S3 + DynamoDB | - |
| **消息队列** | SQS | 标准队列 |
| **CDN** | CloudFront | - |
| **监控** | CloudWatch + Prometheus | - |

---

## 🚀 快速开始

### 前置条件

- AWS 账户（具有管理员权限或 ECS、S3、DynamoDB、Lambda 权限）
- AWS CLI 已安装并配置
- Docker 已安装（用于本地构建镜像）
- 基本的 Linux 命令行知识

### 一键部署

```bash
# 1. 克隆项目
git clone <your-repo-url>
cd mineru-ecs

# 2. 配置环境（可选，使用默认配置）
# 编辑 config.yaml 文件，根据需要调整参数
vim config.yaml

# 3. 执行部署（生产环境）
./deploy-cross-account.sh --environment production --region us-east-1

# 4. 验证部署
aws ecs describe-clusters --clusters mineru-ecs-production-cluster --region us-east-1
aws ecs list-tasks --cluster mineru-ecs-production-cluster --region us-east-1
```

### 测试处理

```bash
# 1. 获取 S3 存储桶名称
BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name mineru-ecs-data-services-production \
  --query 'Stacks[0].Outputs[?OutputKey==`DataBucketName`].OutputValue' \
  --output text --region us-east-1)

# 2. 上传测试 PDF
aws s3 cp test.pdf s3://${BUCKET_NAME}/input/

# 3. 查看任务状态
aws dynamodb scan \
  --table-name mineru-ecs-production-processing-jobs \
  --limit 1 \
  --region us-east-1

# 4. 下载处理结果
# 从 DynamoDB 获取 job_id，然后下载结果
aws s3 ls s3://${BUCKET_NAME}/processed/ --recursive
aws s3 sync s3://${BUCKET_NAME}/processed/{job-id}/ ./results/
```

---

## 📦 部署指南

### 部署架构

项目使用分层部署的 CloudFormation 栈：

```
01-ecs-infrastructure.yaml    (基础设施层)
  
  ↓ VPC, ECS Cluster, Auto Scaling Group, IAM Roles
02-ecs-data-services.yaml     (数据服务层)
  ↓ S3 Bucket, DynamoDB Table, SQS Queue, CloudFront CDN
03-ecs-trigger-services.yaml  (触发服务层)
  ↓ Lambda Function, S3 Event Notification
04-ecs-compute-services.yaml  (计算服务层)
  ↓ ECS Task Definition, ECS Service, Capacity Provider
```

### 部署步骤

**1. 准备工作**

```bash
# 检查 AWS CLI 配置
aws sts get-caller-identity

# 确认区域
export AWS_REGION=us-east-1

# 检查配置文件
cat config.yaml
```

**2. 执行部署**

```bash
# 使用默认配置部署生产环境
./deploy-cross-account.sh --environment production --region us-east-1

# 或指定自定义配置
./deploy-cross-account.sh \
  --environment production \
  --region us-east-1 \
  --profile my-aws-profile \
  --config custom-config.yaml
```

**3. 部署过程**

脚本会自动执行以下步骤：
1. 加载配置文件（config.yaml）
2. 验证 AWS 凭证和权限
3. 按顺序部署 4 个 CloudFormation 栈
4. 等待每个栈部署完成
5. 输出部署结果和资源信息

**4. 验证部署**

```bash
# 检查 CloudFormation 栈状态
aws cloudformation describe-stacks \
  --stack-name mineru-ecs-infrastructure-production \
  --region us-east-1

# 检查 ECS 集群
aws ecs describe-clusters \
  --clusters mineru-ecs-production-cluster \
  --region us-east-1

# 检查 ECS 服务
aws ecs describe-services \
  --cluster mineru-ecs-production-cluster \
  --services mineru-ecs-production-service \
  --region us-east-1

# 检查 Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names mineru-ecs-production-asg \
  --region us-east-1
```

### 部署参数说明

**config.yaml 配置文件**

```yaml
# 默认配置
default:
  project_name: mineru-ecs
  environment: production
  aws_region: us-east-1
  instance_type: g4dn.xlarge      # GPU 实例类型
  min_size: 1                      # 最小实例数
  max_size: 2                      # 最大实例数
  desired_capacity: 1              # 期望实例数
  volume_size: 100                 # EBS 卷大小 (GB)
  task_cpu: 3072                   # 任务 CPU (1024 = 1 vCPU)
  task_memory: 12288               # 任务内存 (MB)
  task_desired_count: 1            # 期望任务数
  startup_mode: prewarmed          # 启动模式: prewarmed/on-demand
  container_image: public.ecr.aws/b1v8r5t6/mineru-ecs-gpu:latest
  log_retention_days: 7            # 日志保留天数
  use_gpu: true                    # 启用 GPU
  debug_mode: false                # 调试模式
  disable_rollback: false          # 禁用回滚

# 开发环境配置
development:
  environment: development
  min_size: 0                      # 开发环境可缩容至 0
  desired_capacity: 0
  task_desired_count: 0
  startup_mode: on-demand          # 按需启动
  log_retention_days: 3

# 生产环境配置
production:
  environment: production
  aws_region: us-west-2
  min_size: 1                      # 生产环境至少 1 个实例
  desired_capacity: 1
  task_desired_count: 1
  startup_mode: prewarmed          # 预热模式
  log_retention_days: 7
```

### Docker 镜像构建

**本地构建镜像**

```bash
cd docker

# 基本构建
./build.sh

# 构建并推送到 ECR
./build.sh -r YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com -p

# 自定义镜像名称和标签
./build.sh -n my-mineru -t v1.0.0

# 使用构建参数
./build.sh --build-arg MINERU_VERSION=2.1.0 --build-arg CUDA_VERSION=12.6
```

**推送到 ECR**

```bash
# 登录 ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# 创建 ECR 仓库
aws ecr create-repository \
  --repository-name mineru-ecs-gpu \
  --region us-east-1

# 构建并推送
docker build -f Dockerfile.ecs-gpu -t mineru-ecs-gpu:latest .
docker tag mineru-ecs-gpu:latest \
  YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/mineru-ecs-gpu:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/mineru-ecs-gpu:latest
```

---

## 📖 使用说明

### 基本使用流程

**1. 上传 PDF 文件**

```bash
# 方式 1: AWS CLI
aws s3 cp document.pdf s3://mineru-ecs-production-data-{account-id}/input/

# 方式 2: AWS SDK (Python)
import boto3
s3 = boto3.client('s3')
s3.upload_file('document.pdf', 'mineru-ecs-production-data-{account-id}', 'input/document.pdf')

# 方式 3: AWS Console
# 在 S3 控制台上传文件到 input/ 前缀
```

**2. 查看任务状态**

```bash
# 查询最新任务
aws dynamodb scan \
  --table-name mineru-ecs-production-processing-jobs \
  --limit 10 \
  --region us-east-1

# 查询特定任务
aws dynamodb get-item \
  --table-name mineru-ecs-production-processing-jobs \
  --key '{"job_id": {"S": "your-job-id"}}' \
  --region us-east-1

# 查询特定状态的任务
aws dynamodb query \
  --table-name mineru-ecs-production-processing-jobs \
  --index-name status-created-index \
  --key-condition-expression "#status = :status" \
  --expression-attribute-names '{"#status": "status"}' \
  --expression-attribute-values '{":status": {"S": "completed"}}' \
  --region us-east-1
```

**3. 下载处理结果**

```bash
# 列出处理结果
aws s3 ls s3://mineru-ecs-production-data-{account-id}/processed/{job-id}/

# 下载所有结果
aws s3 sync \
  s3://mineru-ecs-production-data-{account-id}/processed/{job-id}/ \
  ./results/

# 下载特定文件
aws s3 cp \
  s3://mineru-ecs-production-data-{account-id}/processed/{job-id}/auto/document.md \
  ./document.md
```

**4. 验证图片处理**

```bash
# 获取 CloudFront 域名
CLOUDFRONT_DOMAIN=$(aws cloudformation describe-stacks \
  --stack-name mineru-ecs-data-services-production \
  --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDomainName'].OutputValue" \
  --output text \
  --region us-east-1)

echo "CloudFront Domain: $CLOUDFRONT_DOMAIN"

# 下载 Markdown 文件
aws s3 cp \
  s3://mineru-ecs-production-data-{account-id}/processed/{job-id}/auto/document.md \
  ./document.md

# 检查图片路径是否已替换为 CloudFront URL
cat document.md | grep "cloudfront"

# 提取第一个图片 URL
IMAGE_URL=$(cat document.md | grep -o 'https://[^)]*\.png' | head -1)

# 测试图片访问
curl -I "$IMAGE_URL"
# 应该返回 200 OK

# 或在浏览器中打开
echo "在浏览器中打开: $IMAGE_URL"
```

**5. RAG 应用集成示例**

```python
import boto3
import re

# 下载 Markdown 文件
s3 = boto3.client('s3')
response = s3.get_object(
    Bucket='mineru-ecs-production-data-{account-id}',
    Key='processed/{job-id}/auto/document.md'
)
markdown_content = response['Body'].read().decode('utf-8')

# Markdown 中的图片已经是 CloudFront URL，可以直接使用
print(markdown_content)

# 提取所有图片 URL
image_urls = re.findall(r'!\[.*?\]\((https://.*?)\)', markdown_content)
print(f"找到 {len(image_urls)} 个图片")

# 在 RAG Agent 中直接渲染
# 前端会自动加载 CloudFront URL 的图片
```

### 输出结构

处理完成后，结果会保存在 S3 的 `processed/{job-id}/` 目录下：

```
processed/{job-id}/
├── auto/
│   ├── document.md          # Markdown 格式文档（图片路径已替换为 CloudFront URL）
│   ├── document.json        # JSON 格式文档结构
│   └── images/              # 提取的图片
│       ├── image_001.png    # 可通过 CloudFront 访问
│       ├── image_002.png
│       └── ...
├── layout.pdf               # 布局可视化 (可选)
└── metadata.json            # 处理元数据
```

**Markdown 文件中的图片引用**

处理前（MinerU 生成）:
```markdown
![表格](images/table_001.png)
```

处理后（Lambda 自动替换）:
```markdown
![表格](https://d1234567890.cloudfront.net/processed/job-abc123/auto/images/table_001.png)
```

**图片访问方式**

1. **通过 CloudFront（推荐）**: 
   - URL: `https://{cloudfront-domain}/processed/{job-id}/auto/images/{image-name}`
   - 优势: 全球加速、智能缓存、低延迟

2. **直接从 S3（不推荐）**:
   - 需要配置 S3 Bucket Policy
   - 无 CDN 加速，延迟较高

### 任务状态说明

| 状态 | 说明 |
|------|------|
| `pending` | 任务已创建，等待处理 |
| `processing` | 正在处理中 |
| `completed` | 处理成功完成 |
| `failed` | 处理失败 |

### API 集成示例

**Python SDK**

```python
import boto3
import json
import time

# 初始化客户端
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('mineru-ecs-production-processing-jobs')

# 上传文件
bucket_name = 'mineru-ecs-production-data-{account-id}'
s3.upload_file('document.pdf', bucket_name, 'input/document.pdf')

# 等待任务创建
time.sleep(5)

# 查询任务状态
response = table.scan(Limit=1, ScanIndexForward=False)
job = response['Items'][0]
job_id = job['job_id']
status = job['status']

print(f"Job ID: {job_id}, Status: {status}")

# 轮询任务状态
while status in ['pending', 'processing']:
    time.sleep(10)
    response = table.get_item(Key={'job_id': job_id})
    status = response['Item']['status']
    print(f"Status: {status}")

# 下载结果
if status == 'completed':
    s3.download_file(
        bucket_name,
        f'processed/{job_id}/auto/document.md',
        'result.md'
    )
    print("Result downloaded successfully!")
```

---

## ⚙️ 配置管理

### 环境变量

**ECS 任务环境变量**

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `SQS_QUEUE_URL` | SQS 队列 URL | 自动注入 |
| `DYNAMODB_TABLE` | DynamoDB 表名 | 自动注入 |
| `S3_BUCKET_NAME` | S3 存储桶名称 | 自动注入 |
| `CLOUDFRONT_DOMAIN` | CloudFront 域名 | 自动注入 |
| `ENABLE_GPU` | 启用 GPU | `true` |
| `COMPUTE_MODE` | 计算模式 | `auto` |
| `MINERU_DEVICE_MODE` | MinerU 设备模式 | `cuda` |
| `MINERU_VIRTUAL_VRAM_SIZE` | 虚拟显存大小 (MB) | `14000` |
| `MINERU_LANGUAGE` | 文档语言 | `auto` |
| `MINERU_BACKEND` | 后端引擎 | `unimernet` |
| `MINERU_PARSE_METHOD` | 解析方法 | `auto` |
| `MINERU_VLM_FORMULA_ENABLE` | 启用公式识别 | `true` |
| `MINERU_VLM_TABLE_ENABLE` | 启用表格识别 | `true` |
| `CLEANUP_FILES` | 清理临时文件 | `false` |
| `LOG_LEVEL` | 日志级别 | `INFO` |

### Auto Scaling 配置

**基于队列深度的扩缩容**

```yaml
# 扩容策略
ScaleUpPolicy:
  - 当 SQS 队列消息数 > 10 时，增加 1 个实例
  - 冷却时间: 300 秒

# 缩容策略
ScaleDownPolicy:
  - 当 SQS 队列消息数 < 2 时，减少 1 个实例
  - 冷却时间: 600 秒
  - 最小实例数: 根据 config.yaml 配置
```

**手动调整**

```bash
# 调整期望容量
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name mineru-ecs-production-asg \
  --desired-capacity 2 \
  --region us-east-1

# 调整最小/最大容量
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name mineru-ecs-production-asg \
  --min-size 1 \
  --max-size 5 \
  --region us-east-1
```

---

## 📊 监控运维

### CloudWatch 监控

**关键指标**

| 指标 | 说明 | 告警阈值 |
|------|------|---------|
| `CPUUtilization` | CPU 使用率 | > 80% |
| `MemoryUtilization` | 内存使用率 | > 85% |
| `GPUUtilization` | GPU 使用率 | > 90% |
| `SQS ApproximateNumberOfMessages` | 队列消息数 | > 100 |
| `SQS ApproximateAgeOfOldestMessage` | 最旧消息年龄 | > 1800s |
| `DynamoDB ConsumedReadCapacity` | 读取容量 | - |
| `DynamoDB ConsumedWriteCapacity` | 写入容量 | - |

**查看日志**

```bash
# 查看 ECS 任务日志
aws logs tail /ecs/mineru-ecs-production --follow --region us-east-1

# 查看 Lambda 日志
aws logs tail /aws/lambda/mineru-ecs-production-s3-trigger --follow --region us-east-1

# 查询特定时间段的日志
aws logs filter-log-events \
  --log-group-name /ecs/mineru-ecs-production \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --filter-pattern "ERROR" \
  --region us-east-1
```

### Prometheus 指标

**自定义指标**

```python
# 任务处理指标
mineru_jobs_processed_total{status="completed", device_type="gpu"} 150
mineru_jobs_processed_total{status="failed", device_type="gpu"} 5

# 处理时间直方图
mineru_processing_duration_seconds_bucket{le="60"} 50
mineru_processing_duration_seconds_bucket{le="120"} 120
mineru_processing_duration_seconds_bucket{le="300"} 150

# 活跃任务数
mineru_active_jobs 2

# 队列大小
mineru_queue_size 15
```

**访问 Prometheus 端点**

```bash
# 获取 ECS 任务 IP
TASK_IP=$(aws ecs describe-tasks \
  --cluster mineru-ecs-production-cluster \
  --tasks $(aws ecs list-tasks \
    --cluster mineru-ecs-production-cluster \
    --query 'taskArns[0]' --output text) \
  --query 'tasks[0].containers[0].networkInterfaces[0].privateIpv4Address' \
  --output text --region us-east-1)

# 访问指标端点
curl http://${TASK_IP}:8080/metrics
```

### 健康检查

**健康检查端点**

```bash
# 健康检查
curl http://${TASK_IP}:8080/health

# 就绪检查
curl http://${TASK_IP}:8080/ready

# 指标端点
curl http://${TASK_IP}:8080/metrics
```

**健康检查响应示例**

```json
{
  "healthy": true,
  "timestamp": 1699999999.123,
  "uptime": 3600.5,
  "checks": {
    "system": {
      "healthy": true,
      "cpu_percent": 45.2,
      "memory_percent": 62.8,
      "disk_percent": 35.1,
      "load_avg": [1.5, 1.3, 1.2]
    },
    "gpu": {
      "healthy": true,
      "cuda_available": true,
      "device_count": 1,
      "device_name": "Tesla T4",
      "memory_percent": 55.3
    },
    "aws": {
      "healthy": true,
      "services": {
        "s3": {"healthy": true},
        "dynamodb": {"healthy": true},
        "sqs": {"healthy": true}
      }
    }
  }
}
```

---

## 💰 成本优化

### 成本分析

**按使用频率的成本估算**

| 场景 | 文档数/天 | 月度成本 | 主要成本项 |
|------|----------|---------|-----------|
| **低频使用** | 10 | $42 | ECS 实例 (按需) |
| **中频使用** | 100 | $120 | ECS 实例 + S3 |
| **高频使用** | 1000 | $393 | ECS 实例 + S3 + 数据传输 |

**成本构成**

```
ECS 实例 (g4dn.xlarge):  $0.526/小时
S3 存储:                 $0.023/GB/月
S3 请求:                 $0.0004/1000 请求
DynamoDB:                按需计费
SQS:                     前 100 万请求免费
Lambda:                  前 100 万请求免费
CloudFront:              $0.085/GB (前 10TB)
```

### 优化建议

**1. 使用 Spot 实例**

```yaml
# 在 01-ecs-infrastructure.yaml 中配置
MixedInstancesPolicy:
  InstancesDistribution:
    OnDemandPercentageAboveBaseCapacity: 0  # 100% Spot
    SpotAllocationStrategy: capacity-optimized
```

成本节省: 70%

**2. 调整 Auto Scaling 策略**

```yaml
# 低频使用场景
min_size: 0              # 无任务时缩容至 0
desired_capacity: 0
startup_mode: on-demand  # 按需启动

# 高频使用场景
min_size: 1              # 保持 1 个实例预热
desired_capacity: 1
startup_mode: prewarmed  # 预热模式
```

**3. S3 生命周期策略**

```bash
# 配置生命周期规则
aws s3api put-bucket-lifecycle-configuration \
  --bucket mineru-ecs-production-data-{account-id} \
  --lifecycle-configuration file://lifecycle.json

# lifecycle.json
{
  "Rules": [
    {
      "Id": "DeleteOldProcessedFiles",
      "Status": "Enabled",
      "Prefix": "processed/",
      "Expiration": {
        "Days": 30
      }
    },
    {
      "Id": "TransitionToIA",
      "Status": "Enabled",
      "Prefix": "processed/",
      "Transitions": [
        {
          "Days": 7,
          "StorageClass": "STANDARD_IA"
        }
      ]
    }
  ]
}
```

**4. CloudWatch 日志保留**

```yaml
# 调整日志保留天数
log_retention_days: 3  # 开发环境
log_retention_days: 7  # 生产环境
```

---

## 🔧 故障排除

### 常见问题

**1. ECS 任务无法启动**

**症状**: ECS 服务显示任务数为 0

**排查步骤**:
```bash
# 检查 ECS 服务事件
aws ecs describe-services \
  --cluster mineru-ecs-production-cluster \
  --services mineru-ecs-production-service \
  --region us-east-1 \
  --query 'services[0].events[0:5]'

# 检查任务定义
aws ecs describe-task-definition \
  --task-definition mineru-ecs-production-task \
  --region us-east-1

# 检查容器实例
aws ecs list-container-instances \
  --cluster mineru-ecs-production-cluster \
  --region us-east-1
```

**常见原因**:
- 容器镜像拉取失败 → 检查 ECR 权限
- 资源不足 → 检查 CPU/内存/GPU 配置
- IAM 角色权限不足 → 检查任务执行角色

**2. GPU 不可用**

**症状**: 日志显示 "CUDA not available"

**排查步骤**:
```bash
# 检查实例类型
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=mineru-ecs-production-asg" \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType]' \
  --region us-east-1

# 检查 GPU 驱动
# SSH 到 EC2 实例
nvidia-smi

# 检查 Docker GPU 运行时
docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu22.04 nvidia-smi
```

**解决方案**:
- 确认使用 g4dn 系列实例
- 检查 AMI 是否包含 GPU 驱动
- 验证 Docker GPU 运行时配置

**3. 任务处理失败**

**症状**: DynamoDB 中任务状态为 `failed`

**排查步骤**:
```bash
# 查看任务详情
aws dynamodb get-item \
  --table-name mineru-ecs-production-processing-jobs \
  --key '{"job_id": {"S": "your-job-id"}}' \
  --region us-east-1

# 查看 ECS 任务日志
aws logs filter-log-events \
  --log-group-name /ecs/mineru-ecs-production \
  --filter-pattern "job_id=your-job-id" \
  --region us-east-1

# 检查死信队列
aws sqs receive-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/{account-id}/mineru-ecs-production-processing-dlq \
  --max-number-of-messages 10 \
  --region us-east-1
```

**常见原因**:
- PDF 文件损坏 → 验证文件完整性
- 内存不足 → 增加任务内存配置
- 超时 → 增加 SQS 可见性超时

**4. Auto Scaling 不工作**

**症状**: 队列积压但实例数不增加

**排查步骤**:
```bash
# 检查 Auto Scaling 活动
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name mineru-ecs-production-asg \
  --max-records 10 \
  --region us-east-1

# 检查 CloudWatch 告警
aws cloudwatch describe-alarms \
  --alarm-name-prefix mineru-ecs-production \
  --region us-east-1

# 检查队列指标
aws cloudwatch get-metric-statistics \
  --namespace AWS/SQS \
  --metric-name ApproximateNumberOfMessagesVisible \
  --dimensions Name=QueueName,Value=mineru-ecs-production-processing-queue \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --region us-east-1
```

**解决方案**:
- 检查 Auto Scaling 策略配置
- 验证 CloudWatch 告警状态
- 确认 IAM 角色权限

**5. 图片路径未替换为 CloudFront URL**

**症状**: Markdown 文件中仍然是相对路径 `![xxx](images/xxx.png)`

**排查步骤**:
```bash
# 检查 Lambda 后处理函数日志
aws logs tail /aws/lambda/mineru-ecs-production-md-postprocess --follow --region us-east-1

# 检查 S3 事件通知配置
aws s3api get-bucket-notification-configuration \
  --bucket mineru-ecs-production-data-{account-id} \
  --region us-east-1

# 手动触发 Lambda 测试
cat > test-event.json << EOF
{
  "Records": [{
    "s3": {
      "bucket": {"name": "mineru-ecs-production-data-{account-id}"},
      "object": {"key": "processed/{job-id}/auto/document.md"}
    }
  }]
}
EOF

aws lambda invoke \
  --function-name mineru-ecs-production-md-postprocess \
  --payload file://test-event.json \
  response.json \
  --region us-east-1

cat response.json
```

**常见原因**:
- Lambda 未被触发 → 检查 S3 事件通知配置
- CloudFront 域名环境变量未设置 → 检查 Lambda 环境变量
- Lambda 权限不足 → 检查 IAM 角色权限
- 正则表达式不匹配 → 检查 Markdown 文件格式

**解决方案**:
```bash
# 验证 Lambda 环境变量
aws lambda get-function-configuration \
  --function-name mineru-ecs-production-md-postprocess \
  --query 'Environment.Variables' \
  --region us-east-1

# 应该看到 CLOUDFRONT_DOMAIN 变量

# 手动更新环境变量（如果缺失）
CLOUDFRONT_DOMAIN=$(aws cloudformation describe-stacks \
  --stack-name mineru-ecs-data-services-production \
  --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDomainName'].OutputValue" \
  --output text \
  --region us-east-1)

aws lambda update-function-configuration \
  --function-name mineru-ecs-production-md-postprocess \
  --environment "Variables={CLOUDFRONT_DOMAIN=$CLOUDFRONT_DOMAIN}" \
  --region us-east-1
```

**6. CloudFront 访问图片返回 403**

**症状**: 图片 URL 返回 403 Forbidden

**排查步骤**:
```bash
# 检查 CloudFront 配置
aws cloudfront get-distribution-config \
  --id $(aws cloudformation describe-stacks \
    --stack-name mineru-ecs-data-services-production \
    --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionId'].OutputValue" \
    --output text \
    --region us-east-1) \
  --region us-east-1

# 检查 S3 Bucket Policy
aws s3api get-bucket-policy \
  --bucket mineru-ecs-production-data-{account-id} \
  --query Policy --output text \
  --region us-east-1 | jq '.'

# 测试直接 S3 访问（应该被拒绝）
aws s3 cp s3://mineru-ecs-production-data-{account-id}/processed/{job-id}/auto/images/image_001.png ./test.png
# 应该返回 Access Denied
```

**常见原因**:
- OAI 配置错误 → 检查 CloudFront OAI 和 S3 Bucket Policy
- 文件不存在 → 检查 S3 中是否有该文件
- CloudFront 缓存问题 → 创建失效请求

**解决方案**:
```bash
# 验证文件存在
aws s3 ls s3://mineru-ecs-production-data-{account-id}/processed/{job-id}/auto/images/

# 创建 CloudFront 失效请求
DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
  --stack-name mineru-ecs-data-services-production \
  --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionId'].OutputValue" \
  --output text \
  --region us-east-1)

aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/processed/{job-id}/*" \
  --region us-east-1
```

### 调试模式

**启用调试模式**

```yaml
# 在 config.yaml 中设置
debug_mode: true
disable_rollback: true
```

这将:
- 跳过 CloudFormation 信号等待
- 禁用自动回滚
- 输出详细日志

**手动测试容器**

```bash
# 本地运行容器
docker run --rm -it \
  --gpus all \
  -e SQS_QUEUE_URL=your-queue-url \
  -e DYNAMODB_TABLE=your-table-name \
  -e S3_BUCKET_NAME=your-bucket-name \
  -e ENABLE_GPU=true \
  mineru-ecs-gpu:latest

# 进入容器调试
docker run --rm -it \
  --gpus all \
  --entrypoint /bin/bash \
  mineru-ecs-gpu:latest
```

---

## 📚 相关文档

### 项目文档

- [图片服务架构说明](图片服务架构说明.md) - CloudFront CDN 配置和图片处理流程
- [跨账号部署指南](跨账号部署指南.md) - 多账号部署配置
- [安全审计报告](安全审计报告.md) - 安全最佳实践
- [文档整合说明](文档整合说明.md) - 文档结构说明

### 技术博客

- [基于 MinerU 和 AWS Serverless 构建企业级 RAG 文档处理平台](blog1-mineru-rag-solution-new.md)
  - MinerU 核心技术特性
  - AWS Serverless 架构设计
  - 成本优化策略

- [基于 Dify 和 MinerU 构建智能文档问答系统](blog2-dify-integration-prompt-design.md)
  - Dify 集成方案
  - Prompt 工程实践
  - RAG 系统优化

### 外部资源

- [MinerU 官方文档](https://github.com/opendatalab/MinerU)
- [AWS ECS 文档](https://docs.aws.amazon.com/ecs/)
- [AWS Auto Scaling 文档](https://docs.aws.amazon.com/autoscaling/)
- [CloudFormation 文档](https://docs.aws.amazon.com/cloudformation/)

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 开发环境设置

```bash
# 克隆项目
git clone <your-repo-url>
cd mineru-ecs

# 安装依赖（如需本地开发）
pip install boto3 structlog torch flask prometheus-client psutil

# 运行代码格式检查
# black docker/app/
# flake8 docker/app/
```

### 提交规范

- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建/工具相关

---

## 📄 许可证

MIT License

---

## 🙏 致谢

- [MinerU](https://github.com/opendatalab/MinerU) - 优秀的文档解析引擎
- [AWS](https://aws.amazon.com/) - 强大的云服务平台
- 所有贡献者和用户的支持

---

**最后更新**: 2025-11-11
