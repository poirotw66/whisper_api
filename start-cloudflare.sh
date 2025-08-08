#!/bin/bash

# Cloudflare Tunnel 啟動腳本
# 此腳本會啟動包含 Cloudflare Tunnel 的完整服務

set -e

echo "🚀 啟動 Whisper API 服務 (含 Cloudflare Tunnel)"

# 載入環境變數
if [ -f .env.cloudflare ]; then
    echo "📋 載入 Cloudflare 配置..."
    export $(cat .env.cloudflare | grep -v '^#' | xargs)
else
    echo "❌ 錯誤: .env.cloudflare 文件不存在"
    exit 1
fi

# 檢查必要的環境變數
if [ -z "$CLOUDFLARE_TUNNEL_TOKEN" ]; then
    echo "❌ 錯誤: CLOUDFLARE_TUNNEL_TOKEN 未設置"
    exit 1
fi

echo "🔧 停止現有服務..."
docker compose -f docker-compose.cloudflare.yml down 2>/dev/null || true

echo "🏗️  構建並啟動服務..."
docker compose -f docker-compose.cloudflare.yml up -d --build

echo "⏳ 等待服務啟動..."
sleep 10

echo "🔍 檢查服務狀態..."
docker compose -f docker-compose.cloudflare.yml ps

echo "📊 檢查應用日誌..."
docker compose -f docker-compose.cloudflare.yml logs whisper-api --tail 10

echo "🌐 檢查 Cloudflare Tunnel 狀態..."
docker compose -f docker-compose.cloudflare.yml logs cloudflared --tail 10

echo ""
echo "✅ 服務啟動完成!"
echo "🌍 本地 API: http://localhost:8000"
echo "🌍 本地 Nginx: http://localhost:81"
echo "🌍 外部訪問: https://${TUNNEL_DOMAIN:-whisper.itr-lab.cloud}"
echo ""
echo "📖 查看完整日誌: docker compose -f docker-compose.cloudflare.yml logs -f"
echo "🛑 停止服務: docker compose -f docker-compose.cloudflare.yml down"
