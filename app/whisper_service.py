import whisper
import torch
import os
from typing import Dict, Optional
from app.models import WhisperModel


class WhisperService:
    def __init__(self):
        self.models: Dict[str, whisper.Whisper] = {}
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"Using device: {self.device}")

    def load_model(self, model_name: WhisperModel) -> whisper.Whisper:
        """Load a Whisper model, caching it for reuse."""
        model_key = model_name.value
        
        if model_key not in self.models:
            print(f"Loading Whisper model: {model_key}")
            try:
                # Set model cache directory
                cache_dir = os.getenv("CACHE_DIR", "./models")
                os.makedirs(cache_dir, exist_ok=True)
                
                model = whisper.load_model(
                    model_key, 
                    device=self.device,
                    download_root=cache_dir
                )
                self.models[model_key] = model
                print(f"Successfully loaded model: {model_key}")
            except Exception as e:
                print(f"Error loading model {model_key}: {str(e)}")
                raise
        
        return self.models[model_key]

    def transcribe_audio(
        self,
        audio_path: str,
        model_name: WhisperModel,
        task: str = "transcribe",
        language: Optional[str] = None,
        **kwargs
    ) -> dict:
        """Transcribe audio file using specified Whisper model."""
        try:
            model = self.load_model(model_name)
            
            # Prepare transcription options
            options = {
                "task": task,
                "language": language,
                **kwargs
            }
            
            # Remove None values
            options = {k: v for k, v in options.items() if v is not None}
            
            print(f"Transcribing {audio_path} with model {model_name.value}")
            result = model.transcribe(audio_path, **options)
            
            return {
                "text": result["text"],
                "language": result.get("language"),
                "segments": result.get("segments", []),
                "whisper_model": model_name.value
            }
            
        except Exception as e:
            print(f"Error during transcription: {str(e)}")
            raise

    def detect_language(self, audio_path: str, model_name: WhisperModel) -> dict:
        """Detect the language of the audio file."""
        try:
            model = self.load_model(model_name)
            
            # Load and process audio
            audio = whisper.load_audio(audio_path)
            audio = whisper.pad_or_trim(audio)
            
            # Make log-Mel spectrogram
            mel = whisper.log_mel_spectrogram(audio, n_mels=model.dims.n_mels).to(model.device)
            
            # Detect language
            _, probs = model.detect_language(mel)
            detected_language = max(probs, key=probs.get)
            
            return {
                "detected_language": detected_language,
                "probabilities": probs
            }
            
        except Exception as e:
            print(f"Error during language detection: {str(e)}")
            raise


# Global instance
whisper_service = WhisperService()
