#!/bin/bash

# 測試 API 的簡單腳本

echo "🧪 測試 Whisper API..."

# 檢查服務是否運行
echo "檢查服務狀態..."
curl -s http://localhost:8000/health || { echo "❌ 服務未運行，請先啟動服務"; exit 1; }

echo ""
echo "✅ 服務運行正常"

# 測試模型列表
echo ""
echo "📋 可用模型:"
curl -s http://localhost:8000/models | python -m json.tool

# 如果有測試音頻文件，可以測試轉錄
if [ -f "test_audio.wav" ]; then
    echo ""
    echo "🎵 測試音頻轉錄..."
    curl -X POST "http://localhost:8000/transcribe" \
         -H "Content-Type: multipart/form-data" \
         -F "file=@test_audio.wav" \
         -F "model=tiny" \
         -F "task=transcribe"
else
    echo ""
    echo "💡 提示: 放置一個 test_audio.wav 文件來測試轉錄功能"
fi

echo ""
echo "🌐 API 文檔: http://localhost:8000/docs"
