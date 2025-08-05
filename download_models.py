#!/usr/bin/env python3
"""
Whisper 模型下載工具
下載並緩存不同大小的 Whisper 模型到 models/ 目錄
"""

import whisper
import os
import sys
from pathlib import Path

# 設置模型緩存目錄
MODELS_DIR = Path("./models")
MODELS_DIR.mkdir(exist_ok=True)

# 可用的模型列表（按照大小排序）
AVAILABLE_MODELS = {
    "tiny": {"size": "39M", "description": "最小模型，適合快速原型和實時轉錄"},
    "base": {"size": "74M", "description": "平衡性能和準確度的基礎模型"},
    "small": {"size": "244M", "description": "高質量轉錄，適合大多數應用"},
    "medium": {"size": "769M", "description": "專業級應用，更高準確度"},
    "large": {"size": "1550M", "description": "最高準確度，但速度較慢"},
    "turbo": {"size": "809M", "description": "優化版本，速度快且準確度高"}
}

def check_existing_models():
    """檢查已存在的模型"""
    print("🔍 檢查已存在的模型...")
    existing = []
    for model_file in MODELS_DIR.glob("*.pt"):
        model_name = model_file.stem
        if model_name in AVAILABLE_MODELS:
            size_mb = model_file.stat().st_size / (1024 * 1024)
            print(f"  ✅ {model_name}: {size_mb:.1f}MB")
            existing.append(model_name)
        else:
            print(f"  ❓ {model_name}: 未知模型")
    
    if not existing:
        print("  📭 目前沒有已下載的模型")
    
    return existing

def download_model(model_name):
    """下載指定的模型"""
    if model_name not in AVAILABLE_MODELS:
        print(f"❌ 模型 '{model_name}' 不存在")
        return False
    
    info = AVAILABLE_MODELS[model_name]
    print(f"📥 下載模型: {model_name} ({info['size']})")
    print(f"   描述: {info['description']}")
    
    try:
        # 使用 whisper.load_model 下載並緩存模型
        model = whisper.load_model(model_name, download_root=str(MODELS_DIR))
        print(f"✅ 模型 '{model_name}' 下載完成")
        
        # 檢查下載的文件大小
        model_file = MODELS_DIR / f"{model_name}.pt"
        if model_file.exists():
            size_mb = model_file.stat().st_size / (1024 * 1024)
            print(f"   文件大小: {size_mb:.1f}MB")
        
        return True
    except Exception as e:
        print(f"❌ 下載模型 '{model_name}' 失敗: {str(e)}")
        return False

def download_recommended_models():
    """下載推薦的模型組合"""
    recommended = ["tiny", "base", "small", "turbo"]
    print("🎯 下載推薦的模型組合...")
    
    success_count = 0
    for model_name in recommended:
        if download_model(model_name):
            success_count += 1
        print()  # 空行分隔
    
    print(f"📊 下載完成: {success_count}/{len(recommended)} 個模型成功下載")

def main():
    print("🤖 Whisper 模型下載工具")
    print("=" * 50)
    
    # 檢查現有模型
    existing_models = check_existing_models()
    print()
    
    # 顯示可用模型
    print("📋 可用模型列表:")
    for name, info in AVAILABLE_MODELS.items():
        status = "✅ 已下載" if name in existing_models else "⬇️  可下載"
        print(f"  {name:8} ({info['size']:>6}) - {info['description']} {status}")
    print()
    
    # 處理命令行參數
    if len(sys.argv) > 1:
        if sys.argv[1] == "all":
            print("⬇️  下載所有模型...")
            for model_name in AVAILABLE_MODELS.keys():
                if model_name not in existing_models:
                    download_model(model_name)
                    print()
        elif sys.argv[1] == "recommended":
            download_recommended_models()
        elif sys.argv[1] in AVAILABLE_MODELS:
            model_name = sys.argv[1]
            if model_name in existing_models:
                print(f"ℹ️  模型 '{model_name}' 已存在")
            else:
                download_model(model_name)
        else:
            print(f"❌ 未知參數: {sys.argv[1]}")
            print("用法: python download_models.py [模型名稱|all|recommended]")
    else:
        # 互動模式
        print("請選擇操作:")
        print("1. 下載推薦模型組合 (tiny, base, small, turbo)")
        print("2. 下載所有模型")
        print("3. 下載特定模型")
        print("4. 退出")
        
        choice = input("\n請輸入選擇 (1-4): ").strip()
        
        if choice == "1":
            download_recommended_models()
        elif choice == "2":
            print("⬇️  下載所有模型...")
            for model_name in AVAILABLE_MODELS.keys():
                if model_name not in existing_models:
                    download_model(model_name)
                    print()
        elif choice == "3":
            print("\n可下載的模型:")
            available_to_download = [name for name in AVAILABLE_MODELS.keys() if name not in existing_models]
            for i, name in enumerate(available_to_download, 1):
                info = AVAILABLE_MODELS[name]
                print(f"{i}. {name} ({info['size']}) - {info['description']}")
            
            if available_to_download:
                try:
                    model_choice = int(input(f"\n請選擇模型 (1-{len(available_to_download)}): ")) - 1
                    if 0 <= model_choice < len(available_to_download):
                        model_name = available_to_download[model_choice]
                        download_model(model_name)
                    else:
                        print("❌ 無效選擇")
                except ValueError:
                    print("❌ 請輸入有效數字")
            else:
                print("✅ 所有模型都已下載")
        elif choice == "4":
            print("👋 再見!")
        else:
            print("❌ 無效選擇")

if __name__ == "__main__":
    main()
