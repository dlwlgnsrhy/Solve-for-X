---
# =========================================================================
#   OPEN-DESIGN SYSTEM CONTRACT (DESIGN.md)
#   Project: SafeSpace Privacy App (com.safespace.privacy)
#   Author: Cloud-Native App Factory Design Team (Friendly & Soft Design)
# =========================================================================
design_system:
  name: "SafeSpace Soft Pastel Friendly Privacy"
  version: "1.3.0"
  tokens:
    colors:
      primary:
        hex: "#a78bfa"
        intent: "Soft pastel lavender representing safety, calmness, and encrypted protection"
      secondary:
        hex: "#f472b6"
        intent: "Warm pastel friendly pink for reassuring alerts and cozy highlights"
      background:
        hex: "#f9fafb"
        intent: "Pure soft warm off-white, offering peace of mind and zero eye strain"
      card:
        hex: "#ffffff"
        intent: "Pure white cards with dynamic soft blurred drop-shadows (elevation 2)"
    typography:
      primary_font: "Outfit"
      scale:
        h1: "2.6rem"
        h2: "1.6rem"
        body: "0.95rem"
    spacing:
      padding_card: "20.0"
      border_radius: "24.0" # Extremely soft, organic squircle rounded corners
    layout:
      enable_chat: true
      enable_profile: true
      enable_settings: true
      hero:
        title: "Your Safe Haven"
        subtitle: "A beautifully soft, highly secure environment protecting your private thoughts and secure data."
      grid_items:
        - title: "Encrypted Vault"
          description: "Zero-knowledge hardware lockbox protecting your passwords and credentials."
          icon: "security"
        - title: "Mindful Journal"
          description: "A private safe diary to log your daily emotional highlights with zero cloud leakage."
          icon: "favorite"
        - title: "Sentinel Guard"
          description: "Real-time biometric threat logs capturing lock attempts."
          icon: "shield"
---

# 🌸 SafeSpace Soft Pastel Friendly Privacy Design System

This design contract specifies the typography, warm aesthetics, and modular features for the **SafeSpace Privacy App**, satisfying the `nexu-io/open-design` specification. The synthesis engine (specifically **Gemma 4 31B Instruct**) must read and enforce this brand rationale natively.

## 1. Aesthetic Rationale: Warm, Reassuring, and Safe
Unlike industrial or cold corporate security apps that invoke anxiety, **SafeSpace** is built to feel calm, organic, and friendly. We leverage soft pastel lavenders (`#a78bfa`) and cozy warm white drops to reassure users that their data is inside a peaceful sanctuary.

*   **Primary Active Elements (`#a78bfa`):** Soft lavender evokes trust, inner peace, and premium encryption quality. Used for biometric prompts, locks, and nav highlights.
*   **Secondary Elements (`#f472b6`):** Friendly pink offers a warm, non-threatening color for highlights and gentle badges.
*   **Soft Rounded Corners:** The border-radius is set at a generous `24.0` pixels to create smooth organic squircle containers that feel satisfying and comforting to touch.

## 2. Component Guidelines & Tokens
The coding agent must inject the corresponding hex codes, padding, and layout booleans dynamically into the Flutter codebase templates.

*   **Typography:** The font `Outfit` must be active, rendering in high contrast over white cards against the soft warm backdrop.
*   **Encrypted Modules:** Hardware Vault, Mindful Journal, and Sentinel logs must be fully mapped.
