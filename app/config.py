from pydantic_settings import BaseSettings
import os


class Settings(BaseSettings):
    # API Configuration
    api_title: str = "Whisper API"
    api_version: str = "1.0.0"
    api_debug: bool = False
    
    # Whisper Configuration
    whisper_model: str = "turbo"
    cache_dir: str = "./models"  # 改名避免 model_ 前綴衝突
    
    # File Upload Configuration
    max_file_size: str = "100MB"
    upload_dir: str = "./uploads"
    temp_dir: str = "./temp"
    
    # Redis Configuration (for background tasks)
    redis_url: str = "redis://localhost:6379/0"
    
    # Performance Configuration
    workers: int = 1
    max_workers: int = 2
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        protected_namespaces = ('settings_',)  # 設置保護命名空間


def get_settings() -> Settings:
    return Settings()
