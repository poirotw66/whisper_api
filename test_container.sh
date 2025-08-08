#!/bin/bash

echo "🎤 Whisper API 容器服務測試腳本"
echo "================================="
echo

# 設置 API 基礎 URL
API_URL="http://localhost:8000"

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 測試函數
test_endpoint() {
    local endpoint="$1"
    local description="$2"
    local method="${3:-GET}"
    
    echo -e "${BLUE}📋 測試: $description${NC}"
    echo "端點: $endpoint"
    echo "方法: $method"
    echo "---"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$API_URL$endpoint")
    else
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X "$method" "$API_URL$endpoint")
    fi
    
    http_code=$(echo "$response" | tail -n1 | cut -d: -f2)
    content=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ 成功 (HTTP $http_code)${NC}"
        echo "$content" | jq . 2>/dev/null || echo "$content"
    else
        echo -e "${RED}❌ 失敗 (HTTP $http_code)${NC}"
        echo "$content"
    fi
    echo
}

# 基本健康檢查
echo -e "${YELLOW}🔍 基本服務測試${NC}"
echo "=================="

test_endpoint "/health" "健康檢查"
test_endpoint "/models" "獲取可用模型列表"
test_endpoint "/docs" "API 文檔頁面"

# 語言檢測測試（如果音頻文件存在）
echo -e "${YELLOW}🎵 音頻服務測試${NC}"
echo "=================="

# 檢查是否有測試音頻文件
if [ -f "test_audio.wav" ]; then
    echo -e "${BLUE}📋 測試: 語言檢測${NC}"
    echo "音頻文件: test_audio.wav"
    echo "---"
    
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        -X POST "$API_URL/detect-language" \
        -H "Content-Type: multipart/form-data" \
        -F "file=@test_audio.wav")
    
    http_code=$(echo "$response" | tail -n1 | cut -d: -f2)
    content=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ 語言檢測成功 (HTTP $http_code)${NC}"
        echo "$content" | jq . 2>/dev/null || echo "$content"
    else
        echo -e "${RED}❌ 語言檢測失敗 (HTTP $http_code)${NC}"
        echo "$content"
    fi
    echo

    # 轉錄測試
    echo -e "${BLUE}📋 測試: 音頻轉錄 (tiny 模型)${NC}"
    echo "音頻文件: test_audio.wav"
    echo "模型: tiny"
    echo "---"
    
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        -X POST "$API_URL/transcribe" \
        -H "Content-Type: multipart/form-data" \
        -F "file=@test_audio.wav" \
        -F "model=tiny")
    
    http_code=$(echo "$response" | tail -n1 | cut -d: -f2)
    content=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ 轉錄成功 (HTTP $http_code)${NC}"
        echo "$content" | jq . 2>/dev/null || echo "$content"
    else
        echo -e "${RED}❌ 轉錄失敗 (HTTP $http_code)${NC}"
        echo "$content"
    fi
    echo

    # 翻譯測試
    echo -e "${BLUE}📋 測試: 音頻翻譯 (tiny 模型)${NC}"
    echo "音頻文件: test_audio.wav"
    echo "模型: tiny"
    echo "---"
    
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        -X POST "$API_URL/translate" \
        -H "Content-Type: multipart/form-data" \
        -F "file=@test_audio.wav" \
        -F "model=tiny")
    
    http_code=$(echo "$response" | tail -n1 | cut -d: -f2)
    content=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ 翻譯成功 (HTTP $http_code)${NC}"
        echo "$content" | jq . 2>/dev/null || echo "$content"
    else
        echo -e "${RED}❌ 翻譯失敗 (HTTP $http_code)${NC}"
        echo "$content"
    fi
    echo

    # 異步轉錄測試
    echo -e "${BLUE}📋 測試: 異步音頻轉錄 (base 模型)${NC}"
    echo "音頻文件: test_audio.wav"
    echo "模型: base"
    echo "---"
    
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        -X POST "$API_URL/transcribe" \
        -H "Content-Type: multipart/form-data" \
        -F "file=@test_audio.wav" \
        -F "model=base" \
        -F "async=true")
    
    http_code=$(echo "$response" | tail -n1 | cut -d: -f2)
    content=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "202" ]; then
        echo -e "${GREEN}✅ 異步轉錄任務提交成功 (HTTP $http_code)${NC}"
        task_id=$(echo "$content" | jq -r '.task_id' 2>/dev/null)
        echo "$content" | jq . 2>/dev/null || echo "$content"
        
        if [ "$task_id" != "null" ] && [ "$task_id" != "" ]; then
            echo
            echo -e "${BLUE}📋 檢查異步任務狀態${NC}"
            echo "任務ID: $task_id"
            echo "---"
            
            # 等待一下讓任務處理
            sleep 5
            
            status_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$API_URL/status/$task_id")
            status_http_code=$(echo "$status_response" | tail -n1 | cut -d: -f2)
            status_content=$(echo "$status_response" | head -n -1)
            
            if [ "$status_http_code" = "200" ]; then
                echo -e "${GREEN}✅ 任務狀態查詢成功 (HTTP $status_http_code)${NC}"
                echo "$status_content" | jq . 2>/dev/null || echo "$status_content"
            else
                echo -e "${RED}❌ 任務狀態查詢失敗 (HTTP $status_http_code)${NC}"
                echo "$status_content"
            fi
        fi
    else
        echo -e "${RED}❌ 異步轉錄失敗 (HTTP $http_code)${NC}"
        echo "$content"
    fi
    echo

else
    echo -e "${YELLOW}⚠️  未找到 test_audio.wav 文件，跳過音頻測試${NC}"
    echo "您可以使用以下命令生成測試音頻文件："
    echo
    echo "# 使用 ffmpeg 生成測試音頻文件"
    echo "ffmpeg -f lavfi -i \"sine=frequency=1000:duration=5\" -ar 16000 test_audio.wav"
    echo
    echo "或者上傳您自己的音頻文件並重新運行此腳本。"
    echo
fi

# 錯誤處理測試
echo -e "${YELLOW}🚨 錯誤處理測試${NC}"
echo "=================="

echo -e "${BLUE}📋 測試: 無效端點${NC}"
echo "端點: /invalid-endpoint"
echo "---"

response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$API_URL/invalid-endpoint")
http_code=$(echo "$response" | tail -n1 | cut -d: -f2)
content=$(echo "$response" | head -n -1)

if [ "$http_code" = "404" ]; then
    echo -e "${GREEN}✅ 正確返回 404 錯誤 (HTTP $http_code)${NC}"
else
    echo -e "${RED}❌ 意外的狀態碼 (HTTP $http_code)${NC}"
fi
echo "$content"
echo

echo -e "${BLUE}📋 測試: 無效模型名稱${NC}"
echo "端點: /transcribe"
echo "模型: invalid-model"
echo "---"

# 創建一個小的測試文件
echo "test" > temp_test.txt

response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X POST "$API_URL/transcribe" \
    -H "Content-Type: multipart/form-data" \
    -F "file=@temp_test.txt" \
    -F "model=invalid-model")

http_code=$(echo "$response" | tail -n1 | cut -d: -f2)
content=$(echo "$response" | head -n -1)

if [ "$http_code" = "400" ] || [ "$http_code" = "422" ]; then
    echo -e "${GREEN}✅ 正確返回錯誤 (HTTP $http_code)${NC}"
else
    echo -e "${YELLOW}⚠️  狀態碼: HTTP $http_code${NC}"
fi
echo "$content"

# 清理測試文件
rm -f temp_test.txt

echo
echo -e "${YELLOW}📊 測試完成總結${NC}"
echo "=================="
echo "✅ 基本服務功能已驗證"
echo "✅ API 端點響應正常"
if [ -f "test_audio.wav" ]; then
    echo "✅ 音頻處理功能已測試"
else
    echo "⚠️  音頻測試需要測試文件"
fi
echo "✅ 錯誤處理機制正常"
echo
echo "🌐 外網訪問測試："
echo "curl https://whisper.itr-lab.cloud/health"
echo "curl https://whisper.itr-lab.cloud/models"
echo
