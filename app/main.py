from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import os
import time
import uuid
import aiofiles
from typing import Optional
from datetime import datetime

from app.models import (
    TranscriptionRequest,
    TranscriptionResponse,
    AsyncTaskResponse,
    TaskResult,
    TaskStatus,
    WhisperModel,
    TaskType
)
from app.whisper_service import whisper_service
from app.config import get_settings

settings = get_settings()

app = FastAPI(
    title=settings.api_title,
    version=settings.api_version,
    description="FastAPI service for OpenAI Whisper speech transcription and translation",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure as needed for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory task storage (use Redis in production)
tasks_db = {}


@app.on_event("startup")
async def startup_event():
    """Initialize directories on startup."""
    os.makedirs(settings.upload_dir, exist_ok=True)
    os.makedirs(settings.temp_dir, exist_ok=True)
    os.makedirs(settings.model_cache_dir, exist_ok=True)
    print("Whisper API service started successfully!")


@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "message": "Whisper API Service",
        "version": settings.api_version,
        "docs": "/docs",
        "health": "/health"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "whisper-api"
    }


@app.get("/models")
async def list_models():
    """List available Whisper models."""
    return {
        "available_models": [model.value for model in WhisperModel],
        "default_model": settings.whisper_model,
        "recommended": {
            "fastest": "tiny",
            "balanced": "base", 
            "quality": "small",
            "best_quality": "large",
            "turbo": "turbo"
        }
    }


@app.post("/transcribe", response_model=TranscriptionResponse)
async def transcribe_audio(
    file: UploadFile = File(...),
    model: WhisperModel = Form(WhisperModel.TURBO),
    task: TaskType = Form(TaskType.TRANSCRIBE),
    language: Optional[str] = Form(None),
    temperature: Optional[float] = Form(0.0),
    best_of: Optional[int] = Form(5),
    beam_size: Optional[int] = Form(5)
):
    """Synchronous audio transcription endpoint."""
    
    # Validate file
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file provided")
    
    # Check file size
    file_size = 0
    content = await file.read()
    file_size = len(content)
    
    max_size = parse_size(settings.max_file_size)
    if file_size > max_size:
        raise HTTPException(
            status_code=413, 
            detail=f"File size exceeds maximum allowed size of {settings.max_file_size}"
        )
    
    # Save uploaded file
    file_id = str(uuid.uuid4())
    file_extension = os.path.splitext(file.filename)[1]
    temp_file_path = os.path.join(settings.temp_dir, f"{file_id}{file_extension}")
    
    try:
        async with aiofiles.open(temp_file_path, 'wb') as f:
            await f.write(content)
        
        # Process transcription
        start_time = time.time()
        
        result = whisper_service.transcribe_audio(
            audio_path=temp_file_path,
            model_name=model,
            task=task.value,
            language=language,
            temperature=temperature,
            best_of=best_of,
            beam_size=beam_size
        )
        
        processing_time = time.time() - start_time
        
        response = TranscriptionResponse(
            text=result["text"],
            language=result.get("language"),
            segments=result.get("segments"),
            processing_time=processing_time,
            model_used=result["model_used"]
        )
        
        return response
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transcription failed: {str(e)}")
    
    finally:
        # Cleanup temp file
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)


@app.post("/transcribe/async", response_model=AsyncTaskResponse)
async def transcribe_audio_async(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    model: WhisperModel = Form(WhisperModel.TURBO),
    task: TaskType = Form(TaskType.TRANSCRIBE),
    language: Optional[str] = Form(None),
    temperature: Optional[float] = Form(0.0),
    best_of: Optional[int] = Form(5),
    beam_size: Optional[int] = Form(5)
):
    """Asynchronous audio transcription endpoint."""
    
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file provided")
    
    # Generate task ID
    task_id = str(uuid.uuid4())
    
    # Save file for background processing
    file_extension = os.path.splitext(file.filename)[1]
    temp_file_path = os.path.join(settings.temp_dir, f"{task_id}{file_extension}")
    
    content = await file.read()
    async with aiofiles.open(temp_file_path, 'wb') as f:
        await f.write(content)
    
    # Create task record
    tasks_db[task_id] = TaskResult(
        task_id=task_id,
        status=TaskStatus.PENDING,
        created_at=datetime.now().isoformat()
    )
    
    # Add background task
    background_tasks.add_task(
        process_transcription_task,
        task_id,
        temp_file_path,
        model,
        task,
        language,
        temperature,
        best_of,
        beam_size
    )
    
    return AsyncTaskResponse(
        task_id=task_id,
        status=TaskStatus.PENDING,
        message="Task queued for processing"
    )


@app.get("/tasks/{task_id}", response_model=TaskResult)
async def get_task_status(task_id: str):
    """Get status and result of an async transcription task."""
    if task_id not in tasks_db:
        raise HTTPException(status_code=404, detail="Task not found")
    
    return tasks_db[task_id]


@app.post("/detect-language")
async def detect_language(
    file: UploadFile = File(...),
    model: WhisperModel = Form(WhisperModel.BASE)
):
    """Detect the language of an audio file."""
    
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file provided")
    
    # Save temporary file
    file_id = str(uuid.uuid4())
    file_extension = os.path.splitext(file.filename)[1]
    temp_file_path = os.path.join(settings.temp_dir, f"{file_id}{file_extension}")
    
    try:
        content = await file.read()
        async with aiofiles.open(temp_file_path, 'wb') as f:
            await f.write(content)
        
        # Detect language
        result = whisper_service.detect_language(temp_file_path, model)
        
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Language detection failed: {str(e)}")
    
    finally:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)


async def process_transcription_task(
    task_id: str,
    file_path: str,
    model: WhisperModel,
    task: TaskType,
    language: Optional[str],
    temperature: Optional[float],
    best_of: Optional[int],
    beam_size: Optional[int]
):
    """Background task for processing transcription."""
    try:
        # Update status to processing
        tasks_db[task_id].status = TaskStatus.PROCESSING
        
        start_time = time.time()
        
        # Process transcription
        result = whisper_service.transcribe_audio(
            audio_path=file_path,
            model_name=model,
            task=task.value,
            language=language,
            temperature=temperature,
            best_of=best_of,
            beam_size=beam_size
        )
        
        processing_time = time.time() - start_time
        
        # Create response
        response = TranscriptionResponse(
            text=result["text"],
            language=result.get("language"),
            segments=result.get("segments"),
            processing_time=processing_time,
            model_used=result["model_used"]
        )
        
        # Update task with result
        tasks_db[task_id].status = TaskStatus.COMPLETED
        tasks_db[task_id].result = response
        tasks_db[task_id].completed_at = datetime.now().isoformat()
        
    except Exception as e:
        # Update task with error
        tasks_db[task_id].status = TaskStatus.FAILED
        tasks_db[task_id].error = str(e)
        tasks_db[task_id].completed_at = datetime.now().isoformat()
    
    finally:
        # Cleanup temp file
        if os.path.exists(file_path):
            os.remove(file_path)


def parse_size(size_str: str) -> int:
    """Parse size string like '100MB' to bytes."""
    size_str = size_str.upper()
    if size_str.endswith('KB'):
        return int(size_str[:-2]) * 1024
    elif size_str.endswith('MB'):
        return int(size_str[:-2]) * 1024 * 1024
    elif size_str.endswith('GB'):
        return int(size_str[:-2]) * 1024 * 1024 * 1024
    else:
        return int(size_str)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
