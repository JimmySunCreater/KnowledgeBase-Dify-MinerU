#!/bin/bash
set -e

# MinerU混合架构容器入口脚本

echo "=== MinerU混合架构处理器启动 ==="
echo "计算模式: ${COMPUTE_MODE:-gpu}"
echo "单任务模式: ${SINGLE_TASK_MODE:-false}"
echo "GPU启用: ${ENABLE_GPU:-true}"
echo "任务ID: ${JOB_ID:-N/A}"
echo "时间: $(date)"

# 运行 CUDA 修复脚本
if [ "${ENABLE_GPU:-true}" = "true" ] && [ -f "/usr/local/bin/fix-cuda.sh" ]; then
    echo "=== 运行 CUDA 修复脚本 ==="
    /usr/local/bin/fix-cuda.sh
fi

# 检查必需的环境变量
required_vars=("DYNAMODB_TABLE" "SQS_QUEUE_URL")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "错误: 环境变量 $var 未设置"
        exit 1
    fi
done

# 创建必要的目录
mkdir -p /tmp/mineru-workspace /tmp/input /tmp/output /app/logs

# 设置权限
chmod 755 /tmp/mineru-workspace /tmp/input /tmp/output

# GPU模式下的NVIDIA设置
if [ "${ENABLE_GPU:-true}" = "true" ]; then
    echo "=== GPU环境检查 ==="
    
    # 运行时CUDA库链接修复
    if [ -f "/usr/lib/x86_64-linux-gnu/libcuda.so.1" ]; then
        mkdir -p /usr/local/cuda/lib64
        ln -sf /usr/lib/x86_64-linux-gnu/libcuda.so.1 /usr/local/cuda/lib64/libcuda.so 2>/dev/null || true
        ln -sf /usr/lib/x86_64-linux-gnu/libcuda.so.1 /usr/local/cuda/lib64/libcuda.so.1 2>/dev/null || true
        
        # 查找并链接 CUDA 运行时库
        if [ -f "/usr/local/cuda-12.8/lib64/libcudart.so.12" ]; then
            ln -sf /usr/local/cuda-12.8/lib64/libcudart.so.12 /usr/local/cuda/lib64/libcudart.so 2>/dev/null || true
            ln -sf /usr/local/cuda-12.8/lib64/libcudart.so.12 /usr/local/cuda/lib64/libcudart.so.12 2>/dev/null || true
        fi
        
        # 更新库缓存
        ldconfig 2>/dev/null || true
        echo "✓ CUDA库链接已修复"
    fi
    
    # 强制设置GPU环境变量
    export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-all}
    export NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:-all}
    export NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES:-compute,utility}
    export MINERU_VIRTUAL_VRAM_SIZE=${MINERU_VIRTUAL_VRAM_SIZE:-23000}
    export FORCE_CUDA=${FORCE_CUDA:-1}
    export TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST:-8.6}
    
    # 检查NVIDIA驱动
    if command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA驱动信息:"
        nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free --format=csv,noheader,nounits
        echo "GPU利用率:"
        nvidia-smi --query-gpu=utilization.gpu,utilization.memory --format=csv,noheader,nounits
    else
        echo "警告: nvidia-smi 不可用"
    fi
    
    # 检查CUDA
    if command -v nvcc &> /dev/null; then
        echo "CUDA版本: $(nvcc --version | grep release | awk '{print $6}' | cut -c2-)"
    else
        echo "警告: CUDA编译器不可用"
    fi
    
    echo "GPU环境变量设置:"
    echo "  CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
    echo "  NVIDIA_VISIBLE_DEVICES: $NVIDIA_VISIBLE_DEVICES"
    echo "  MINERU_VIRTUAL_VRAM_SIZE: $MINERU_VIRTUAL_VRAM_SIZE"
    echo "  FORCE_CUDA: $FORCE_CUDA"
    
    # 测试PyTorch GPU
    echo "PyTorch GPU测试:"
    python3 -c "
import torch
print(f'  PyTorch版本: {torch.__version__}')
print(f'  CUDA可用: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'  GPU数量: {torch.cuda.device_count()}')
    for i in range(torch.cuda.device_count()):
        print(f'  GPU {i}: {torch.cuda.get_device_name(i)}')
        props = torch.cuda.get_device_properties(i)
        print(f'    内存: {props.total_memory / 1024**3:.1f} GB')
else:
    print('  ❌ PyTorch无法检测到CUDA')
    " || echo "PyTorch GPU检测失败"
    
    # 测试MinerU API
    echo "MinerU API测试:"
    timeout 30 python3 -c "
import os
import sys
os.environ['MINERU_VIRTUAL_VRAM_SIZE'] = '23000'
try:
    # 优先尝试pip安装的版本
    try:
        from mineru.cli.common import do_parse
        from mineru.utils.config_reader import get_device
        print('  ✅ MinerU Python API可用 (pip版本)')
    except ImportError:
        # 尝试源码版本
        sys.path.insert(0, '/opt/MinerU')
        from mineru.cli.common import do_parse
        from mineru.utils.config_reader import get_device
        print('  ✅ MinerU Python API可用 (源码版本)')
    
    print(f'  设备模式: {get_device()}')
except Exception as e:
    print(f'  ❌ MinerU API测试异常: {e}')
    " || echo "MinerU API测试超时或失败"
fi

# Python环境检查
echo "=== Python环境检查 ==="
echo "Python版本: $(python3 --version)"
echo "pip版本: $(pip3 --version)"

# 检查关键依赖
echo "=== 依赖检查 ==="
python3 -c "
import sys
try:
    import boto3
    print(f'✓ boto3: {boto3.__version__}')
except ImportError as e:
    print(f'✗ boto3: {e}')
    sys.exit(1)

try:
    # 优先尝试pip安装的MinerU
    try:
        from mineru.cli.common import do_parse
        from mineru import version
        print(f'✓ MinerU API (pip): {getattr(version, \"__version__\", \"unknown\")}')
    except ImportError:
        # 如果pip版本不可用，尝试源码版本
        sys.path.insert(0, '/opt/MinerU')
        from mineru.cli.common import do_parse
        from mineru import version
        print(f'✓ MinerU API (source): {getattr(version, \"__version__\", \"unknown\")}')
except ImportError as e:
    print(f'✗ MinerU API: {e}')
    sys.exit(1)

if '${ENABLE_GPU:-true}' == 'true':
    try:
        import torch
        print(f'✓ torch: {torch.__version__}')
        print(f'✓ CUDA available: {torch.cuda.is_available()}')
        if torch.cuda.is_available():
            print(f'✓ GPU count: {torch.cuda.device_count()}')
            for i in range(torch.cuda.device_count()):
                print(f'  - GPU {i}: {torch.cuda.get_device_name(i)}')
    except ImportError as e:
        print(f'✗ torch: {e}')
        sys.exit(1)
"

# AWS连接检查
echo "=== AWS连接检查 ==="
python3 -c "
import boto3
import os
from botocore.exceptions import ClientError

# 检查AWS凭证
try:
    sts = boto3.client('sts')
    identity = sts.get_caller_identity()
    print(f'✓ AWS身份: {identity[\"Arn\"]}')
except Exception as e:
    print(f'✗ AWS身份验证失败: {e}')

# 检查DynamoDB表
try:
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])
    status = table.table_status
    print(f'✓ DynamoDB表状态: {status}')
except Exception as e:
    print(f'✗ DynamoDB连接失败: {e}')

# 检查SQS队列
try:
    sqs = boto3.client('sqs')
    attrs = sqs.get_queue_attributes(
        QueueUrl=os.environ['SQS_QUEUE_URL'],
        AttributeNames=['QueueArn']
    )
    print(f'✓ SQS队列: {attrs[\"Attributes\"][\"QueueArn\"]}')
except Exception as e:
    print(f'✗ SQS连接失败: {e}')
"

# 系统资源检查
echo "=== 系统资源检查 ==="
echo "CPU核心数: $(nproc)"
echo "内存总量: $(free -h | awk '/^Mem:/ {print $2}')"
echo "磁盘空间: $(df -h / | awk 'NR==2 {print $4\" available\"}')"

# 工作目录检查
echo "=== 工作目录检查 ==="
echo "工作目录: ${WORK_DIR:-/tmp/mineru-workspace}"
echo "输入目录: ${INPUT_DIR:-/tmp/input}"
echo "输出目录: ${OUTPUT_DIR:-/tmp/output}"

# 测试写入权限
test_file="/tmp/mineru-workspace/.write_test"
if echo "test" > "$test_file" 2>/dev/null; then
    echo "✓ 工作目录可写"
    rm -f "$test_file"
else
    echo "✗ 工作目录不可写"
    exit 1
fi

# 启动前最后检查
echo "=== 启动前检查 ==="
if [ "${SINGLE_TASK_MODE:-false}" = "true" ] && [ -z "${JOB_ID}" ]; then
    echo "错误: 单任务模式需要JOB_ID环境变量"
    exit 1
fi

echo "✓ 所有检查通过"
echo "=== 启动应用程序 ==="

# 根据参数启动不同的命令
if [ "$#" -eq 0 ]; then
    # 默认启动主程序
    exec python3 main.py
else
    # 执行传入的命令
    exec "$@"
fi
