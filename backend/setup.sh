#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_PATH="$SCRIPT_DIR/.venv"
REQUIREMENTS_PATH="$SCRIPT_DIR/requirements.txt"

echo "========================================"
echo "  Backend 环境初始化脚本 (Python 3.11)"
echo "========================================"

if [ -d "$VENV_PATH" ]; then
    echo "[INFO] 虚拟环境已存在: $VENV_PATH"
else
    echo "[STEP 1] 检查 Python 3.11..."
    
    PYTHON_CMD=""
    if command -v python3.11 &> /dev/null; then
        PYTHON_CMD="python3.11"
        echo "[OK] 找到 Python 3.11: $(python3.11 --version)"
    elif command -v python3 &> /dev/null; then
        PY_VER=$(python3 --version 2>&1)
        if [[ "$PY_VER" == *"3.11"* ]]; then
            PYTHON_CMD="python3"
            echo "[OK] 使用 Python: $PY_VER"
        fi
    fi

    if [ -z "$PYTHON_CMD" ]; then
        echo "[ERROR] 未找到 Python 3.11，请先安装"
        echo "Mac: brew install python@3.11"
        echo "Ubuntu: sudo apt install python3.11 python3.11-venv"
        exit 1
    fi

    echo "[STEP 2] 创建虚拟环境..."
    $PYTHON_CMD -m venv "$VENV_PATH"
    echo "[OK] 虚拟环境创建成功"
fi

BIN_PATH="$VENV_PATH/bin"
ACTIVATE_SH="$BIN_PATH/activate"

echo "[STEP 3] 检查激活脚本..."
if [ -f "$ACTIVATE_SH" ]; then
    echo "[OK] 激活脚本已就绪"
    echo "  - activate (Bash/Zsh)"
else
    echo "[WARN] 缺少激活脚本"
fi

echo "[STEP 4] 安装依赖..."
source "$ACTIVATE_SH"

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
