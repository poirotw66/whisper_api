#!/bin/bash

# Whisper 模型下載腳本

set -e

MODELS_DIR="./models"
CONDA_ENV="whisper"

echo "📥 Whisper 模型下載工具"
echo "=========================="

# 創建模型目錄
mkdir -p "$MODELS_DIR"

# 檢查 conda 環境
if ! conda info --envs | grep -q "$CONDA_ENV"; then
    echo "❌ 找不到 conda 環境: $CONDA_ENV"
    echo "請先創建並激活 whisper 環境"
    exit 1
fi

# 激活環境
source ~/miniconda3/etc/profile.d/conda.sh
conda activate "$CONDA_ENV"

download_model() {
    local model_name="$1"
    echo "📥 下載模型: $model_name"
    
    python -c "
import whisper
import os

model_name = '$model_name'
models_dir = '$MODELS_DIR'

print(f'正在下載 {model_name} 模型...')
try:
    model = whisper.load_model(model_name, download_root=models_dir)
    print(f'✅ {model_name} 模型下載完成')
except Exception as e:
    print(f'❌ {model_name} 模型下載失敗: {e}')
    exit(1)
"
}

show_model_info() {
    echo ""
    echo "📋 Whisper 模型信息:"
    echo "==================="
    echo "tiny    - 39M  參數，~1GB 內存，~10x 速度，適合快速原型"
    echo "base    - 74M  參數，~1GB 內存，~7x  速度，平衡性能"
    echo "small   - 244M 參數，~2GB 內存，~4x  速度，高質量轉錄"
    echo "medium  - 769M 參數，~5GB 內存，~2x  速度，專業級應用"
    echo "large   - 1550M參數，~10GB內存，1x   速度，最高準確度"
    echo "turbo   - 809M 參數，~6GB 內存，~8x  速度，優化版本"
    echo ""
}

check_existing_models() {
    echo "🔍 檢查現有模型:"
    if [ -d "$MODELS_DIR" ] && [ "$(ls -A $MODELS_DIR)" ]; then
        for model_file in "$MODELS_DIR"/*.pt; do
            if [ -f "$model_file" ]; then
                model_name=$(basename "$model_file" .pt)
                size=$(du -h "$model_file" | cut -f1)
                echo "  ✅ $model_name ($size)"
            fi
        done
    else
        echo "  📁 模型目錄為空"
    fi
    echo ""
}

download_recommended_models() {
    echo "📥 下載推薦模型組合..."
    echo ""
    
    # 下載基礎模型組合
    download_model "tiny"    # 快速測試
    download_model "base"    # 平衡選擇
    download_model "small"   # 高質量
    
    echo ""
    echo "✅ 推薦模型下載完成!"
}

download_all_models() {
    echo "📥 下載所有模型 (警告: 需要大量磁盤空間)..."
    echo ""
    
    models=("tiny" "base" "small" "medium" "large" "turbo")
    
    for model in "${models[@]}"; do
        download_model "$model"
    done
    
    echo ""
    echo "✅ 所有模型下載完成!"
}

interactive_download() {
    show_model_info
    check_existing_models
    
    echo "請選擇要下載的模型:"
    echo "1) tiny    - 快速測試"
    echo "2) base    - 平衡選擇 (推薦)"
    echo "3) small   - 高質量"
    echo "4) medium  - 專業級"
    echo "5) large   - 最高質量"
    echo "6) turbo   - 優化速度"
    echo "7) 推薦組合 (tiny + base + small)"
    echo "8) 全部模型"
    echo "q) 退出"
    echo ""
    
    read -p "請輸入選擇 (1-8, q): " choice
    
    case $choice in
        1) download_model "tiny" ;;
        2) download_model "base" ;;
        3) download_model "small" ;;
        4) download_model "medium" ;;
        5) download_model "large" ;;
        6) download_model "turbo" ;;
        7) download_recommended_models ;;
        8) download_all_models ;;
        q|Q) echo "退出"; exit 0 ;;
        *) echo "❌ 無效選擇"; exit 1 ;;
    esac
}

# 解析命令行參數
case "${1:-interactive}" in
    "interactive"|"")
        interactive_download
        ;;
    "recommended")
        download_recommended_models
        ;;
    "all")
        download_all_models
        ;;
    "tiny"|"base"|"small"|"medium"|"large"|"turbo")
        download_model "$1"
        ;;
    "check")
        check_existing_models
        ;;
    "help"|"--help"|"-h")
        echo "用法: $0 [選項]"
        echo ""
        echo "選項:"
        echo "  interactive    交互式選擇 (默認)"
        echo "  recommended   下載推薦模型"
        echo "  all           下載所有模型"
        echo "  tiny|base|small|medium|large|turbo  下載指定模型"
        echo "  check         檢查現有模型"
        echo "  help          顯示此幫助"
        ;;
    *)
        echo "❌ 未知選項: $1"
        echo "使用 '$0 help' 查看幫助"
        exit 1
        ;;
esac

# 最終檢查
echo ""
check_existing_models

echo "💡 提示:"
echo "  - 模型存儲在: $MODELS_DIR"
echo "  - 在 Docker 中使用: docker-compose up 會自動掛載模型"
echo "  - 配置文件: .env 中的 WHISPER_MODEL 設置默認模型"
