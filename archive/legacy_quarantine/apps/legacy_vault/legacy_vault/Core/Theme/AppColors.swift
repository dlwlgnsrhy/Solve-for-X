import SwiftUI

// MARK: - Vault Button Style

struct VaultButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.white)
          .padding(.vertical, 14)
          .frame(maxWidth: .infinity)
           .background(AppColors.accent)
          .cornerRadius(12)
          .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Vault Text Field Style

struct VaultTextFieldStyle: TextFieldStyle {
    typealias _Body = _BodyContent

    struct _BodyContent: View {
        var input: TextField<_TextFieldStyleLabel>
        var body: some View {
            input
                .padding(14)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Color(.white))
        }
    }

    func _body(configuration: TextField<Self._Label>) -> Self._Body {
        _BodyContent(input: configuration)
    }
}

// MARK: - AppColors

/// Color palette container for the app.

struct AppColors {
    // Background Colors
    static let background = Color(red: 0.039, green: 0.039, blue: 0.059)
    static let surface = Color(red: 0.063, green: 0.063, blue: 0.078)
    static let surfaceVariant = Color(red: 0.09, green: 0.09, blue: 0.11)

    // Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.6, green: 0.6, blue: 0.65)
    static let textTertiary = Color(red: 0.4, green: 0.4, blue: 0.45)

    // Neon Accent Colors
    static let neonGreen = Color(red: 0.0, green: 1.0, blue: 0.533)
    static let neonPink = Color(red: 1.0, green: 0.2, blue: 0.65)
    static let neonCyan = Color(red: 0.0, green: 0.69, blue: 1.0)
    static let accent = neonGreen

    // Status Colors
    static let warning = Color(red: 1.0, green: 0.64, blue: 0.0)
    static let danger = Color(red: 1.0, green: 0.2, blue: 0.2)
}
