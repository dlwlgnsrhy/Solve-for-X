// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "LegacyVault",
  platforms: [.iOS(.v17)],
  products: [
    .executable(name: "LegacyVaultApp", targets: ["LegacyVaultApp"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.0"),
  ],
  targets: [
    .executableTarget(
      name: "LegacyVaultApp",
      dependencies: [
        "KeychainAccess",
      ],
      path: "legacy_vault",
      resources: [
        .process("Resources/Assets.xcassets"),
        .process("Resources/Localization"),
      ]
    ),
  ]
)
