#!/bin/bash

# Interactive Shell Script for Audio Transcription using Whisper

# Generate a random file name for the temporary WAV file
TEMP_WAV_FILE="temp_$(date +%s%N).wav"

# Function to clean up temporary files
cleanup() {
    echo "Cleaning up temporary files..."
    rm -f "$TEMP_WAV_FILE"
    echo "Temporary files cleaned up."
}

# Trap to handle script exit
trap cleanup EXIT

# Prompt the user for input and output file paths
echo "Welcome to the Audio Transcription Script!"
read -p "Enter the path to the input audio file (with extension NO SPACE): " INPUT_PATH
read -p "Enter the desired path for the output transcription file (without space): " OUTPUT_PATH

# Check if the input file exists
if [[ ! -f "$INPUT_PATH" ]]; then
    echo "Error: Input file not found at '$INPUT_PATH'. Exiting."
    exit 1
fi

# Convert the input audio file to WAV format
echo "Converting the input audio file to WAV format..."
ffmpeg -i "$INPUT_PATH" -ar 16000 -ac 1 -c:a pcm_s16le "$TEMP_WAV_FILE"
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to convert audio file. Exiting."
    exit 1
fi
echo "Audio file successfully converted to WAV format."

# Perform transcription using Whisper CLI
echo "Running Whisper transcription..."
./whisper.cpp/build/bin/whisper-cli -mc 0 -otxt -of "$OUTPUT_PATH" -m ./whisper.cpp/models/ggml-large-v3-turbo.bin -f "$TEMP_WAV_FILE"
if [[ $? -ne 0 ]]; then
    echo "Error: Whisper transcription failed. Exiting."
    exit 1
fi
echo "Transcription completed. Output saved to '$OUTPUT_PATH'."

# Success message
echo "Process completed successfully!"
