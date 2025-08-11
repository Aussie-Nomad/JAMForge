#!/bin/bash

# setup-project.sh - Initialize JAMForge project structure
echo "🔨 Setting up JAMForge project..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "README.md" ]; then
    print_error "Please run this script from the JAMForge project root directory"
    exit 1
fi

# Create directory structure
print_status "Creating project directory structure..."

# Core directories
directories=(
    "JAMForge/App"
    "JAMForge/Views/Profile"
    "JAMForge/Views/Templates"
    "JAMForge/Views/JAMF"
    "JAMForge/Views/Components"
    "JAMForge/Views/Settings"
    "JAMForge/Models/Payloads"
    "JAMForge/Models/Templates"
    "JAMForge/Models/JAMF"
    "JAMForge/Models/Privacy"
    "JAMForge/Services"
    "JAMForge/Utilities/Extensions"
    "JAMForge/Resources/Assets.xcassets"
    "JAMForge/Resources/Templates"
    "Tests/JAMForgeTests"
    "Tests/JAMForgeUITests"
    "Documentation/images"
    "Scripts"
    ".vscode"
    ".github/workflows"
    ".github/ISSUE_TEMPLATE"
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
    print_status "Created directory: $dir"
done

print_success "Directory structure created successfully"

# Initialize Git repository if not already initialized
if [ ! -d ".git" ]; then
    print_status "Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit: Project structure setup"
    print_success "Git repository initialized"
fi

# Set file permissions
chmod +x Scripts/*.sh
print_status "Set executable permissions for scripts"

print_success "Project setup complete! 🎉"
echo "Next steps:"
echo "1. Open JAMForge.xcodeproj in Xcode"
echo "2. Review and update the README.md"
echo "3. Begin development!"
