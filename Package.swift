// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JAMForge",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "JAMForge",
            targets: ["JAMForge"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/CoreOffice/XMLCoder.git", from: "0.17.1"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
    ],
    targets: [
        .executableTarget(
            name: "JAMForge",
            dependencies: [
                "XMLCoder",
                "KeychainAccess",
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "JAMForge"
        ),
        .testTarget(
            name: "JAMForgeTests",
            dependencies: ["JAMForge"],
            path: "Tests/JAMForgeTests"
        ),
    ]
)
