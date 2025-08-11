# JAMForge Profile Creator

[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![macOS 13.0+](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://developer.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A modern, open-source macOS configuration profile creator with JAMF Pro integration. Built for system administrators and the MacAdmins community to create, manage, and deploy Apple Configuration Profiles efficiently.

## ✨ Features

### 🎯 Core Functionality
- **Drag & Drop App Integration**: Automatically configure required permissions
- **Dark Mode UI**: Modern macOS-native interface
- **Template System**: Pre-built templates for common configurations
- **Profile Suggestions**: Intelligent recommendations
- **Privacy Settings Catalog**: Detailed permission explanations

### 🔒 Security Features
- **Secure JAMF Integration**: Full API support with encrypted storage
- **Profile Signing**: Digital signing with institutional certificates
- **Debugging Tools**: Validation and testing capabilities
- **Encrypted Storage**: Secure configuration handling

### 📱 Profile Management
- **Complete Payload Support**: All major configuration profile payloads
- **Visual Editor**: Form-based editing with validation
- **Export/Import**: Multiple format support
- **Version Control**: Change tracking and history

## 🚀 Getting Started

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9+
- JAMF Pro 10.25+ (for JAMF integration)

### Development Setup
1. Clone the repository
```bash
git clone https://github.com/Aussie-Nomad/JAMForge.git
cd JAMForge
```
2. Open the Xcode project
```bash
open JAMForgeProfileCreator/JAMForgeProfileCreator.xcodeproj
```

## 📖 Documentation

- [Development Plan](Documentation/DevelopmentPlan.md)
- [API Documentation](Documentation/API.md)
- [Template System](Documentation/Templates.md)
- [JAMF Integration](Documentation/JAMFIntegration.md)

## 🤝 Contributing

We welcome contributions from the MacAdmins community! Please check our development plan and contributing guidelines.

### Development Process
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Commit your changes
6. Push to the branch
7. Open a Pull Request

## 📋 Project Roadmap

### Phase 1: Core Profile Engine
- [ ] Basic profile creation
- [ ] Essential payload types
- [ ] Profile validation
- [ ] XML generation

### Phase 2: User Interface
- [ ] Dark mode interface
- [ ] Profile editor views
- [ ] Template system
- [ ] Drag & drop support

### Phase 3: JAMF Integration
- [ ] API authentication
- [ ] Profile deployment
- [ ] Scope management
- [ ] Status monitoring

### Phase 4: Security & Distribution
- [ ] Code signing
- [ ] Profile encryption
- [ ] Credential management
- [ ] Distribution preparation

### Phase 5: Testing & Documentation
- [ ] Unit tests
- [ ] Integration tests
- [ ] User documentation
- [ ] API documentation

## 🔧 Built With

- [Swift](https://swift.org/) - Programming language
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - UI framework
- [CryptoKit](https://developer.apple.com/documentation/cryptokit) - Cryptography
- [XMLCoder](https://github.com/CoreOffice/XMLCoder) - XML handling

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- MacAdmins community
- Apple's Configuration Profile documentation
- JAMF Pro API documentation