// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PanchangApp",
    platforms: [
        .macOS(.v14) // SwiftUI needs newer macOS versions
    ],
    products: [
        .executable(
            name: "PanchangApp",
            targets: ["PanchangApp"]),
    ],
    targets: [
        // Target for the C header and static library wrapper
        .target(
            name: "panchang_engine",
            path: "Sources/panchang_engine",
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedLibrary("panchang_engine_universal"),
                .unsafeFlags(["-L", "Sources/panchang_engine"])
            ]
        ),
        // Main executable target
        .executableTarget(
            name: "PanchangApp",
            dependencies: ["panchang_engine"],
            path: "Sources/PanchangApp"
        ),
    ]
)
