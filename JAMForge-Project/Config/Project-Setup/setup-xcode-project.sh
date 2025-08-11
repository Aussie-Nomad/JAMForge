#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up JAMForge development environment...${NC}"

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Homebrew is not installed. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install dependencies
echo -e "${YELLOW}Installing required tools...${NC}"
brew install xcodegen swiftlint

# Check if XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    echo -e "${RED}Failed to install XcodeGen${NC}"
    exit 1
fi

# Generate Xcode project
echo -e "${YELLOW}Generating Xcode project...${NC}"
xcodegen generate

# Create Info.plist if it doesn't exist
if [ ! -f "JAMForgeProfileCreator/Info.plist" ]; then
    echo -e "${YELLOW}Creating Info.plist...${NC}"
    cat > JAMForgeProfileCreator/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIconFile</key>
    <string></string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 JAMForge. All rights reserved.</string>
</dict>
</plist>
EOF
fi

# Update CI workflow
echo -e "${YELLOW}Updating CI workflow...${NC}"
mkdir -p .github/workflows

cat > .github/workflows/ci.yml << EOF
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: latest-stable
    
    - name: Install XcodeGen
      run: |
        brew install xcodegen
    
    - name: Generate Xcode Project
      run: |
        xcodegen generate
    
    - name: Build
      run: |
        xcodebuild -project JAMForgeProfileCreator.xcodeproj \
                   -scheme JAMForgeProfileCreator \
                   -destination 'platform=macOS' \
                   build
    
    - name: Test
      run: |
        xcodebuild -project JAMForgeProfileCreator.xcodeproj \
                   -scheme JAMForgeProfileCreator \
                   -destination 'platform=macOS' \
                   test
EOF

echo -e "${GREEN}Setup complete! Opening Xcode project...${NC}"
open JAMForgeProfileCreator.xcodeproj
