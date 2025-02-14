#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Starting the setup for Whisper..."

# Step 1: Check and install Homebrew
if command_exists brew; then
    echo "Homebrew is already installed."
else
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to install Homebrew."
        exit 1
    fi
fi

# Step 2: Add Homebrew to PATH
if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
    echo "Adding Homebrew to PATH..."
    echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Step 3: Install Python
if command_exists python3; then
    echo "Python is already installed."
else
    echo "Installing Python..."
    brew install python
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to install Python."
        exit 1
    fi
fi

# Step 4: Install pip
echo "Ensuring pip is installed and updated..."
python3 -m ensurepip --upgrade

# Step 5: Install Git
if command_exists git; then
    echo "Git is already installed."
else
    echo "Installing Git..."
    brew install git
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to install Git."
        exit 1
    fi
fi

# Step 6: Install CMake
if command_exists cmake; then
    echo "CMake is already installed."
else
    echo "Installing CMake..."
    brew install cmake
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to install CMake."
        exit 1
    fi
fi

# Step 6.1: Install FFmpeg
if command_exists ffmpeg; then
    echo "FFmpeg is already installed."
else
    echo "Installing FFmpeg..."
    brew install ffmpeg
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to install FFmpeg."
        exit 1
    fi
fi

# Step 7: Clone whisper.cpp repository
if [[ -d "whisper.cpp" ]]; then
    echo "whisper.cpp repository already exists."
else
    echo "Cloning whisper.cpp repository..."
    git clone https://github.com/ggerganov/whisper.cpp.git
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to clone whisper.cpp repository."
        exit 1
    fi
fi

# Step 8: Change to whisper.cpp directory
cd whisper.cpp || { echo "Error: Failed to change to whisper.cpp directory."; exit 1; }

# Step 9: Download the model
echo "Downloading the model..."
make -j large-v3-turbo
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to download the model."
    exit 1
fi

# Step 10: Add Core ML support
echo "Installing dependencies for Core ML support..."
pip3 install ane_transformers openai-whisper coremltools
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to install Core ML dependencies."
    exit 1
fi

# Step 11: Generate a Core ML model
echo "Generating Core ML model..."
./models/generate-coreml-model.sh large-v3-turbo
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to generate Core ML model."
    exit 1
fi

# Step 12: Build Whisper with Core ML support
echo "Building Whisper with Core ML support..."
cmake -B build -DWHISPER_COREML=1
cmake --build build -j --config Release
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to build Whisper."
    exit 1
fi

./build/bin/quantize models/ggml-large-v3-turbo.bin models/ggml-large-v3-turbo.q5_0.bin q5_0
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to quantize model."
    exit 1
fi
echo "Setup complete! Whisper is ready to use."
