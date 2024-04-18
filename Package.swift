// swift-tools-version:5.5
import PackageDescription

let package = Package(
 name: "Configuration",
 platforms: [.macOS(.v11), .iOS(.v14)],
 products: [
  .library(name: "Configuration", targets: ["Configuration"])
 ],
 dependencies: [
  .package(url: "https://github.com/acrlc/core.git", from: "0.1.0"),
  .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4"),
  .package(
   url: "https://github.com/acrlc/Chalk.git",
   branch: "add-default-color"
  )
 ],
 targets: [
  .target(
   name: "Configuration",
   dependencies: [
    .product(name: "Extensions", package: "core"),
    .product(name: "Components", package: "core"),
    .product(name: "Logging", package: "swift-log"),
    "Chalk"
   ],
   path: "Sources"
  ),
  .testTarget(name: "ConfigurationTests", dependencies: ["Configuration"])
 ]
)
