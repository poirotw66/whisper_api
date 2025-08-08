#!/bin/bash

# Whisper API 啟動腳本
# 用於快速啟動 Whisper API 服務

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日誌函數
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查 Docker 和 Docker Compose
check_requirements() {
    log_info "檢查系統需求..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安裝，請先安裝 Docker"
        exit 1
    fi
    
    if ! command -v docker compose &> /dev/null; then
        log_error "Docker Compose 未安裝，請先安裝 Docker Compose"
        exit 1
    fi
    
    # 檢查 NVIDIA Docker 支援
    if ! docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu20.04 nvidia-smi &> /dev/null; then
        log_warning "NVIDIA Docker 支援可能未正確配置，GPU 加速可能無法使用"
    fi
    
    log_success "系統需求檢查完成"
}

# 創建必要的目錄
create_directories() {
    log_info "創建必要的目錄..."
    
    directories=("models" "uploads" "temp" "logs")
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_info "創建目錄: $dir"
        fi
    done
    
    log_success "目錄創建完成"
}

# 檢查環境文件
check_env_file() {
    log_info "檢查環境配置..."
    
    if [ ! -f ".env.production" ]; then
        log_warning ".env.production 文件不存在，創建默認配置"
        cat > .env.production << 'EOF'
WHISPER_MODEL=base
REDIS_URL=redis://redis:6379/0
CACHE_DIR=/app/models
CUDA_VISIBLE_DEVICES=0
NVIDIA_VISIBLE_DEVICES=0
EOF
        log_info "已創建 .env.production 文件"
    fi
    
    # 如果使用 Cloudflare 配置，檢查相關環境文件
    if [[ "$COMPOSE_FILE" == *"cloudflare"* ]]; then
        if [ ! -f ".env.cloudflare" ]; then
            log_error ".env.cloudflare 文件不存在！"
            log_error "請複製 .env.cloudflare.example 為 .env.cloudflare 並填入你的 Cloudflare Tunnel token"
            log_error "cp .env.cloudflare.example .env.cloudflare"
            exit 1
        fi
        
        # 檢查是否包含示例值
        if grep -q "your_tunnel_token_here" .env.cloudflare; then
            log_error ".env.cloudflare 包含示例值，請填入實際的 Cloudflare Tunnel token"
            exit 1
        fi
    fi
    
    log_success "環境配置檢查完成"
}

# 顯示幫助信息
show_help() {
    echo "Whisper API 啟動腳本"
    echo ""
    echo "用法: $0 [選項]"
    echo ""
    echo "選項:"
    echo "  start     啟動所有服務 (默認)"
    echo "  stop      停止所有服務"
    echo "  restart   重啟所有服務"
    echo "  logs      顯示服務日誌"
    echo "  status    顯示服務狀態"
    echo "  build     重新構建並啟動"
    echo "  clean     清理並重新啟動"
    echo "  help      顯示此幫助信息"
    echo ""
    echo "環境選項:"
    echo "  --local     使用本地配置 (docker-compose.yml)"
    echo "  --cloud     使用 Cloudflare Tunnel 配置 (docker-compose.cloudflare.yml)"
    echo ""
    echo "示例:"
    echo "  $0 start --cloud    # 使用 Cloudflare Tunnel 啟動"
    echo "  $0 build --local    # 重新構建本地版本"
    echo "  $0 logs             # 顯示日誌"
}

# 載入環境變數
load_env_vars() {
    if [[ "$COMPOSE_FILE" == *"cloudflare"* ]]; then
        if [ -f ".env.cloudflare" ]; then
            set -a  # 自動導出變數
            source .env.cloudflare
            set +a  # 停止自動導出
        fi
    fi
}

# 選擇 Docker Compose 文件
select_compose_file() {
    if [[ "$*" == *"--cloud"* ]]; then
        COMPOSE_FILE="docker-compose.cloudflare.yml"
        log_info "使用 Cloudflare Tunnel 配置"
    elif [[ "$*" == *"--local"* ]]; then
        COMPOSE_FILE="docker-compose.yml"
        log_info "使用本地配置"
    else
        # 默認選擇邏輯
        if [ -f "docker-compose.cloudflare.yml" ]; then
            COMPOSE_FILE="docker-compose.cloudflare.yml"
            log_info "自動選擇 Cloudflare Tunnel 配置"
        else
            COMPOSE_FILE="docker-compose.yml"
            log_info "自動選擇本地配置"
        fi
    fi
}

# 啟動服務
start_services() {
    log_info "啟動 Whisper API 服務..."
    
    load_env_vars
    docker compose -f "$COMPOSE_FILE" up -d
    
    log_success "服務啟動完成！"
    
    # 等待服務就緒
    log_info "等待服務就緒..."
    sleep 10
    
    # 檢查服務狀態
    check_services_health
}

# 停止服務
stop_services() {
    log_info "停止 Whisper API 服務..."
    
    load_env_vars
    docker compose -f "$COMPOSE_FILE" down
    log_success "服務已停止"
}

# 重啟服務
restart_services() {
    log_info "重啟 Whisper API 服務..."
    load_env_vars
    docker compose -f "$COMPOSE_FILE" restart
    log_success "服務重啟完成"
}

# 重新構建服務
build_services() {
    log_info "重新構建 Whisper API 服務..."
    
    load_env_vars
    docker compose -f "$COMPOSE_FILE" up -d --build
    log_success "服務構建並啟動完成"
}

# 清理並重啟
clean_restart() {
    log_info "清理並重新啟動服務..."
    load_env_vars
    docker compose -f "$COMPOSE_FILE" down -v
    docker system prune -f
    docker compose -f "$COMPOSE_FILE" up -d --build
    log_success "清理重啟完成"
}

# 顯示日誌
show_logs() {
    service=""
    # 檢查是否有服務名稱參數
    for arg in "$@"; do
        if [[ "$arg" != "--local" && "$arg" != "--cloud" && "$arg" != "logs" ]]; then
            service="$arg"
            break
        fi
    done
    
    load_env_vars
    if [ -z "$service" ]; then
        docker compose -f "$COMPOSE_FILE" logs -f
    else
        docker compose -f "$COMPOSE_FILE" logs -f "$service"
    fi
}

# 檢查服務健康狀態
check_services_health() {
    log_info "檢查服務狀態..."
    
    load_env_vars
    # 檢查容器狀態
    docker compose -f "$COMPOSE_FILE" ps
    
    echo ""
    log_info "測試 API 健康狀態..."
    
    # 測試本地 API
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        log_success "本地 API (http://localhost:8000) 運行正常"
    else
        log_warning "本地 API 可能還未就緒，請稍後再試"
    fi
    
    # 如果使用 Cloudflare 配置，測試外部訪問
    if [[ "$COMPOSE_FILE" == *"cloudflare"* ]]; then
        if curl -s https://whisper.itr-lab.cloud/health > /dev/null 2>&1; then
            log_success "外部 API (https://whisper.itr-lab.cloud) 運行正常"
        else
            log_warning "外部 API 可能還未就緒，請稍後再試"
        fi
    fi
}

# 顯示服務訪問信息
show_access_info() {
    echo ""
    log_info "服務訪問信息:"
    echo "  • API 端點: http://localhost:8000"
    echo "  • API 文檔: http://localhost:8000/docs"
    echo "  • 健康檢查: http://localhost:8000/health"
    
    if [[ "$COMPOSE_FILE" == *"cloudflare"* ]]; then
        echo "  • 外部訪問: https://whisper.itr-lab.cloud"
        echo "  • 外部文檔: https://whisper.itr-lab.cloud/docs"
    fi
    
    echo "  • Nginx: http://localhost:81"
    echo "  • Redis: localhost:6381"
    echo ""
}

# 主函數
main() {
    # 切換到腳本目錄
    cd "$(dirname "$0")"
    
    # 解析命令行參數
    command=${1:-start}
    
    case $command in
        help|--help|-h)
            show_help
            exit 0
            ;;
        start)
            check_requirements
            create_directories
            check_env_file
            select_compose_file "$@"
            start_services
            show_access_info
            ;;
        stop)
            select_compose_file "$@"
            stop_services
            ;;
        restart)
            select_compose_file "$@"
            restart_services
            ;;
        build)
            check_requirements
            create_directories
            check_env_file
            select_compose_file "$@"
            build_services
            show_access_info
            ;;
        clean)
            select_compose_file "$@"
            clean_restart
            show_access_info
            ;;
        logs)
            select_compose_file "$@"
            show_logs "$@"
            ;;
        status)
            select_compose_file "$@"
            check_services_health
            show_access_info
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 執行主函數
main "$@"
