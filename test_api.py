#!/usr/bin/env python3
"""
Whisper API 測試腳本
測試語音轉錄和翻譯功能
"""

import requests
import json
import os
import time
from pathlib import Path


class WhisperAPITester:
    def __init__(self, base_url="http://localhost:8000"):
        self.base_url = base_url
        
    def test_health(self):
        """測試健康檢查"""
        print("🔍 測試健康檢查...")
        response = requests.get(f"{self.base_url}/health")
        print(f"狀態碼: {response.status_code}")
        print(f"響應: {response.json()}")
        print()
        
    def test_models(self):
        """測試模型列表"""
        print("🔍 測試模型列表...")
        response = requests.get(f"{self.base_url}/models")
        print(f"狀態碼: {response.status_code}")
        data = response.json()
        print(f"可用模型: {data['available_models']}")
        print(f"默認模型: {data['default_model']}")
        print()
        
    def create_test_audio(self, filename="test_audio.wav"):
        """創建測試用的音頻文件（如果系統支持）"""
        # 這裡可以添加創建測試音頻的邏輯
        # 目前返回 None，需要手動提供音頻文件
        return None
        
    def test_transcription(self, audio_file_path, model="tiny"):
        """測試語音轉錄"""
        if not Path(audio_file_path).exists():
            print(f"❌ 音頻文件不存在: {audio_file_path}")
            return
            
        print(f"🔍 測試語音轉錄 (模型: {model})...")
        
        with open(audio_file_path, 'rb') as f:
            files = {'file': f}
            data = {'model': model, 'task': 'transcribe'}
            
            start_time = time.time()
            response = requests.post(f"{self.base_url}/transcribe", files=files, data=data)
            elapsed_time = time.time() - start_time
            
        print(f"狀態碼: {response.status_code}")
        print(f"請求時間: {elapsed_time:.2f} 秒")
        
        if response.status_code == 200:
            result = response.json()
            print(f"轉錄文本: {result['text']}")
            print(f"語言: {result.get('language', 'Unknown')}")
            print(f"使用模型: {result['whisper_model']}")
            print(f"處理時間: {result['processing_time']:.2f} 秒")
        else:
            print(f"錯誤: {response.text}")
        print()
        
    def test_translation(self, audio_file_path, model="tiny"):
        """測試語音翻譯"""
        if not Path(audio_file_path).exists():
            print(f"❌ 音頻文件不存在: {audio_file_path}")
            return
            
        print(f"🔍 測試語音翻譯 (模型: {model})...")
        
        with open(audio_file_path, 'rb') as f:
            files = {'file': f}
            data = {'model': model, 'task': 'translate'}
            
            start_time = time.time()
            response = requests.post(f"{self.base_url}/transcribe", files=files, data=data)
            elapsed_time = time.time() - start_time
            
        print(f"狀態碼: {response.status_code}")
        print(f"請求時間: {elapsed_time:.2f} 秒")
        
        if response.status_code == 200:
            result = response.json()
            print(f"翻譯文本: {result['text']}")
            print(f"使用模型: {result['whisper_model']}")
            print(f"處理時間: {result['processing_time']:.2f} 秒")
        else:
            print(f"錯誤: {response.text}")
        print()
        
    def test_async_transcription(self, audio_file_path, model="tiny"):
        """測試異步語音轉錄"""
        if not Path(audio_file_path).exists():
            print(f"❌ 音頻文件不存在: {audio_file_path}")
            return
            
        print(f"🔍 測試異步語音轉錄 (模型: {model})...")
        
        # 提交異步任務
        with open(audio_file_path, 'rb') as f:
            files = {'file': f}
            data = {'model': model, 'task': 'transcribe'}
            
            response = requests.post(f"{self.base_url}/transcribe/async", files=files, data=data)
            
        print(f"狀態碼: {response.status_code}")
        
        if response.status_code == 200:
            task_info = response.json()
            task_id = task_info['task_id']
            print(f"任務ID: {task_id}")
            print(f"狀態: {task_info['status']}")
            
            # 輪詢任務狀態
            print("⏳ 等待任務完成...")
            while True:
                status_response = requests.get(f"{self.base_url}/task/{task_id}")
                if status_response.status_code == 200:
                    status_data = status_response.json()
                    print(f"當前狀態: {status_data['status']}")
                    
                    if status_data['status'] == 'completed':
                        result = status_data['result']
                        print(f"✅ 轉錄完成!")
                        print(f"轉錄文本: {result['text']}")
                        print(f"使用模型: {result['whisper_model']}")
                        break
                    elif status_data['status'] == 'failed':
                        print(f"❌ 任務失敗: {status_data.get('error', 'Unknown error')}")
                        break
                else:
                    print(f"❌ 無法獲取任務狀態: {status_response.text}")
                    break
                    
                time.sleep(2)
        else:
            print(f"❌ 錯誤: {response.text}")
        print()

    def run_all_tests(self, audio_file_path=None):
        """運行所有測試"""
        print("🚀 Whisper API 測試開始")
        print("=" * 50)
        
        # 基礎測試
        self.test_health()
        self.test_models()
        
        # 如果提供了音頻文件，測試轉錄功能
        if audio_file_path and Path(audio_file_path).exists():
            self.test_transcription(audio_file_path, "tiny")
            self.test_translation(audio_file_path, "tiny")
            self.test_async_transcription(audio_file_path, "tiny")
        else:
            print("⚠️  沒有提供音頻文件，跳過轉錄測試")
            print("   可以下載測試音頻文件或提供自己的音頻文件進行測試")
            print()
        
        print("✅ 測試完成!")


if __name__ == "__main__":
    import sys
    
    tester = WhisperAPITester()
    
    # 檢查是否提供了音頻文件路徑
    audio_file = sys.argv[1] if len(sys.argv) > 1 else None
    
    if audio_file:
        print(f"📁 使用音頻文件: {audio_file}")
    else:
        print("💡 使用方式: python test_api.py [音頻文件路徑]")
        print("   例如: python test_api.py audio.wav")
        print()
    
    tester.run_all_tests(audio_file)
