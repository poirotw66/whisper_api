#!/bin/bash

echo "🌩️  Cloudflare Tunnel 設置腳本"
echo "================================"

# 檢查 cloudflared 是否已安裝
if ! command -v cloudflared &> /dev/null; then
    echo "❌ cloudflared 未安裝。請先安裝 cloudflared。"
    exit 1
fi

echo "✅ cloudflared 已安裝"

# 步驟 1: 登錄 Cloudflare
echo ""
echo "📝 步驟 1: 登錄 Cloudflare 帳戶"
echo "即將開啟瀏覽器進行授權..."
read -p "按 Enter 繼續..."

cloudflared tunnel login

if [ $? -ne 0 ]; then
    echo "❌ Cloudflare 登錄失敗"
    exit 1
fi

echo "✅ Cloudflare 登錄成功"

# 步驟 2: 創建 tunnel
echo ""
echo "📝 步驟 2: 創建 Cloudflare Tunnel"
TUNNEL_NAME="whisper-api-$(date +%s)"

cloudflared tunnel create $TUNNEL_NAME

if [ $? -ne 0 ]; then
    echo "❌ Tunnel 創建失敗"
    exit 1
fi

echo "✅ Tunnel '$TUNNEL_NAME' 創建成功"

# 獲取 tunnel UUID
TUNNEL_UUID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}')
echo "📋 Tunnel UUID: $TUNNEL_UUID"

# 步驟 3: 創建 DNS 記錄
echo ""
echo "📝 步驟 3: 設置 DNS 記錄"
echo "請輸入您要使用的域名 (例如: whisper-api.yourdomain.com):"
read -p "域名: " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "❌ 域名不能為空"
    exit 1
fi

cloudflared tunnel route dns $TUNNEL_NAME $DOMAIN

if [ $? -ne 0 ]; then
    echo "❌ DNS 記錄創建失敗"
    exit 1
fi

echo "✅ DNS 記錄創建成功: $DOMAIN"

# 步驟 4: 創建配置文件
echo ""
echo "📝 步驟 4: 創建 Tunnel 配置文件"

mkdir -p ~/.cloudflared

cat > ~/.cloudflared/config.yml << EOF
tunnel: $TUNNEL_UUID
credentials-file: ~/.cloudflared/$TUNNEL_UUID.json

ingress:
  - hostname: $DOMAIN
    service: http://localhost:8000
    originRequest:
      httpHostHeader: $DOMAIN
  - service: http_status:404
EOF

echo "✅ 配置文件已創建: ~/.cloudflared/config.yml"

# 步驟 5: 創建環境變量文件
echo ""
echo "📝 步驟 5: 創建環境變量文件"

# 獲取 tunnel token
TUNNEL_TOKEN=$(cloudflared tunnel token $TUNNEL_NAME)

cat > .env.cloudflare << EOF
# Cloudflare Tunnel 配置
CLOUDFLARE_TUNNEL_TOKEN=$TUNNEL_TOKEN
TUNNEL_NAME=$TUNNEL_NAME
TUNNEL_UUID=$TUNNEL_UUID
TUNNEL_DOMAIN=$DOMAIN
EOF

echo "✅ 環境變量文件已創建: .env.cloudflare"

# 步驟 6: 顯示啟動指令
echo ""
echo "🚀 設置完成！"
echo "================================"
echo ""
echo "✅ Tunnel 名稱: $TUNNEL_NAME"
echo "✅ Tunnel UUID: $TUNNEL_UUID"
echo "✅ 域名: $DOMAIN"
echo "✅ 本地服務: http://localhost:8000"
echo ""
echo "🔧 啟動 Cloudflare Tunnel 的方法："
echo ""
echo "方法 1 - 直接啟動："
echo "cloudflared tunnel run $TUNNEL_NAME"
echo ""
echo "方法 2 - 使用 Docker Compose："
echo "docker compose -f docker-compose.cloudflare.yml --env-file .env.cloudflare up -d"
echo ""
echo "方法 3 - 後台服務啟動："
echo "cloudflared tunnel --config ~/.cloudflared/config.yml run &"
echo ""
echo "🌐 外網訪問地址: https://$DOMAIN"
echo ""
echo "📋 測試命令："
echo "curl https://$DOMAIN/health"
echo "curl https://$DOMAIN/models"
echo ""
echo "⚠️  注意: 請確保您的 Whisper API 服務正在運行在 localhost:8000"
