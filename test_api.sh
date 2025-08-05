# Test the API with sample audio files

## Create a test audio file
echo "Testing Whisper API with text-to-speech" | espeak -w test_audio.wav

## Test synchronous transcription
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=tiny" \
  -F "task=transcribe"

## Test asynchronous transcription
TASK_ID=$(curl -X POST "http://localhost:8000/transcribe/async" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=base" | jq -r '.task_id')

echo "Task ID: $TASK_ID"

## Check task status
curl "http://localhost:8000/tasks/$TASK_ID"

## Test language detection
curl -X POST "http://localhost:8000/detect-language" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_audio.wav" \
  -F "model=base"

## Test with different audio formats
# You can test with various audio formats:
# - MP3: curl ... -F "file=@audio.mp3"
# - FLAC: curl ... -F "file=@audio.flac" 
# - M4A: curl ... -F "file=@audio.m4a"

## Performance testing with different models
echo "Testing different models..."

for model in tiny base small medium; do
  echo "Testing model: $model"
  time curl -X POST "http://localhost:8000/transcribe" \
    -H "Content-Type: multipart/form-data" \
    -F "file=@test_audio.wav" \
    -F "model=$model" \
    -F "task=transcribe"
  echo ""
done
