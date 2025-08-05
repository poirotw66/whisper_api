<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Whisper API Service Development Guidelines

This is a FastAPI-based service for OpenAI Whisper speech transcription and translation.

## Project Context
- **Framework**: FastAPI with async/await patterns
- **ML Model**: OpenAI Whisper for speech recognition
- **File Handling**: Supports multiple audio formats (mp3, wav, flac, m4a)
- **Deployment**: Docker containerization with nginx reverse proxy

## Code Style Guidelines
- Use async/await for I/O operations
- Follow FastAPI patterns for endpoint definitions
- Use Pydantic models for request/response validation
- Implement proper error handling with HTTPException
- Use type hints throughout the codebase

## Key Dependencies
- FastAPI for API framework
- OpenAI Whisper for speech processing
- PyTorch for ML operations
- aiofiles for async file operations
- pydantic for data validation

## Architecture Patterns
- Separate concerns: models, services, configuration
- Use dependency injection for settings
- Implement background tasks for long-running operations
- Cache Whisper models in memory for performance

## Security Considerations
- Validate file types and sizes
- Implement rate limiting in production
- Use CORS middleware appropriately
- Clean up temporary files after processing

## Performance Tips
- Use appropriate Whisper model sizes based on requirements
- Implement model caching to avoid reloading
- Consider GPU acceleration when available
- Use async processing for large files
