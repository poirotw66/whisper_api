#!/bin/bash

# 啟動 Whisper API 服務腳本

echo "啟動 Whisper API 服務..."

# 激活 conda 環境
source ~/miniconda3/etc/profile.d/conda.sh
conda activate whisper

# 檢查依賴
echo "檢查依賴..."
python -c "import whisper; import fastapi; import torch; print('✅ 所有依賴已就緒')"

# 檢查 GPU 可用性
echo "檢查 GPU 狀態..."
python -c "import torch; print(f'GPU 可用: {torch.cuda.is_available()}'); print(f'CUDA 版本: {torch.version.cuda}' if torch.cuda.is_available() else '')"

# 創建必要目錄
mkdir -p uploads temp models

# 啟動服務
echo "正在啟動 FastAPI 服務..."
echo "API 文檔將在: http://localhost:8000/docs"
echo "健康檢查: http://localhost:8000/health"
echo ""
echo "按 Ctrl+C 停止服務"

uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
