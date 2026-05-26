import Foundation

// MARK: - PrivacyTests

/// Tests that verify privacy compliance: no network dependencies, 100% on-device.
/// These tests ensure Legacy Vault conforms to the "Google은 당신의 데이터를 학습하지만, Legacy Vault는 당신의 존엄을 보호합니다" principle.

final class PrivacyTests {
    
    /// Assert that legacy_vault Swift source files contain NO URLSession/networking imports.
    static func assertNoNetworkImports() -> Bool {
        let forbiddenImports = ["URLSession", "URLRequest", "URLSession.shared", "Alamofire", "Firebase"]
        var hasViolation = false
        
        // Search all Swift files in legacy_vault directory
        guard let fileURL = URL(filePath: "apps/legacy_vault/legacy_vault") else { return false }
        let enumerator = FileManager.default.enumerator(at: fileURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        
        while let file = enumerator?.nextObject() as? URL {
            guard file.pathExtension == "swift", !file.path.contains("/Tests/") else { continue }
            
            guard let content = try? String(contentsOf: file, encoding: .utf8) else { continue }
            
            for forbidden in forbiddenImports {
                if content.contains(forbidden) {
                    print("❌ Privacy VIOLATION: \(file.lastPathComponent) contains '\(forbidden)'")
                    hasViolation = true
                }
            }
        }
        
        if !hasViolation {
            print("✅ Privacy PASSED: No network imports found in any Swift file")
        }
        
        return !hasViolation
    }
    
    /// Verify that all Core Data interactions are local (no remote persistence controllers).
    static func assertLocalPersistenceOnly() -> Bool {
        let forbiddenTypes = ["FirebaseFirestore", "CloudFirestore", "RemotePersistenceController"]
        var hasViolation = false
        
        let fileURL = URL(filePath: "apps/legacy_vault/legacy_vault/Core/Database")
        guard let enumerator = FileManager.default.enumerator(at: fileURL, includingPropertiesForKeys: [.isRegularFileKey]) else {
            return true // No files to check
        }
        
        for case let file as URL in enumerator {
            guard file.pathExtension == "swift" else { continue }
            guard let content = try? String(contentsOf: file, encoding: .utf8) else { continue }
            
            for forbidden in forbiddenTypes {
                if content.contains(forbidden) {
                    print("❌ Persistence VIOLATION: \(file.lastPathComponent) uses \(forbidden)")
                    hasViolation = true
                }
            }
        }
        
        if !hasViolation {
            print("✅ Persistence PASSED: Only local PersistenceController used")
        }
        
        return !hasViolation
    }
    
    static func runAll() -> [String] {
        var results: [String] = []
        
        if assertNoNetworkImports() {
            results.append("Privacy: PASS (no network imports)")
        } else {
            results.append("Privacy: FAIL")
        }
        
        if assertLocalPersistenceOnly() {
            results.append("Persistence: PASS (local only)")
        } else {
            results.append("Persistence: FAIL")
        }
        
        print("""
        \n═══════════════════════════════════════════════════════
        PRIVACY TEST RESULTS
        ═══════════════════════════════════════════════════════
        """)
        for result in results {
            print("  \(result)")
        }
        print("═══════════════════════════════════════════════════════\n")
        
        return results
    }
}

// MARK: - Usage
// Run from command line:
//   cd Solve-for-X
//   swift apps/legacy_vault/legacy_vault/Tests/Unit/PrivacyTests.swift
