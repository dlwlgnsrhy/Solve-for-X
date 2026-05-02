import Foundation

// MARK: - EncryptionServiceTests
// Unit tests for AES-256-GCM encryption round-trip.

final class EncryptionServiceTests {
    
    private let service = EncryptionService()
    
    func testEncryptDecryptRoundTrip() -> Bool {
        let plaintext = "내 비밀 일기: 아빠의 가치관과 인생 경험"
        let passphrase = "MySecurePassphrase2024!"
        let originalData = Data(plaintext.utf8)
        
        do {
            let encrypted = try service.encrypt(originalData, with: passphrase)
            let decrypted = try service.decrypt(encrypted, with: passphrase)
            let result = String(data: decrypted, encoding: .utf8)
            
            if result == plaintext {
                print("✓ testRoundTrip: PASSED")
                return true
            } else {
                print("✗ testRoundTrip: FAILED (round-trip mismatch)")
                return false
            }
        } catch {
            print("✗ testRoundTrip: FAILED (\(error.localizedDescription))")
            return false
        }
    }
    
    func testDifferentPassphrasesFail() -> Bool {
        let plaintext = "TestData"
        let payload = try? service.encrypt(Data(plaintext.utf8), with: "correct")
        
        do {
            _ = try service.decrypt(payload!, with: "wrong")
            print("✗ testWrongPassphrase: FAILED (should have thrown)")
            return false
        } catch {
            print("✓ testWrongPassphrase: PASSED (correctly rejected)")
            return true
        }
    }
    
    func testEmptyData() -> Bool {
        do {
            let encrypted = try service.encrypt(Data(), with: "key")
            let decrypted = try service.decrypt(encrypted, with: "key")
            if decrypted.count == 0 {
                print("✓ testEmptyData: PASSED")
                return true
            }
        } catch {
            print("✗ testEmptyData: FAILED (\(error))")
            return false
        }
        return false
    }
    
    static func runAllTests() -> (passed: Int, failed: Int) {
        let test = EncryptionServiceTests()
        var passed = 0
        var failed = 0
        
        if test.testEncryptDecryptRoundTrip() { passed += 1 } else { failed += 1 }
        if test.testDifferentPassphrasesFail() { passed += 1 } else { failed += 1 }
        if test.testEmptyData() { passed += 1 } else { failed += 1 }
        
        print("\n═══ EncryptionService Tests ═══")
        print("  Passed: \(passed)/3")
        print("  Failed: \(failed)/3")
        return (passed, failed)
    }
}

// Test runner: run this via: swift apps/legacy_vault/legacy_vault/Tests/Unit/EncryptionServiceTests.swift
