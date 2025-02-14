# PowerShell Script to Set Up whisper.cpp

Write-Host "Starting the setup for whisper.cpp..." -ForegroundColor Green

# Step 1: Install Chocolatey
if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to install Chocolatey." -ForegroundColor Red
        exit 1
    }
    Write-Host "Chocolatey installed successfully." -ForegroundColor Green
} else {
    Write-Host "Chocolatey is already installed."
}

# Step 2: Install CMake
if (-Not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    Write-Host "Installing CMake..."
    choco install cmake -y
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to install CMake." -ForegroundColor Red
        exit 1
    }
    Write-Host "CMake installed successfully." -ForegroundColor Green
} else {
    Write-Host "CMake is already installed."
}

# Step 3: Install Python
if (-Not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Python..."
    choco install python3 --pre -y
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to install Python." -ForegroundColor Red
        exit 1
    }
    Write-Host "Python installed successfully." -ForegroundColor Green
} else {
    Write-Host "Python is already installed."
}

# Step 4: Install pip
Write-Host "Ensuring pip is installed and updated..."
python -m ensurepip --upgrade
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to install or upgrade pip." -ForegroundColor Red
    exit 1
}

# Step 5: Install FFmpeg
if (-Not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "Installing FFmpeg..."
    choco install ffmpeg -y
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to install FFmpeg." -ForegroundColor Red
        exit 1
    }
    Write-Host "FFmpeg installed successfully." -ForegroundColor Green
} else {
    Write-Host "FFmpeg is already installed."
}

# Step 6: Install Git
if (-Not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Git..."
    choco install git -y
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to install Git." -ForegroundColor Red
        exit 1
    }
    Write-Host "Git installed successfully." -ForegroundColor Green
} else {
    Write-Host "Git is already installed."
}

# Step 6.1: Add Git's sh.exe to PATH
$GitShPath = "C:\Program Files\Git\usr\bin"
if (-Not ($env:Path -like "*$GitShPath*")) {
    Write-Host "Adding Git's sh.exe to PATH..."
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$GitShPath", [EnvironmentVariableTarget]::Machine)
    Write-Host "Git's sh.exe added to PATH." -ForegroundColor Green
}

# Step 7: Clone whisper.cpp repository
if (-Not (Test-Path "./whisper.cpp")) {
    Write-Host "Cloning whisper.cpp repository..."
    git clone https://github.com/ggerganov/whisper.cpp.git
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to clone whisper.cpp repository." -ForegroundColor Red
        exit 1
    }
    Write-Host "whisper.cpp repository cloned successfully." -ForegroundColor Green
} else {
    Write-Host "whisper.cpp repository already exists."
}

# Step 8: Change directory to whisper.cpp
Set-Location ./whisper.cpp

# Step 9: Download the model
Write-Host "Downloading the model..."
make -j large-v3-turbo
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to download the model." -ForegroundColor Red
    exit 1
fi
Write-Host "Model downloaded successfully." -ForegroundColor Green

# Step 10: Generate a Core ML model
Write-Host "Generating Core ML model..."
./models/generate-coreml-model.sh large-v3-turbo
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to generate Core ML model." -ForegroundColor Red
    exit 1
fi
Write-Host "Core ML model generated successfully." -ForegroundColor Green

# Step 11: Build Whisper
Write-Host "Building Whisper..."
cmake -B build
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to configure build with CMake." -ForegroundColor Red
    exit 1
fi

cmake --build build --config Release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to build Whisper." -ForegroundColor Red
    exit 1
fi
Write-Host "Whisper built successfully." -ForegroundColor Green

./build/bin/quantize models/large-v3-turbo.bin models/large-v3-turbo.q5_0.bin q5_0
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed quantize model." -ForegroundColor Red
    exit 1
fi
Write-Host "Setup complete! whisper.cpp is ready to use." -ForegroundColor Green
