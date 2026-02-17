// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoreMarkdownPreview",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CoreMarkdownPreview",
            targets: ["CoreMarkdownPreview"]
        )
    ],
    targets: [
        .target(
            name: "CoreMarkdownPreview"
        ),
        .testTarget(
            name: "CoreMarkdownPreviewTests",
            dependencies: ["CoreMarkdownPreview"]
        )
    ]
)
