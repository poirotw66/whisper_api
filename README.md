# Whisper API Service

高性能的 OpenAI Whisper 語音轉錄和翻譯 API 服務，支援 GPU 加速和多種部署方式。

## 🚀 功能特色

- 🎯 **多模型支援**: 支援所有 Whisper 模型 (tiny, base, small, medium, large, turbo)
- ⚡ **GPU 加速**: 支援 NVIDIA GPU 加速，大幅提升轉錄速度
- 🚀 **同步/異步處理**: 提供同步和異步轉錄端點
- 🌍 **多語言支援**: 支援 99+ 種語言的語音識別和翻譯
- 📁 **多格式支援**: 支援 mp3, wav, flac, m4a 等音頻格式
- 🔧 **語言檢測**: 自動檢測音頻語言
- 📊 **任務狀態追蹤**: 異步任務進度查詢
- 🐳 **Docker 支援**: 完整的容器化部署方案
- 🌐 **Cloudflare Tunnel**: 支援外部訪問的安全隧道
- 🗄️ **Redis 緩存**: 高效的緩存機制
- 🔄 **Nginx 反向代理**: 負載均衡和請求優化

## 📋 系統需求

### 最低要求
- Docker 20.10+
- Docker Compose 2.0+
- 8GB RAM
- 2GB 可用磁盤空間

### GPU 加速要求 (可選)
- NVIDIA GPU (GTX 1060 或更新)
- NVIDIA Driver 470+
- NVIDIA Container Toolkit

## 🛠️ 快速開始

### 1. 克隆專案
```bash
git clone https://github.com/poirotw66/whisper_api.git
cd whisper_api
```

### 2. 使用啟動腳本 (推薦)
```bash
# 賦予執行權限
chmod +x start_api.sh

# 啟動服務 (本地訪問)
./start_api.sh start --local

# 或使用 Cloudflare Tunnel (外部訪問)
./start_api.sh start --cloud
```

### 3. 驗證服務
```bash
# 檢查服務狀態
./start_api.sh status

# 測試健康檢查
curl http://localhost:8000/health
```

### 4. 訪問 API 文檔
- 本地: http://localhost:8000/docs
- 外部: https://whisper.itr-lab.cloud/docs (如使用 Cloudflare Tunnel)

## 🎯 啟動腳本用法

### 基本命令
```bash
# 啟動服務
./start_api.sh start

# 停止服務
./start_api.sh stop

# 重啟服務
./start_api.sh restart

# 查看狀態
./start_api.sh status

# 查看日誌
./start_api.sh logs

# 重新構建
./start_api.sh build

# 清理重啟
./start_api.sh clean
```

### 配置選項
```bash
# 使用本地配置
./start_api.sh start --local

# 使用 Cloudflare Tunnel (需要先配置 .env.cloudflare)
cp .env.cloudflare.example .env.cloudflare
# 編輯 .env.cloudflare 填入你的 Cloudflare Tunnel token
./start_api.sh start --cloud

# 重新構建特定版本
./start_api.sh build --cloud
```

## 🔑 Cloudflare Tunnel 配置

### 第一次設置
1. 複製示例配置文件：
   ```bash
   cp .env.cloudflare.example .env.cloudflare
   ```

2. 編輯 `.env.cloudflare` 文件，填入你的實際值：
   ```env
   CLOUDFLARE_TUNNEL_TOKEN=你的實際token
   TUNNEL_DOMAIN=你的域名
   ```

3. 啟動服務：
   ```bash
   ./start_api.sh start --cloud
   ```

### 🔒 安全注意事項
- ⚠️ **永遠不要將 `.env.cloudflare` 文件提交到 git**
- 🔐 **Token 具有完整的 tunnel 訪問權限，請妥善保管**
- 🔄 **如果 token 洩露，請立即在 Cloudflare Dashboard 中撤銷並重新生成**

## 📚 API 使用指南

### 基本端點

#### 健康檢查
```bash
curl http://localhost:8000/health
```

#### 語音轉錄
```bash
curl -X POST "http://localhost:8000/transcribe" \
  -H "accept: application/json" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@your_audio.mp3" \
  -F "model=base" \
  -F "language=zh"
```

#### 語音翻譯 (翻譯為英文)
```bash
curl -X POST "http://localhost:8000/translate" \
  -H "accept: application/json" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@your_audio.mp3" \
  -F "model=base"
```

### Python 示例

#### 安裝依賴
```bash
pip install requests
```

#### 轉錄示例
```python
import requests

# 轉錄音頻文件
def transcribe_audio(file_path, language="auto"):
    url = "http://localhost:8000/transcribe"
    
    with open(file_path, "rb") as audio_file:
        files = {"file": audio_file}
        data = {
            "model": "base",
            "language": language,
            "response_format": "json"
        }
        
        response = requests.post(url, files=files, data=data)
        
        if response.status_code == 200:
            result = response.json()
            return result["text"]
        else:
            print(f"錯誤: {response.status_code} - {response.text}")
            return None

# 使用示例
text = transcribe_audio("my_audio.mp3", language="zh")
print(f"轉錄結果: {text}")
```

#### 翻譯示例
```python
import requests

def translate_audio(file_path):
    url = "http://localhost:8000/translate"
    
    with open(file_path, "rb") as audio_file:
        files = {"file": audio_file}
        data = {"model": "base"}
        
        response = requests.post(url, files=files, data=data)
        
        if response.status_code == 200:
            result = response.json()
            return result["text"]
        else:
            print(f"錯誤: {response.status_code} - {response.text}")
            return None

# 使用示例
english_text = translate_audio("chinese_audio.mp3")
print(f"翻譯結果: {english_text}")
```

### JavaScript 示例

#### 使用 Fetch API
```javascript
// 轉錄音頻
async function transcribeAudio(audioFile, language = "auto") {
    const formData = new FormData();
    formData.append("file", audioFile);
    formData.append("model", "base");
    formData.append("language", language);
    formData.append("response_format", "json");
    
    try {
        const response = await fetch("http://localhost:8000/transcribe", {
            method: "POST",
            body: formData
        });
        
        if (response.ok) {
            const result = await response.json();
            return result.text;
        } else {
            console.error("轉錄失敗:", response.statusText);
            return null;
        }
    } catch (error) {
        console.error("請求錯誤:", error);
        return null;
    }
}

// 使用示例 (在瀏覽器中)
document.getElementById("audioFile").addEventListener("change", async (event) => {
    const file = event.target.files[0];
    if (file) {
        const text = await transcribeAudio(file, "zh");
        console.log("轉錄結果:", text);
    }
});
```

## 🔧 配置選項

### 環境變數

在 `.env.production` 文件中配置：

```env
# Whisper 模型 (tiny, base, small, medium, large)
WHISPER_MODEL=base

# Redis 連接
REDIS_URL=redis://redis:6379/0

# 模型緩存目錄
CACHE_DIR=/app/models

# GPU 設定
CUDA_VISIBLE_DEVICES=0
NVIDIA_VISIBLE_DEVICES=0
```

### Whisper 模型大小對比

| 模型 | 參數量 | VRAM | 相對速度 | 精確度 | 適用場景 |
|------|--------|------|----------|--------|----------|
| tiny | 39M    | ~1GB | ~32x     | 低     | 快速原型、實時轉錄 |
| base | 74M    | ~1GB | ~16x     | 中     | 平衡性能和準確度 |
| small| 244M   | ~2GB | ~6x      | 中高   | 高質量轉錄 |
| medium| 769M  | ~5GB | ~2x      | 高     | 專業級應用 |
| large| 1550M  | ~10GB| ~1x      | 最高   | 最高準確度 |
| turbo| 809M   | ~6GB | ~8x      | 高     | 優化版本，速度快 |

## 🐳 Docker 部署

### 本地部署
```bash
# 使用本地配置
docker compose up -d
```

### Cloudflare Tunnel 部署
```bash
# 使用 Cloudflare Tunnel 配置
docker compose -f docker-compose.cloudflare.yml up -d
```

### 檢查服務狀態
```bash
docker compose ps
docker compose logs whisper-api
```

## 📝 API 響應格式

### 成功響應
```json
{
    "text": "轉錄或翻譯的文字內容",
    "language": "zh",
    "duration": 10.5,
    "model": "base"
}
```

### 錯誤響應
```json
{
    "detail": "錯誤詳細信息"
}
```

## 🔒 安全性

### 文件大小限制
- 最大文件大小: 500MB
- 支援的格式: mp3, wav, flac, m4a, ogg, webm

### 速率限制
- API 請求: 10 requests/second
- 上傳請求: 2 requests/second

### CORS 設定
開發環境下允許所有來源，生產環境建議限制特定域名。

## 📊 監控和日誌

### 查看日誌
```bash
# 所有服務日誌
./start_api.sh logs

# 特定服務日誌
docker compose logs whisper-api -f
docker compose logs nginx -f
docker compose logs redis -f
```

### 性能監控
```bash
# 檢查 GPU 使用情況
docker exec whisper_api-whisper-api-1 nvidia-smi

# 檢查記憶體使用
docker stats

# 檢查磁盤使用
df -h
```

## 🐛 故障排除

### 常見問題

#### 1. GPU 未被偵測
```bash
# 檢查 NVIDIA 驅動
nvidia-smi

# 檢查 Docker GPU 支援
docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu20.04 nvidia-smi
```

#### 2. 記憶體不足
```bash
# 使用較小的模型
WHISPER_MODEL=tiny

# 或增加 swap 空間
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### 3. 連接問題
```bash
# 檢查服務狀態
./start_api.sh status

# 查看詳細日誌
./start_api.sh logs whisper-api
```

#### 4. Cloudflare Tunnel 問題
```bash
# 檢查 cloudflared 日誌
docker compose -f docker-compose.cloudflare.yml logs cloudflared

# 重啟 tunnel
docker compose -f docker-compose.cloudflare.yml restart cloudflared
```

#### 5. FFmpeg 未安裝
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install ffmpeg

# CentOS/RHEL
sudo yum install ffmpeg
```

#### 6. CUDA 內存不足
```bash
# 使用較小的模型或增加 GPU 記憶體
WHISPER_MODEL=base  # 而非 large
```

## 📈 性能優化

### GPU 記憶體優化
```python
# 使用較小的模型以節省 VRAM
WHISPER_MODEL=base  # 而非 large
```

### 批次處理
```python
# 對於多個文件，建議分批處理避免記憶體溢出
for file_batch in audio_files_batches:
    results = process_batch(file_batch)
```

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

## 🤝 開發

### 代碼格式化

```bash
black app/
flake8 app/
```

### 測試

```bash
pytest tests/
```

## 🆘 支援

如有問題或建議，請：
1. 查看 [常見問題](#故障排除) 章節
2. 搜索現有 [Issues](https://github.com/poirotw66/whisper_api/issues)
3. 創建新的 Issue 並提供詳細信息

## 📄 授權條款

本專案使用 MIT 授權條款。

## 🔮 未來計劃

- [ ] 支援更多音頻格式
- [ ] 實時語音轉錄 (WebSocket)
- [ ] 多語言同時輸出
- [ ] 說話人分離功能
- [ ] 語音情感分析
- [ ] 自動語言檢測優化
- [ ] 批次處理 API
- [ ] 管理面板

## 🤝 貢獻指南

### 開發環境設置
```bash
# 克隆專案
git clone https://github.com/poirotw66/whisper_api.git

# 安裝開發依賴
pip install -r requirements.txt

# 啟動開發服務器
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 提交規範
- 使用清晰的提交信息
- 遵循現有的代碼風格
- 添加適當的測試
- 更新相關文檔

---

**享受使用 Whisper API Service! 🎉**
