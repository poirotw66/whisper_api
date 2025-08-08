#!/bin/bash

# 快速容器服務測試腳本
echo "🎤 Whisper API 快速測試"
echo "======================"

# 測試健康檢查
echo "1. 健康檢查..."
curl -s http://localhost:8000/health | python3 -m json.tool

echo -e "\n2. 模型列表..."
curl -s http://localhost:8000/models | python3 -m json.tool

# 如果有測試音頻文件，進行轉錄測試
if [ -f "test_audio.wav" ]; then
    echo -e "\n3. 音頻轉錄測試..."
    curl -s -X POST "http://localhost:8000/transcribe" \
      -H "Content-Type: multipart/form-data" \
      -F "file=@test_audio.wav" \
      -F "model=tiny" | python3 -m json.tool
    
    echo -e "\n4. 語言檢測測試..."
    curl -s -X POST "http://localhost:8000/detect-language" \
      -H "Content-Type: multipart/form-data" \
      -F "file=@test_audio.wav" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(f\"檢測到的語言: {data['detected_language']}\")
print(f\"置信度: {data['probabilities'][data['detected_language']]:.4f}\")
"
else
    echo -e "\n❌ 未找到 test_audio.wav 文件"
    echo "使用以下命令生成測試音頻："
    echo "ffmpeg -f lavfi -i \"sine=frequency=1000:duration=5\" -ar 16000 test_audio.wav"
fi

echo -e "\n✅ 快速測試完成"
