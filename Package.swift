// swift-tools-version:5.1
import PackageDescription

let package = Package(
 name: "Configuration",
 platforms: [.macOS(.v10_15), .iOS(.v13)],
 products: [
  .library(name: "Configuration", targets: ["Configuration"])
 ],
 dependencies: [
  .package(url: "https://github.com/acrlc/core.git", from: "0.1.0"),
  .package(url: "https://github.com/mxcl/Chalk.git", from: "0.5.0")
 ],
 targets: [
  .target(
   name: "Configuration",
   dependencies: [
    .product(name: "Extensions", package: "core"),
    .product(name: "Components", package: "core"),
    "Chalk"
   ],
   path: "Sources"
  ),
  .testTarget(name: "ConfigurationTests", dependencies: ["Configuration"])
 ]
)
