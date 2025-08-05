# Whisper API Client Examples

## Python Client Example

```python
import requests
import json

class WhisperAPIClient:
    def __init__(self, base_url="http://localhost:8000"):
        self.base_url = base_url
    
    def transcribe_sync(self, audio_file_path, model="turbo", task="transcribe", language=None):
        """Synchronous transcription."""
        url = f"{self.base_url}/transcribe"
        
        with open(audio_file_path, 'rb') as f:
            files = {'file': f}
            data = {
                'model': model,
                'task': task,
            }
            if language:
                data['language'] = language
            
            response = requests.post(url, files=files, data=data)
            return response.json()
    
    def transcribe_async(self, audio_file_path, model="turbo", task="transcribe", language=None):
        """Asynchronous transcription."""
        url = f"{self.base_url}/transcribe/async"
        
        with open(audio_file_path, 'rb') as f:
            files = {'file': f}
            data = {
                'model': model,
                'task': task,
            }
            if language:
                data['language'] = language
            
            response = requests.post(url, files=files, data=data)
            return response.json()
    
    def get_task_status(self, task_id):
        """Get async task status."""
        url = f"{self.base_url}/tasks/{task_id}"
        response = requests.get(url)
        return response.json()
    
    def detect_language(self, audio_file_path, model="base"):
        """Detect audio language."""
        url = f"{self.base_url}/detect-language"
        
        with open(audio_file_path, 'rb') as f:
            files = {'file': f}
            data = {'model': model}
            
            response = requests.post(url, files=files, data=data)
            return response.json()

# Usage example
if __name__ == "__main__":
    client = WhisperAPIClient()
    
    # Synchronous transcription
    result = client.transcribe_sync("audio.mp3", model="base")
    print("Transcription:", result['text'])
    
    # Asynchronous transcription
    task = client.transcribe_async("audio.mp3", model="small")
    task_id = task['task_id']
    
    # Poll for result
    import time
    while True:
        status = client.get_task_status(task_id)
        if status['status'] == 'completed':
            print("Async transcription:", status['result']['text'])
            break
        elif status['status'] == 'failed':
            print("Error:", status['error'])
            break
        time.sleep(1)
```

## JavaScript/Node.js Client Example

```javascript
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

class WhisperAPIClient {
    constructor(baseUrl = 'http://localhost:8000') {
        this.baseUrl = baseUrl;
    }

    async transcribeSync(audioFilePath, options = {}) {
        const formData = new FormData();
        formData.append('file', fs.createReadStream(audioFilePath));
        formData.append('model', options.model || 'turbo');
        formData.append('task', options.task || 'transcribe');
        
        if (options.language) {
            formData.append('language', options.language);
        }

        const response = await axios.post(`${this.baseUrl}/transcribe`, formData, {
            headers: formData.getHeaders(),
        });

        return response.data;
    }

    async transcribeAsync(audioFilePath, options = {}) {
        const formData = new FormData();
        formData.append('file', fs.createReadStream(audioFilePath));
        formData.append('model', options.model || 'turbo');
        formData.append('task', options.task || 'transcribe');
        
        if (options.language) {
            formData.append('language', options.language);
        }

        const response = await axios.post(`${this.baseUrl}/transcribe/async`, formData, {
            headers: formData.getHeaders(),
        });

        return response.data;
    }

    async getTaskStatus(taskId) {
        const response = await axios.get(`${this.baseUrl}/tasks/${taskId}`);
        return response.data;
    }

    async detectLanguage(audioFilePath, model = 'base') {
        const formData = new FormData();
        formData.append('file', fs.createReadStream(audioFilePath));
        formData.append('model', model);

        const response = await axios.post(`${this.baseUrl}/detect-language`, formData, {
            headers: formData.getHeaders(),
        });

        return response.data;
    }
}

// Usage
(async () => {
    const client = new WhisperAPIClient();
    
    try {
        // Synchronous transcription
        const result = await client.transcribeSync('audio.mp3', { model: 'base' });
        console.log('Transcription:', result.text);
        
        // Language detection
        const language = await client.detectLanguage('audio.mp3');
        console.log('Detected language:', language.detected_language);
    } catch (error) {
        console.error('Error:', error.response?.data || error.message);
    }
})();
```

## cURL Examples

### Basic transcription
```bash
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@audio.mp3" \
  -F "model=turbo" \
  -F "task=transcribe"
```

### Translation to English
```bash
curl -X POST "http://localhost:8000/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@japanese_audio.mp3" \
  -F "model=medium" \
  -F "task=translate" \
  -F "language=Japanese"
```

### Asynchronous processing
```bash
# Submit task
TASK_ID=$(curl -X POST "http://localhost:8000/transcribe/async" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@large_audio.mp3" \
  -F "model=large" | jq -r '.task_id')

# Check status
curl "http://localhost:8000/tasks/$TASK_ID"
```

### Language detection
```bash
curl -X POST "http://localhost:8000/detect-language" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@unknown_language.mp3" \
  -F "model=base"
```
