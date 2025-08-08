#!/bin/bash

# Whisper API 管理腳本

COMPOSE_FILE="docker-compose.yml"

show_help() {
    echo "Whisper API 管理工具"
    echo ""
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  start     啟動服務"
    echo "  stop      停止服務"
    echo "  restart   重啟服務"
    echo "  status    查看狀態"
    echo "  logs      查看日誌"
    echo "  build     重新構建"
    echo "  clean     清理資源"
    echo "  test      測試API"
    echo "  monitor   監控資源使用"
    echo "  backup    備份數據"
    echo "  help      顯示幫助"
}

start_services() {
    echo "🚀 啟動 Whisper API 服務..."
    docker compose up -d
    echo "✅ 服務啟動完成"
}

stop_services() {
    echo "🛑 停止 Whisper API 服務..."
    docker compose down
    echo "✅ 服務已停止"
}

restart_services() {
    echo "🔄 重啟 Whisper API 服務..."
    docker compose restart
    echo "✅ 服務重啟完成"
}

show_status() {
    echo "📊 服務狀態:"
    docker compose ps
    echo ""
    echo "💾 資源使用:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
}

show_logs() {
    if [ -n "$2" ]; then
        docker compose logs -f "$2"
    else
        docker compose logs -f
    fi
}

build_services() {
    echo "🔨 重新構建服務..."
    docker compose build --no-cache
    echo "✅ 構建完成"
}

clean_resources() {
    echo "🧹 清理資源..."
    docker compose down -v
    docker system prune -f
    docker volume prune -f
    echo "✅ 清理完成"
}

test_api() {
    echo "🧪 測試 API..."
    
    # 健康檢查
    if curl -f http://localhost/health > /dev/null 2>&1; then
        echo "✅ 健康檢查通過"
    else
        echo "❌ 健康檢查失敗"
        return 1
    fi
    
    # 測試模型列表
    echo "📋 測試模型列表..."
    curl -s http://localhost/models | jq . || echo "⚠️  無法解析JSON響應"
    
    echo "🌐 API 文檔: http://localhost/docs"
}

monitor_resources() {
    echo "📈 實時監控 (按 Ctrl+C 退出)..."
    watch -n 5 "docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}'"
}

backup_data() {
    BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
    echo "💾 創建備份到 $BACKUP_DIR..."
    
    mkdir -p "$BACKUP_DIR"
    cp -r models "$BACKUP_DIR/" 2>/dev/null || echo "⚠️  models 目錄為空"
    cp -r uploads "$BACKUP_DIR/" 2>/dev/null || echo "⚠️  uploads 目錄為空"
    
    # 導出Redis數據
    docker compose exec redis redis-cli BGSAVE
    sleep 5
    docker cp $(docker compose ps -q redis):/data/dump.rdb "$BACKUP_DIR/"
    
    echo "✅ 備份完成: $BACKUP_DIR"
}

case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$@"
        ;;
    build)
        build_services
        ;;
    clean)
        clean_resources
        ;;
    test)
        test_api
        ;;
    monitor)
        monitor_resources
        ;;
    backup)
        backup_data
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ 未知命令: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
