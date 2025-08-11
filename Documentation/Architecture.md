# JAMForge Architecture

## Overview

JAMForge is a container application that hosts various tools for JAMF Administrators. It's designed to be modular, allowing for easy addition of new features while maintaining a consistent user experience.

## Core Components

### Container App (JAMForge)
- Main application shell
- Feature management and navigation
- Shared state and services
- Cross-cutting concerns (auth, security, etc.)

### Features
1. Profile Builder (formerly ProfileCreator)
   - Configuration profile creation and management
   - JAMF Pro integration
   - Template system
   - App analysis

2. Device Manager (Future)
   - Device inventory management
   - Policy application
   - Status monitoring

3. App Manager (Future)
   - Application deployment
   - License management
   - Update tracking

## Technical Architecture

### JAMForgeKit (Shared Framework)
- JAMF Pro API client
- Common models and protocols
- Shared utilities
- Cross-platform compatibility layer

### Core Services
- JAMF integration
- Security services
- Analytics and logging
- State management

### UI Architecture
- SwiftUI-based
- Shared components
- Responsive design (macOS/iOS)
- Dark mode support

## Directory Structure
```
JAMForge/
├── JAMForge/               # Main app
│   ├── App/               # App entry and lifecycle
│   ├── Features/         # Feature modules
│   ├── Core/            # Core services
│   ├── UI/             # Shared UI components
│   └── Resources/      # Assets and configs
├── JAMForgeKit/        # Shared framework
├── Tests/             # Test suites
└── Documentation/    # Project documentation
```

## Development Guidelines

### Feature Development
1. Features should be self-contained
2. Use shared services via dependency injection
3. Follow MVVM architecture
4. Include tests and documentation

### Styling
- Use shared UI components
- Follow Apple Human Interface Guidelines
- Support both light and dark modes
- Maintain accessibility

### Testing
- Unit tests for business logic
- Integration tests for JAMF Pro API
- UI tests for critical paths
- Performance testing

## Future Considerations

### Scalability
- Module independence
- Performance optimization
- Resource management

### Cross-Platform
- macOS primary platform
- iOS support for key features
- Shared business logic
- Platform-specific UIs where needed

### Integration
- MDM system support
- Third-party tool integration
- API availability
