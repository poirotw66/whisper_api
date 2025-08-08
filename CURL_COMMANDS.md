# Whisper API 容器測試 - curl 指令集合

## 基本服務測試

### 1. 健康檢查
```bash
curl -f http://localhost:8000/health
```

### 2. 獲取可用模型
```bash
curl http://localhost:8000/models
```

### 3. API 文檔
```bash
curl http://localhost:8000/docs
# 或在瀏覽器中訪問: http://localhost:8000/docs
```

## 音頻處理測試

### 4. 語言檢測
```bash
# 使用測試音頻文件
curl -X POST "http://localhost:8000/detect-language" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav"
```

### 5. 音頻轉錄 (同步)
```bash
# 使用 tiny 模型 (快速)
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=tiny"

# 使用 base 模型 (更準確)
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=base"

# 使用 small 模型
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=small"
```

### 6. 音頻翻譯 (翻譯為英文)
```bash
# 使用 tiny 模型
curl -X POST "http://localhost:8000/translate" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=tiny"

# 使用 base 模型
curl -X POST "http://localhost:8000/translate" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=base"
```

### 7. 異步音頻轉錄
```bash
# 提交異步任務
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=base" \
  -F "async=true"

# 返回類似: {"task_id": "abc123", "status": "pending"}

# 檢查任務狀態 (替換 TASK_ID)
curl http://localhost:8000/status/TASK_ID
```

### 8. 帶參數的轉錄
```bash
# 指定語言
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=base" \
  -F "language=zh"

# 返回時間戳
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=base" \
  -F "word_timestamps=true"

# 設置溫度參數
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=base" \
  -F "temperature=0.2"
```

## 測試不同音頻格式

### 9. MP3 文件測試
```bash
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@audio.mp3" \
  -F "model=tiny"
```

### 10. M4A 文件測試
```bash
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@audio.m4a" \
  -F "model=tiny"
```

### 11. FLAC 文件測試
```bash
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@audio.flac" \
  -F "model=tiny"
```

## 外網訪問測試 (Cloudflare Tunnel)

### 12. 外網健康檢查
```bash
curl https://whisper.itr-lab.cloud/health
```

### 13. 外網模型列表
```bash
curl https://whisper.itr-lab.cloud/models
```

### 14. 外網音頻轉錄
```bash
curl -X POST "https://whisper.itr-lab.cloud/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=tiny"
```

## 性能測試

### 15. 並發測試
```bash
# 同時發送多個請求測試
for i in {1..5}; do
  curl -X POST "http://localhost:8000/transcribe" \
    -H "Content-Type: multipart/form-data" \
    -F "file=@test_audio.wav" \
    -F "model=tiny" &
done
wait
```

### 16. 大文件測試
```bash
# 測試較大的音頻文件
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@large_audio.wav" \
  -F "model=small"
```

## 錯誤測試

### 17. 無效端點
```bash
curl http://localhost:8000/invalid-endpoint
# 應該返回 404
```

### 18. 無效模型
```bash
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=invalid-model"
# 應該返回 400 或 422
```

### 19. 無效文件格式
```bash
echo "test" > test.txt
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test.txt" \
  -F "model=tiny"
# 應該返回錯誤
rm test.txt
```

## 調試和監控

### 20. 詳細響應頭
```bash
curl -v http://localhost:8000/health
```

### 21. 只顯示 HTTP 狀態碼
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health
```

### 22. 測量響應時間
```bash
curl -s -o /dev/null -w "時間: %{time_total}s\n狀態碼: %{http_code}\n" \
  -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=tiny"
```

## 生成測試音頻文件

### 23. 創建測試音頻
```bash
# 使用 ffmpeg 生成 5 秒的測試音頻
ffmpeg -f lavfi -i "sine=frequency=1000:duration=5" -ar 16000 test_audio.wav

# 生成包含語音的測試音頻 (需要 espeak)
espeak "Hello, this is a test" -w test_speech.wav

# 從麥克風錄製 5 秒音頻 (Linux)
arecord -d 5 -f cd test_recording.wav
```

## 使用腳本進行自動化測試

### 24. 運行完整測試套件
```bash
./test_container.sh
```

### 25. JSON 格式化輸出
```bash
# 如果有 jq 工具
curl http://localhost:8000/models | jq .

# 如果沒有 jq，使用 python
curl http://localhost:8000/models | python -m json.tool
```
