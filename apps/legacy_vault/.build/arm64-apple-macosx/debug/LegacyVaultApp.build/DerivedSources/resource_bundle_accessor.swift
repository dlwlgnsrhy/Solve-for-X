import Foundation

extension Foundation.Bundle {
    static let module: Bundle = {
        let mainPath = Bundle.main.bundleURL.appendingPathComponent("LegacyVault_LegacyVaultApp.bundle").path
        let buildPath = "/Users/apple/development/soluni/Solve-for-X/apps/legacy_vault/.build/arm64-apple-macosx/debug/LegacyVault_LegacyVaultApp.bundle"

        let preferredBundle = Bundle(path: mainPath)

        guard let bundle = preferredBundle ?? Bundle(path: buildPath) else {
            // Users can write a function called fatalError themselves, we should be resilient against that.
            Swift.fatalError("could not load resource bundle: from \(mainPath) or \(buildPath)")
        }

        return bundle
    }()
}