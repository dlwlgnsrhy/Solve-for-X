import Foundation
import CoreData
import AVFoundation
import Speech
import UserNotifications
import UniformTypeIdentifiers
import LocalAuthentication
import SwiftUI
import CloudKit

@MainActor
final class AppLifecycleService: ObservableObject {
    static let shared = AppLifecycleService()
    
    @Published var navigationPath = NavigationPath()
    @Published var isFirstLaunch: Bool = true
    @Published var isBootstrapReady: Bool = false
    @Published var appState: AppState = .inactive
    
    private var encryptionService = EncryptionService()
    private var sttService = STTService()
    private var notificationHandler = NotificationHandler()
    
    private let key = KeychainHelper.shared
    
    enum AppState: String {
        case inactive
        case active
        case background
    }
    
    public init() {
        self.isFirstLaunch = key.isFirstLaunch
    }
    
    func bootstrap() async {
        // Request STT permission silently
        await sttService.requestPermission()
        
        // Setup notification handler
        await notificationHandler.requestNotificationPermission()
        
        // Check if encryption key exists
        if let _ = try? encryptionService.loadEncryptionKey() {
            isBootstrapReady = true
        } else {
            // No encryption key → onboarding is required
            isBootstrapReady = true
        }
    }
    
    func completeOnboarding(passphrase: String) throws {
        try encryptionService.saveEncryptionKey(passphrase: passphrase)
        key.markFirstLaunchComplete()
        isFirstLaunch = false
    }
    
    func markFirstLaunchComplete() {
        key.markFirstLaunchComplete()
        isFirstLaunch = false
    }
    
    func applicationWillEnterForeground() {
        appState = .active
    }
    
    func applicationDidEnterBackground() {
        appState = .background
    }
}
