#!/bin/bash
# RikkaHub Build Script for Debian/Ubuntu
# This script installs all necessary dependencies and builds the APK

set -e

echo "=========================================="
echo "RikkaHub Build Script for Debian/Ubuntu"
echo "=========================================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please run this script as a non-root user (with sudo privileges)"
    exit 1
fi

# Update system
echo "[1/7] Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install basic dependencies
echo "[2/7] Installing basic dependencies..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    openjdk-17-jdk \
    apt-transport-https

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> ~/.bashrc

# Install Android SDK
echo "[3/7] Installing Android SDK..."
ANDROID_SDK_ROOT=$HOME/Android/Sdk
mkdir -p $ANDROID_SDK_ROOT
mkdir -p $ANDROID_SDK_ROOT/cmdline-tools

# Download command-line tools
CMDLINE_TOOLS_VERSION=11076708
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip"

cd /tmp
wget -q --show-progress "$CMDLINE_TOOLS_URL" -O cmdline-tools.zip
unzip -q cmdline-tools.zip
mv cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest
rm cmdline-tools.zip

# Set ANDROID_SDK_ROOT
export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT
echo "export ANDROID_SDK_ROOT=$HOME/Android/Sdk" >> ~/.bashrc
export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools
echo "export PATH=\$PATH:\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:\$ANDROID_SDK_ROOT/platform-tools" >> ~/.bashrc

# Accept licenses and install required components
echo "[4/7] Installing Android SDK components..."
yes | sdkmanager --licenses
sdkmanager --update
sdkmanager "platforms;android-36" "build-tools;36.0.0" "platform-tools"

# Clone repository
echo "[5/7] Cloning RikkaHub repository..."
cd $HOME
if [ -d "rikkahub" ]; then
    echo "Directory exists, pulling latest changes..."
    cd rikkahub
    git pull
else
    git clone https://github.com/zixiaohao/rikkahub.git
    cd rikkahub
fi

# Make gradlew executable
chmod +x gradlew

# Build the APK
echo "[6/7] Building APK..."
./gradlew assembleRelease --no-daemon

# Check build result
echo "[7/7] Checking build result..."
APK_PATH="app/build/outputs/apk/release/app-release.apk"
if [ -f "$APK_PATH" ]; then
    echo ""
    echo "=========================================="
    echo "Build successful!"
    echo "APK location: $(pwd)/$APK_PATH"
    echo "=========================================="
    
    # Copy APK to home directory with version name
    VERSION_NAME=$(grep "versionName" app/build.gradle.kts | head -1 | sed 's/.*versionName = "\([^"]*\)".*/\1/')
    cp "$APK_PATH" "$HOME/rikkahub-${VERSION_NAME}.apk"
    echo "APK also copied to: $HOME/rikkahub-${VERSION_NAME}.apk"
else
    echo ""
    echo "Build failed! APK not found."
    exit 1
fi

echo ""
echo "Done!"