# Whisper API Cloudflare Tunnel 設置指南

## 概述

這個指南將幫助您設置 Cloudflare Tunnel，讓您的 Whisper API 服務可以從外網訪問，而無需開放防火牆端口或設置複雜的網絡配置。

## 前置要求

1. ✅ Cloudflare 帳戶 (免費帳戶即可)
2. ✅ 擁有的域名 (需要將域名 DNS 託管在 Cloudflare)
3. ✅ 已安裝 `cloudflared` 工具
4. ✅ Whisper API 服務正在運行

## 快速開始

### 自動設置 (推薦)

```bash
# 1. 運行自動設置腳本
./setup-cloudflare.sh

# 2. 按照提示完成設置後，啟動服務
./start-tunnel.sh
```

### 手動設置

如果您偏好手動設置，請按照以下步驟：

#### 1. 登錄 Cloudflare

```bash
cloudflared tunnel login
```

這會開啟瀏覽器，請登錄您的 Cloudflare 帳戶並授權。

#### 2. 創建 Tunnel

```bash
# 創建一個新的 tunnel
cloudflared tunnel create whisper-api

# 查看 tunnel 列表
cloudflared tunnel list
```

#### 3. 設置 DNS 記錄

```bash
# 將您的域名指向 tunnel
cloudflared tunnel route dns whisper-api your-domain.com
```

#### 4. 創建配置文件

在 `~/.cloudflared/config.yml` 創建配置：

```yaml
tunnel: YOUR_TUNNEL_UUID
credentials-file: ~/.cloudflared/YOUR_TUNNEL_UUID.json

ingress:
  - hostname: your-domain.com
    service: http://localhost:8000
    originRequest:
      httpHostHeader: your-domain.com
  - service: http_status:404
```

#### 5. 啟動 Tunnel

```bash
# 方法 1: 直接啟動
cloudflared tunnel run whisper-api

# 方法 2: 後台啟動
cloudflared tunnel --config ~/.cloudflared/config.yml run &

# 方法 3: 使用 Docker Compose
docker compose -f docker-compose.cloudflare.yml up -d
```

## 服務管理

### 檢查服務狀態

```bash
# 檢查 Docker 服務
docker compose ps

# 檢查 Cloudflare Tunnel 狀態
cloudflared tunnel info whisper-api

# 檢查日誌
docker compose logs -f cloudflared
```

### 停止服務

```bash
# 停止所有服務
docker compose down

# 只停止 Cloudflare 服務
docker compose stop cloudflared
```

### 重啟服務

```bash
# 重啟所有服務
docker compose restart

# 只重啟 Cloudflare 服務
docker compose restart cloudflared
```

## 測試 API

一旦設置完成，您可以通過以下方式測試 API：

### 基本測試

```bash
# 健康檢查
curl https://your-domain.com/health

# 獲取模型列表
curl https://your-domain.com/models

# 查看 API 文檔
# 在瀏覽器中訪問: https://your-domain.com/docs
```

### 轉錄測試

```bash
# 上傳音頻文件進行轉錄
curl -X POST "https://your-domain.com/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@your-audio-file.wav" \
  -F "model=base"
```

### 翻譯測試

```bash
# 上傳音頻文件進行翻譯
curl -X POST "https://your-domain.com/translate" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@your-audio-file.wav" \
  -F "model=base"
```

## 故障排除

### 常見問題

1. **Tunnel 連接失敗**
   ```bash
   # 檢查 tunnel 狀態
   cloudflared tunnel info whisper-api
   
   # 檢查日誌
   docker compose logs cloudflared
   ```

2. **DNS 解析問題**
   ```bash
   # 檢查 DNS 記錄
   nslookup your-domain.com
   
   # 檢查 Cloudflare DNS 設置
   cloudflared tunnel route dns list
   ```

3. **API 無法訪問**
   ```bash
   # 確認本地服務運行
   curl http://localhost:8000/health
   
   # 檢查端口映射
   docker compose ps
   ```

### 調試命令

```bash
# 詳細日誌
docker compose logs -f --tail=100 cloudflared

# 檢查網絡連接
docker compose exec cloudflared ping localhost

# 檢查配置
docker compose config
```

## 安全考慮

1. **訪問控制**: 考慮在 Cloudflare 中設置訪問規則
2. **速率限制**: 設置適當的速率限制防止濫用
3. **SSL/TLS**: Cloudflare 自動提供 SSL 證書
4. **日誌監控**: 定期檢查訪問日誌

## 配置文件說明

### docker-compose.cloudflare.yml

擴展版本的 Docker Compose 文件，包含 cloudflared 服務：

- 自動從環境變量讀取 tunnel token
- 與主服務網絡連接
- 健康檢查和重啟策略

### .env.cloudflare

包含 Cloudflare Tunnel 相關的環境變量：

- `CLOUDFLARE_TUNNEL_TOKEN`: Tunnel 認證 token
- `TUNNEL_NAME`: Tunnel 名稱
- `TUNNEL_UUID`: Tunnel 唯一標識符
- `TUNNEL_DOMAIN`: 外網訪問域名

## 進階配置

### 多服務代理

您可以在同一個 tunnel 中代理多個服務：

```yaml
ingress:
  - hostname: api.your-domain.com
    service: http://localhost:8000
  - hostname: admin.your-domain.com
    service: http://localhost:8080
  - service: http_status:404
```

### 自定義請求頭

```yaml
ingress:
  - hostname: your-domain.com
    service: http://localhost:8000
    originRequest:
      httpHostHeader: your-domain.com
      originServerName: your-domain.com
```

## 支援

如果遇到問題，請檢查：

1. [Cloudflare Tunnel 文檔](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
2. [Docker Compose 文檔](https://docs.docker.com/compose/)
3. 項目 GitHub Issues

---

**注意**: 請確保您的域名 DNS 已託管在 Cloudflare，這是使用 Cloudflare Tunnel 的前置要求。
