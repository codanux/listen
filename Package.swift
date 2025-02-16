// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CodanuxListen",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "CodanuxListen",
            targets: ["ListenPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "ListenPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/ListenPlugin"),
        .testTarget(
            name: "ListenPluginTests",
            dependencies: ["ListenPlugin"],
            path: "ios/Tests/ListenPluginTests")
    ]
)