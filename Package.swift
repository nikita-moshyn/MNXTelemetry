// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "MNXTelemetry",
                      platforms: [.iOS(.v16)],
                      products: [
                        // Products define the executables and libraries a package produces, making them visible to other packages.
                        .library(
                            name: "MNXTelemetry",
                            targets: ["MNXTelemetry"]),
                      ],
                      dependencies: [
                        .package(url: "https://github.com/amplitude/Amplitude-Swift.git", from: "1.15.0"),
                        .package(url: "https://github.com/getsentry/sentry-cocoa.git", from: "8.56.2")
                      ],
                      targets: [
                        // Targets are the basic building blocks of a package, defining a module or a test suite.
                        // Targets can depend on other targets in this package and products from dependencies.
                        .target(name: "MNXTelemetry",
                                dependencies: [
                                    .product(name: "AmplitudeSwift", package: "Amplitude-Swift"),
                                    .product(name: "Sentry", package: "sentry-cocoa")
                                ],
                                path: "Sources/MNXTelemetry"),
                        .testTarget(
                            name: "MNXTelemetryTests",
                            dependencies: ["MNXTelemetry"],
                            path: "MNXTelemetryTests"),
                      ],
                      swiftLanguageModes: [.v6]
)
