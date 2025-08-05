from pydantic import BaseSettings
import os


class Settings(BaseSettings):
    # API Configuration
    api_title: str = "Whisper API"
    api_version: str = "1.0.0"
    api_debug: bool = False
    
    # Whisper Configuration
    whisper_model: str = "turbo"
    model_cache_dir: str = "./models"
    
    # File Upload Configuration
    max_file_size: str = "100MB"
    upload_dir: str = "./uploads"
    temp_dir: str = "./temp"
    
    # Redis Configuration (for background tasks)
    redis_url: str = "redis://localhost:6379/0"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


def get_settings() -> Settings:
    return Settings()
