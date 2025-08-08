#!/bin/bash

echo "🚀 Whisper API + Cloudflare Tunnel 快速啟動"
echo "==========================================="

# 檢查環境變量文件
if [ ! -f ".env.cloudflare" ]; then
    echo "❌ 未找到 .env.cloudflare 文件"
    echo "請先運行: ./setup-cloudflare.sh"
    exit 1
fi

# 載入環境變量
source .env.cloudflare

echo "✅ 環境變量已載入"
echo "📋 Tunnel: $TUNNEL_NAME"
echo "📋 域名: $TUNNEL_DOMAIN"

# 檢查 Docker 服務狀態
echo ""
echo "🔍 檢查 Docker 服務狀態..."

if docker compose ps | grep -q "whisper-api.*Up"; then
    echo "✅ Whisper API 服務正在運行"
else
    echo "⚠️  Whisper API 服務未運行，正在啟動..."
    docker compose up -d
    
    # 等待服務啟動
    echo "⏳ 等待服務啟動..."
    sleep 10
    
    # 檢查健康狀態
    if curl -s http://localhost:8000/health > /dev/null; then
        echo "✅ Whisper API 服務啟動成功"
    else
        echo "❌ Whisper API 服務啟動失敗"
        exit 1
    fi
fi

# 啟動 Cloudflare Tunnel
echo ""
echo "🌩️  啟動 Cloudflare Tunnel..."

# 方法 1: 使用 docker compose
echo "使用 Docker Compose 啟動 Cloudflare Tunnel..."
docker compose -f docker-compose.cloudflare.yml --env-file .env.cloudflare up -d cloudflared

if [ $? -eq 0 ]; then
    echo "✅ Cloudflare Tunnel 啟動成功"
else
    echo "❌ Docker Compose 啟動失敗，嘗試直接啟動..."
    
    # 方法 2: 直接啟動
    nohup cloudflared tunnel run $TUNNEL_NAME > cloudflared.log 2>&1 &
    CLOUDFLARED_PID=$!
    echo $CLOUDFLARED_PID > cloudflared.pid
    
    echo "✅ Cloudflare Tunnel 已在後台啟動 (PID: $CLOUDFLARED_PID)"
    echo "📋 日誌文件: cloudflared.log"
fi

# 等待 tunnel 建立連接
echo ""
echo "⏳ 等待 Tunnel 建立連接..."
sleep 15

# 測試外網連接
echo ""
echo "🧪 測試外網連接..."

if curl -s -o /dev/null -w "%{http_code}" https://$TUNNEL_DOMAIN/health | grep -q "200"; then
    echo "✅ 外網連接測試成功!"
    echo ""
    echo "🌐 您的 API 現在可以通過以下地址訪問:"
    echo "   🔗 https://$TUNNEL_DOMAIN"
    echo ""
    echo "📋 API 端點:"
    echo "   • 健康檢查: https://$TUNNEL_DOMAIN/health"
    echo "   • 模型列表: https://$TUNNEL_DOMAIN/models"
    echo "   • API 文檔: https://$TUNNEL_DOMAIN/docs"
    echo "   • 轉錄服務: https://$TUNNEL_DOMAIN/transcribe"
    echo "   • 翻譯服務: https://$TUNNEL_DOMAIN/translate"
    echo ""
    echo "🧪 測試命令:"
    echo "   curl https://$TUNNEL_DOMAIN/health"
    echo "   curl https://$TUNNEL_DOMAIN/models"
else
    echo "⚠️  外網連接測試失敗，請檢查:"
    echo "   1. Cloudflare Tunnel 是否正常啟動"
    echo "   2. DNS 設置是否正確"
    echo "   3. 域名是否已生效"
    echo ""
    echo "🔧 調試命令:"
    echo "   docker compose logs cloudflared"
    echo "   cloudflared tunnel info $TUNNEL_NAME"
fi

echo ""
echo "🛠️  管理命令:"
echo "   停止服務: docker compose down"
echo "   查看日誌: docker compose logs -f"
echo "   重啟服務: docker compose restart"

if [ -f "cloudflared.pid" ]; then
    echo "   停止 Tunnel: kill \$(cat cloudflared.pid)"
fi
