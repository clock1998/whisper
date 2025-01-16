# Interactive PowerShell Script for Audio Transcription using Whisper

# Generate a random file name for the temporary WAV file
$TempWavFile = "temp_$((Get-Date).ToString("yyyyMMddHHmmssffff")).wav"

# Function to clean up temporary files
function Cleanup {
    Write-Host "Cleaning up temporary files..."
    if (Test-Path $TempWavFile) {
        Remove-Item -Force $TempWavFile
        Write-Host "Temporary files cleaned up."
    }
}

# Set up trap to handle script exit
$null = Register-EngineEvent -SourceIdentifier "PowerShell.Exiting" -Action { Cleanup }

# Prompt the user for input and output file paths
Write-Host "Welcome to the Audio Transcription Script!"
$InputPath = Read-Host "Enter the path to the input audio file (with extension NO SPACE)"
$OutputPath = Read-Host "Enter the desired path for the output transcription file (without space)"

# Check if the input file exists
if (-Not (Test-Path $InputPath)) {
    Write-Host "Error: Input file not found at '$InputPath'. Exiting." -ForegroundColor Red
    exit 1
}

# Convert the input audio file to WAV format
Write-Host "Converting the input audio file to WAV format..."
try {
    ffmpeg -i $InputPath -ar 16000 -ac 1 -c:a pcm_s16le $TempWavFile
    if ($LASTEXITCODE -ne 0) {
        throw "Error: Failed to convert audio file."
    }
    Write-Host "Audio file successfully converted to WAV format."
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Perform transcription using Whisper CLI
Write-Host "Running Whisper transcription..."
try {
    ./whisper.cpp/build/bin/whisper-cli -mc 0 -otxt -of $OutputPath -m ./whisper.cpp/models/ggml-large-v3-turbo.bin -f $TempWavFile
    if ($LASTEXITCODE -ne 0) {
        throw "Error: Whisper transcription failed."
    }
    Write-Host "Transcription completed. Output saved to '$OutputPath'."
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Success message
Write-Host "Process completed successfully!"
