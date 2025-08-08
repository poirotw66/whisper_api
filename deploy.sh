#!/bin/bash

# Whisper API Docker Compose 部署腳本

set -e

echo "🚀 開始部署 Whisper API 服務..."

# 檢查 Docker 和 Docker Compose
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安裝，請先安裝 Docker"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose 未安裝，請先安裝 Docker Compose"
    exit 1
fi

# 創建必要目錄
echo "📁 創建目錄結構..."
mkdir -p {models,uploads,temp,logs}

# 設置權限
echo "🔐 設置目錄權限..."
sudo chown -R 1000:1000 {models,uploads,temp,logs}

# 停止現有服務（如果存在）
echo "🛑 停止現有服務..."
docker compose down || true

# 構建和啟動服務
echo "🔨 構建 Docker 鏡像..."
docker compose build --no-cache

echo "⚡ 啟動服務..."
docker compose up -d

# 等待服務啟動
echo "⏳ 等待服務啟動..."
sleep 30

# 檢查服務狀態
echo "🔍 檢查服務狀態..."
docker compose ps

# 健康檢查
echo "🏥 進行健康檢查..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✅ 服務運行正常!"
    echo ""
    echo "🌐 服務地址:"
    echo "  - API 文檔: http://localhost/docs"
    echo "  - 健康檢查: http://localhost/health"
    echo "  - API 根路徑: http://localhost/"
    echo ""
    echo "📊 查看日誌: docker compose logs -f"
    echo "🛑 停止服務: docker compose down"
else
    echo "❌ 服務啟動失敗，請檢查日誌："
    echo "docker compose logs"
    exit 1
fi
