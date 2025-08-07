from pydantic import BaseModel
from typing import Optional, List
from enum import Enum


class WhisperModel(str, Enum):
    TINY = "tiny"
    BASE = "base"
    SMALL = "small"
    MEDIUM = "medium"
    LARGE = "large"
    TURBO = "turbo"
    TINY_EN = "tiny.en"
    BASE_EN = "base.en"
    SMALL_EN = "small.en"
    MEDIUM_EN = "medium.en"


class TaskType(str, Enum):
    TRANSCRIBE = "transcribe"
    TRANSLATE = "translate"


class TranscriptionRequest(BaseModel):
    model: WhisperModel = WhisperModel.TURBO
    task: TaskType = TaskType.TRANSCRIBE
    language: Optional[str] = None
    temperature: Optional[float] = 0.0
    best_of: Optional[int] = 5
    beam_size: Optional[int] = 5


class TranscriptionResponse(BaseModel):
    text: str
    language: Optional[str] = None
    segments: Optional[List[dict]] = None
    processing_time: float
    whisper_model: str
    
    model_config = {"protected_namespaces": ()}


class TaskStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class AsyncTaskResponse(BaseModel):
    task_id: str
    status: TaskStatus
    message: str


class TaskResult(BaseModel):
    task_id: str
    status: TaskStatus
    result: Optional[TranscriptionResponse] = None
    error: Optional[str] = None
    created_at: str
    completed_at: Optional[str] = None
