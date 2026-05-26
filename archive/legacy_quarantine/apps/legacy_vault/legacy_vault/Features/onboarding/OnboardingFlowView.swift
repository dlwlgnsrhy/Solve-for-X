import SwiftUI
import CoreData

@MainActor

struct OnboardingFlowView: View {
    @StateObject private var notificationHandler = NotificationHandler()
    
    @State private var step: Int = 0
    @State private var passphrase: String = ""
    @State private var confirmPassphrase: String = ""
    @State private var showPassphraseError: Bool = false
    @State private var isCreatingKey: Bool = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                stepView
                ProgressView(value: Double(step), total: 3.0)
                  .padding(.vertical, 24)
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    var stepView: some View {
        switch step {
        case 0: welcomeStep
        case 1: passphraseStep
        case 2: completeStep
        default: welcomeStep
        }
    }
    
    // MARK: - Step 0: Welcome
    
    var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "shield.checkered")
              .font(.system(size: 64))
              .foregroundStyle(AppColors.accent)
            
            Text("Legacy Vault")
              .font(.system(size: 32, weight: .bold))
              .foregroundStyle(.white)
            
            Text("당신의 삶과 가치를\n영원히 간직하세요")
              .font(.system(size: 18))
              .foregroundStyle(.white.opacity(0.8))
              .multilineTextAlignment(.center)
              .lineSpacing(4)
            
            VStack(spacing: 16) {
                featureRow("mic.fill", "음성 녹음", "Soul-Mining")
                featureRow("lock.shield.fill", "보안 저장소", "Guardian Protocol")
                featureRow("sparkles", "내 AI 유산", "Legacy Agent")
                featureRow("leaf.fill", "가치 매핑", "Value Mapping")
            }
            
            Spacer()
            
            Button("시작하기") {
                withAnimation { step = 1 }
            }
            .buttonStyle(VaultButtonStyle())
            .padding(.horizontal, 32)
        }
        .padding()
    }
    
    // MARK: - Step 1: Passphrase
    
    var passphraseStep: some View {
        VStack(spacing: 20) {
            Text("보안 키 생성")
              .font(.system(size: 24, weight: .bold))
              .foregroundStyle(.white)
            
            Text("모든 데이터는 디바이스 내에서\nAES-256-GCM으로 암호화됩니다")
              .font(.system(size: 15))
              .foregroundStyle(.white.opacity(0.7))
              .multilineTextAlignment(.center)
              .lineSpacing(4)
            
            VStack(spacing: 12) {
                SecureField("비밀번호 입력", text: $passphrase)
                  .textFieldStyle(VaultTextFieldStyle())
                
                SecureField("비밀번호 확인", text: $confirmPassphrase)
                  .textFieldStyle(VaultTextFieldStyle())
                
                if showPassphraseError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text("비밀번호가 일치하지 않습니다")
                      }
                      .font(.system(size: 13))
                      .foregroundStyle(.red)
                }
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(isCreatingKey ? "키 생성 중..." : "암호화 키 생성") {
                    createKey()
                }
                .buttonStyle(VaultButtonStyle())
                .disabled(isCreatingKey)
                .padding(.horizontal, 32)
            }
        }
        .padding()
    }
    
    // MARK: - Step 2: Complete
    
    var completeStep: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                  .font(.system(size: 64))
                  .foregroundStyle(AppColors.accent)
                
                Text("설정 완료!")
                  .font(.system(size: 28, weight: .bold))
                  .foregroundStyle(.white)
                
                Text("모든 설정이 완료되었습니다.\n이제 Legacy Vault를 사용할 수 있습니다.")
                  .font(.system(size: 16))
                  .foregroundStyle(.white.opacity(0.7))
                  .multilineTextAlignment(.center)
                  .lineSpacing(4)
                
                Spacer()
                
                Button("홈으로 이동") {
                    completeOnboarding()
                }
                .buttonStyle(VaultButtonStyle())
                .padding(.horizontal, 32)
            }
            .padding()
        }
    }
    
    // MARK: - Actions
    
    private func createKey() {
        guard !passphrase.isEmpty, !confirmPassphrase.isEmpty else { return }
        guard passphrase == confirmPassphrase else {
            showPassphraseError = true
            return
        }
        guard passphrase.count >= 4 else { return }
        
        showPassphraseError = false
        isCreatingKey = true
        
        Task {
            do {
                try AppLifecycleService.shared.completeOnboarding(passphrase: passphrase)
                withAnimation { step = 2 }
            } catch {
                isCreatingKey = false
            }
        }
    }
    
    private func completeOnboarding() {
        AppLifecycleService.shared.markFirstLaunchComplete()
        notificationHandler.scheduleDailyPingReminder()
    }
    
    // MARK: - Subviews
    
    private func featureRow(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
              .font(.system(size: 24))
              .foregroundStyle(AppColors.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                  .font(.system(size: 14, weight: .medium))
                  .foregroundStyle(.white)
                Text(subtitle)
                  .font(.system(size: 12))
                  .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Previews

// Preview disabled for compilation compatibility
