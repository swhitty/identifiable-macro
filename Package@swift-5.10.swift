// swift-tools-version:5.10

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "identifiable-macro",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(
            name: "IdentifiableMacro",
            targets: ["IdentifiableMacro"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", "510.0.0"..<"602.0.0"),
    ],
    targets: [
        .target(
            name: "IdentifiableMacro",
            dependencies: ["MacroPlugin"],
            path: "Sources",
            swiftSettings: .upcomingFeatures
        ),
        .macro(
            name: "MacroPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Plugin",
            swiftSettings: .upcomingFeatures
        ),
        .testTarget(
            name: "IdentifiableMacroTests",
            dependencies: ["IdentifiableMacro", "MacroPlugin"],
            path: "Tests",
            swiftSettings: .upcomingFeatures
        )
    ]
)

extension Array where Element == SwiftSetting {

    static var upcomingFeatures: [SwiftSetting] {
        [
            .enableUpcomingFeature("ExistentialAny"),
            .enableExperimentalFeature("StrictConcurrency")
        ]
    }
}
