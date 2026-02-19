#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_PATH="$SCRIPT_DIR/.venv"
REQUIREMENTS_PATH="$SCRIPT_DIR/requirements.txt"

echo "========================================"
echo "  Backend 环境初始化脚本"
echo "========================================"

if [ -d "$VENV_PATH" ]; then
    echo "[INFO] 虚拟环境已存在: $VENV_PATH"
else
    echo "[STEP 1] 创建虚拟环境..."
    python3 -m venv "$VENV_PATH"
    echo "[OK] 虚拟环境创建成功"
fi

echo "[STEP 2] 激活虚拟环境并安装依赖..."
source "$VENV_PATH/bin/activate"

if [ -f "$REQUIREMENTS_PATH" ]; then
    pip install -r "$REQUIREMENTS_PATH"
    echo "[OK] 依赖安装完成"
else
    echo "[WARN] requirements.txt 不存在，跳过依赖安装"
fi

echo ""
echo "========================================"
echo "  初始化完成！"
echo "========================================"
echo ""
echo "后续使用请运行:"
echo "  source .venv/bin/activate"
echo ""
