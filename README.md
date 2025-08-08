# Whisper API Service

這是一個基於 FastAPI 和 OpenAI Whisper 的語音轉錄和翻譯 API 服務。

## 功能特性

- 🎯 **多模型支援**: 支援所有 Whisper 模型 (tiny, base, small, medium, large, turbo)
- 🚀 **同步/異步處理**: 提供同步和異步轉錄端點
- 🌍 **多語言支援**: 支援 99+ 種語言的語音識別和翻譯
- 📁 **多格式支援**: 支援 mp3, wav, flac, m4a 等音頻格式
- 🔧 **語言檢測**: 自動檢測音頻語言
- 📊 **任務狀態追蹤**: 異步任務進度查詢
- 🐳 **Docker 支援**: 容器化部署

## Docker 部署

### 快速部署

使用一鍵部署腳本：

```bash
./deploy.sh
```

### 手動部署

1. **下載模型**
   ```bash
   ./download_models.sh recommended
   ```

2. **構建和啟動服務**
   ```bash
   docker-compose up -d
   ```

3. **檢查服務狀態**
   ```bash
   docker-compose ps
   ```

### 環境配置

- **開發環境**: 使用 `docker-compose.yml` + `docker-compose.override.yml`
- **生產環境**: 使用 `docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d`

### 服務管理

使用管理腳本：

```bash
./manage.sh start    # 啟動服務
./manage.sh stop     # 停止服務
./manage.sh status   # 查看狀態
./manage.sh logs     # 查看日誌
./manage.sh test     # 測試API
./manage.sh monitor  # 監控資源
```

### 服務地址

- API 文檔: http://localhost/docs
- 健康檢查: http://localhost/health
- 直接API: http://localhost:8000 (開發環境)

## 快速開始

### 環境要求

- Python 3.8+
- FFmpeg
- CUDA (可選，用於 GPU 加速)

### 安裝依賴

```bash
# 安裝 FFmpeg (Ubuntu/Debian)
sudo apt update && sudo apt install ffmpeg

# 安裝 Python 依賴
pip install -r requirements.txt
```

### 配置環境變數

複製 `.env` 文件並根據需要修改配置：

```bash
cp .env .env.local
```

### 啟動服務

```bash
# 開發模式
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 生產模式
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

服務啟動後，可以通過以下地址訪問：

- API 文檔: http://localhost:8000/docs
- ReDoc 文檔: http://localhost:8000/redoc
- 健康檢查: http://localhost:8000/health

## API 端點

### 核心功能

- `POST /transcribe` - 同步音頻轉錄
- `POST /transcribe/async` - 異步音頻轉錄
- `GET /tasks/{task_id}` - 查詢異步任務狀態
- `POST /detect-language` - 檢測音頻語言
- `GET /models` - 列出可用模型

### 管理端點

- `GET /` - API 基本信息
- `GET /health` - 健康檢查

## 使用示例

curl -f http://localhost:8000/health

curl -X POST "http://localhost:8000/transcribe" -H "Content-Type: multipart/form-data" -F "file=@test_audio.wav" -F "model=base"

curl http://localhost:8000/models 

### 同步轉錄

```bash
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@audio.mp3" \
  -F "model=turbo" \
  -F "task=transcribe"
```

### 異步轉錄

```bash
# 提交任務
curl -X POST "http://localhost:8000/transcribe/async" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@audio.mp3" \
  -F "model=base"

# 查詢結果
curl "http://localhost:8000/tasks/{task_id}"
```

### 語言檢測

```bash
curl -X POST "http://localhost:8000/detect-language" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@audio.mp3" \
  -F "model=base"
```

## Docker 部署

### 構建鏡像

```bash
docker build -t whisper-api .
```

### 運行容器

```bash
docker run -d \
  --name whisper-api \
  -p 8000:8000 \
  -v $(pwd)/models:/app/models \
  -v $(pwd)/uploads:/app/uploads \
  whisper-api
```

### Docker Compose

```bash
docker-compose up -d
```

## 模型選擇指南

| 模型 | 大小 | 記憶體 | 速度 | 適用場景 |
|------|------|--------|------|----------|
| tiny | 39M | ~1GB | ~10x | 快速原型、實時轉錄 |
| base | 74M | ~1GB | ~7x | 平衡性能和準確度 |
| small | 244M | ~2GB | ~4x | 高質量轉錄 |
| medium | 769M | ~5GB | ~2x | 專業級應用 |
| large | 1550M | ~10GB | 1x | 最高準確度 |
| turbo | 809M | ~6GB | ~8x | 優化版本，速度快 |

## 性能調優

### GPU 加速

確保安裝了正確版本的 PyTorch：

```bash
# CUDA 11.8
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu118

# CUDA 12.1
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu121
```

### 記憶體優化

- 使用較小的模型 (tiny, base) 減少記憶體使用
- 調整 `beam_size` 和 `best_of` 參數
- 限制並發請求數量

## 開發

### 代碼格式化

```bash
black app/
flake8 app/
```

### 測試

```bash
pytest tests/
```

## 故障排除

### 常見問題

1. **FFmpeg 未安裝**
   ```
   確保系統已安裝 FFmpeg
   ```

2. **CUDA 內存不足**
   ```
   使用較小的模型或增加 GPU 記憶體
   ```

3. **模型下載失敗**
   ```
   檢查網絡連接，確保有足夠的磁盤空間
   ```

## 授權

MIT License

## 貢獻

歡迎提交 Pull Request 和 Issue！
