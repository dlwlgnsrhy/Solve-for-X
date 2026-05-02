import SwiftUI

@main
struct LegacyVaultApp: App {
  @StateObject private var appLifecycle = AppLifecycleService.shared

  var body: some Scene {
    WindowGroup {
      NavigationStack(path: $appLifecycle.navigationPath) {
        Group {
          if appLifecycle.isFirstLaunch {
            OnboardingFlowView()
          } else {
            HomeDashboardView()
          }
        }
        .onAppear {
          Task { await appLifecycle.bootstrap() }
        }
      }
    }
  }
}
