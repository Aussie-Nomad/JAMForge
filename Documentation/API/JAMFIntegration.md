# JAMF Integration Guide

## Overview

JAMForge integrates with JAMF Pro using both the Classic API and modern JAMF Pro API to provide comprehensive profile management capabilities.

## Authentication

### Bearer Token Authentication

```swift
// Initialize JAMF service with your instance URL
let jamfService = JAMFAPIService(baseURL: "https://your-instance.jamfcloud.com")

// Authenticate and get bearer token
try await jamfService.authenticate(username: "admin", password: "password")
```

### Token Management

- Tokens are automatically refreshed
- Stored securely in Keychain
- Validates on each API call

## Profile Operations

### Uploading Profiles

```swift
// Create and configure profile
let profile = ConfigurationProfile(...)

// Upload to JAMF
let profileId = try await jamfService.uploadProfile(profile)
```

### Managing Scope

```swift
// Define scope
let scope = ProfileScope(
    computers: ["All Computers"],
    computerGroups: ["Development"],
    buildings: ["HQ"],
    departments: ["IT"]
)

// Apply scope
try await jamfService.updateScope(scope, for: profileId)
```

### Profile Status

```swift
// Get deployment status
let status = try await jamfService.getProfileStatus(profileId)

// Monitor deployment
for try await update in jamfService.monitorDeployment(profileId) {
    print("Progress: \(update.progress)%")
}
```

## Security Considerations

1. **API Credentials**
   - Use service account with minimal permissions
   - Rotate credentials regularly
   - Store securely in Keychain

2. **Network Security**
   - Validate SSL certificates
   - Use certificate pinning
   - Implement request timeouts

3. **Data Protection**
   - Encrypt sensitive data
   - Clear memory after use
   - Validate all responses

## Best Practices

1. **Rate Limiting**
   - Implement exponential backoff
   - Batch operations when possible
   - Cache frequently used data

2. **Error Handling**
   - Provide meaningful error messages
   - Implement retry logic
   - Log all API interactions

3. **Deployment**
   - Test in staging environment
   - Validate profiles before upload
   - Monitor deployment status

## Example Workflows

### Full Profile Deployment

```swift
// Create profile
let profile = try profileService.createProfile(...)

// Add payloads
try profile.addPayload(wifiPayload)
try profile.addPayload(vpnPayload)

// Sign profile
let signedData = try securityManager.signProfile(profile)

// Upload to JAMF
let profileId = try await jamfService.uploadProfile(signedData)

// Configure scope
let scope = ProfileScope(computers: ["All Computers"])
try await jamfService.updateScope(scope, for: profileId)

// Monitor deployment
for try await status in jamfService.monitorDeployment(profileId) {
    updateProgress(status.progress)
}
```

### Profile Management

```swift
// List all profiles
let profiles = try await jamfService.getProfiles()

// Update existing profile
try await jamfService.updateProfile(id: profileId, profile: updatedProfile)

// Remove profile
try await jamfService.deleteProfile(id: profileId)
```

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify credentials
   - Check URL format
   - Confirm API permissions

2. **Upload Errors**
   - Validate profile format
   - Check file size limits
   - Verify signing certificate

3. **Scope Issues**
   - Confirm group existence
   - Check naming consistency
   - Verify permissions

### Debugging

```swift
// Enable debug logging
JAMFAPIService.setLogLevel(.debug)

// Log all requests
jamfService.enableRequestLogging()

// Export debug information
let debugInfo = try jamfService.generateDebugReport()
```

## API Reference

### Endpoints Used

1. **Authentication**
   - POST /api/v1/auth/token
   - POST /api/v1/auth/keep-alive

2. **Profile Management**
   - GET /api/v1/osxconfigurationprofiles
   - POST /api/v1/osxconfigurationprofiles
   - PUT /api/v1/osxconfigurationprofiles/{id}
   - DELETE /api/v1/osxconfigurationprofiles/{id}

3. **Scope Management**
   - GET /api/v1/osxconfigurationprofiles/{id}/scope
   - PUT /api/v1/osxconfigurationprofiles/{id}/scope
