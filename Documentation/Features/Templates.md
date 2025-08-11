# Profile Template System

## Overview

JAMForge's template system provides a flexible way to create, manage, and share configuration profile templates. Templates can include variables for customization and support both basic and advanced configurations.

## Template Structure

### Basic Template

```swift
struct ProfileTemplate: Codable {
    var name: String
    var description: String
    var identifier: String
    var organization: String
    var payloads: [PayloadTemplate]
    var variables: [TemplateVariable]
    var metadata: TemplateMetadata
}

struct PayloadTemplate: Codable {
    var type: String
    var displayName: String
    var description: String?
    var content: [String: Any]
}

struct TemplateVariable: Codable {
    var name: String
    var description: String
    var type: VariableType
    var defaultValue: Any?
    var required: Bool
    var validation: VariableValidation?
}
```

### Example Template

```json
{
  "name": "Corporate Wi-Fi",
  "description": "Standard corporate Wi-Fi configuration",
  "identifier": "com.organization.wifi",
  "organization": "{{organization}}",
  "payloads": [
    {
      "type": "com.apple.wifi.managed",
      "displayName": "Wi-Fi Settings",
      "content": {
        "SSID_STR": "{{wifi_ssid}}",
        "EncryptionType": "WPA2",
        "AutoJoin": true,
        "ProxyType": "None"
      }
    }
  ],
  "variables": [
    {
      "name": "wifi_ssid",
      "description": "Wi-Fi network name",
      "type": "string",
      "required": true
    },
    {
      "name": "organization",
      "description": "Organization name",
      "type": "string",
      "defaultValue": "My Company"
    }
  ]
}
```

## Using Templates

### Loading Templates

```swift
// Load built-in template
let template = try templateManager.loadTemplate("corporate-wifi")

// Load custom template
let template = try templateManager.loadTemplate(from: url)
```

### Customizing Templates

```swift
// Set variable values
template.setVariable("wifi_ssid", value: "Corporate-5G")
template.setVariable("organization", value: "ACME Inc")

// Generate profile
let profile = try template.generateProfile()
```

### Creating Templates

```swift
// Create new template
let template = ProfileTemplate(
    name: "Security Baseline",
    description: "Standard security settings",
    identifier: "com.organization.security",
    organization: "{{organization}}"
)

// Add payloads
template.addPayload(restrictionsPayload)
template.addPayload(passwordPolicyPayload)

// Save template
try templateManager.saveTemplate(template, as: "security-baseline")
```

## Template Categories

### 1. Security Templates

- Password policies
- Application restrictions
- FileVault configuration
- Firewall settings

### 2. Network Templates

- Wi-Fi configurations
- VPN settings
- Proxy configurations
- Network restrictions

### 3. Application Templates

- App settings
- Privacy permissions
- Security & privacy
- Notification settings

### 4. Device Management

- Login window
- Energy saver
- Time machine
- Software updates

## Variables and Customization

### Variable Types

```swift
enum VariableType {
    case string
    case number
    case boolean
    case select([String])
    case multiSelect([String])
    case date
    case dictionary([String: Any])
}
```

### Validation Rules

```swift
struct VariableValidation {
    var regex: String?
    var minimum: Double?
    var maximum: Double?
    var allowedValues: [Any]?
    var customValidation: ((Any) -> Bool)?
}
```

### Example Usage

```swift
// Template with validation
let template = ProfileTemplate(...)
template.addVariable(
    name: "password_length",
    type: .number,
    validation: VariableValidation(
        minimum: 8,
        maximum: 32
    )
)
```

## Best Practices

### Template Design

1. **Modularity**
   - Break down complex configurations
   - Use shared components
   - Keep templates focused

2. **Variables**
   - Provide clear descriptions
   - Set sensible defaults
   - Include validation rules

3. **Documentation**
   - Document all variables
   - Include usage examples
   - Explain dependencies

### Security

1. **Sensitive Data**
   - Never hardcode credentials
   - Use secure variables
   - Validate input data

2. **Validation**
   - Check variable types
   - Validate ranges
   - Verify requirements

### Sharing

1. **Export Format**
   - Use standard JSON
   - Include metadata
   - Version templates

2. **Distribution**
   - Sign templates
   - Include checksums
   - Document changes

## Template Repository

### Structure

```
templates/
├── security/
│   ├── baseline.json
│   └── compliance.json
├── network/
│   ├── wifi.json
│   └── vpn.json
└── applications/
    ├── browsers.json
    └── productivity.json
```

### Metadata

```json
{
  "version": "1.0.0",
  "author": "IT Team",
  "lastModified": "2025-08-11",
  "tags": ["security", "compliance"],
  "requirements": {
    "minOSVersion": "13.0",
    "maxOSVersion": null
  }
}
```

## Testing Templates

### Validation Tests

```swift
// Test template variables
func testTemplateVariables() throws {
    let template = loadTemplate("wifi")
    
    // Required variables
    XCTAssertTrue(template.validate())
    
    // Variable constraints
    template.setVariable("password_length", value: 6)
    XCTAssertFalse(template.validate())
}
```

### Profile Generation

```swift
// Test profile generation
func testProfileGeneration() throws {
    let template = loadTemplate("security")
    let profile = try template.generateProfile()
    
    // Verify structure
    XCTAssertNotNil(profile.payloadContent)
    XCTAssertEqual(profile.payloadType, "Configuration")
}
```
