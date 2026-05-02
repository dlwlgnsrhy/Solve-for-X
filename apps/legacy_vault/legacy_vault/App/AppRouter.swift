import Foundation
import SwiftUI

// MARK: - Navigation Paths

enum SoulMiningDestination: Hashable {
  case recording
  case player(id: String)
  case aiContext(id: String)
  case summary(id: String)
}

enum GuardianDestination: Hashable {
  case deadManSwitchSetup
  case heirManager
  case backupStatus
  case vaultDecryption
}

enum LegacyAgentDestination: Hashable {
  case personaConfig
  case conversationThread
}

enum ValueMappingDestination: Hashable {
  case valueMap
  case keywordCloud
  case timelineDetail
}

// MARK: - App Router

final class AppRouter: ObservableObject {
  @Published var homePath = NavigationPath()
  @Published var soulMiningPath = NavigationPath()
  @Published var guardianPath = NavigationPath()
  @Published var legacyAgentPath = NavigationPath()
  @Published var valueMappingPath = NavigationPath()

  func clearAll() {
    homePath = NavigationPath()
    soulMiningPath = NavigationPath()
    guardianPath = NavigationPath()
    legacyAgentPath = NavigationPath()
    valueMappingPath = NavigationPath()
  }
}
