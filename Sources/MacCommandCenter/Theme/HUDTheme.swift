import SwiftUI

/// Defines the visual language for the CyberDeck High-Tech Dark HUD.
public enum HUDTheme {
    // MARK: - Core Palette
    public static let background = Color(hex: 0x090D16)
    public static let panelBackground = Color(hex: 0x111726)
    public static let cardBackground = Color(hex: 0x161F33)
    public static let cardElevated = Color(hex: 0x1D2942)
    public static let border = Color(hex: 0x22324F)
    public static let borderSubtle = Color(hex: 0x1A253A)
    
    // MARK: - Neon Accent Accents
    public static let cyan = Color(hex: 0x00F0FF)
    public static let emerald = Color(hex: 0x00E676)
    public static let amber = Color(hex: 0xFFB800)
    public static let crimson = Color(hex: 0xFF3366)
    public static let purple = Color(hex: 0xBF5AF2)
    public static let cobalt = Color(hex: 0x3875FF)
    
    // MARK: - Text
    public static let textPrimary = Color(hex: 0xF0F4FC)
    public static let textSecondary = Color(hex: 0x94A3B8)
    public static let textMuted = Color(hex: 0x64748B)
    public static let textDim = Color(hex: 0x3B4861)
    
    // MARK: - Gradients
    public static let cyanGradient = LinearGradient(
        colors: [cyan, cobalt],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let crimsonGradient = LinearGradient(
        colors: [crimson, Color(hex: 0xFF6B4A)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let emeraldGradient = LinearGradient(
        colors: [emerald, Color(hex: 0x00B0FF)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let amberGradient = LinearGradient(
        colors: [amber, Color(hex: 0xFF8800)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let scanlineGradient = LinearGradient(
        colors: [Color.white.opacity(0.04), Color.clear],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Hex Color Helper
public extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

// MARK: - Custom HUD Modifiers
public struct HUDCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 10
    var borderColor: Color = HUDTheme.border
    var glowColor: Color = HUDTheme.cyan
    var hasGlow: Bool = false
    
    public func body(content: Content) -> some View {
        content
            .background(HUDTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        hasGlow ? glowColor.opacity(0.6) : borderColor,
                        lineWidth: hasGlow ? 1.5 : 1
                    )
                    .shadow(color: hasGlow ? glowColor.opacity(0.3) : .clear, radius: 6, x: 0, y: 0)
            )
    }
}

public struct HUDGlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 8
    
    public func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
    }
}

public extension View {
    func hudCard(cornerRadius: CGFloat = 10, borderColor: Color = HUDTheme.border, glowColor: Color = HUDTheme.cyan, hasGlow: Bool = false) -> some View {
        self.modifier(HUDCardModifier(cornerRadius: cornerRadius, borderColor: borderColor, glowColor: glowColor, hasGlow: hasGlow))
    }
    
    func hudGlow(color: Color = HUDTheme.cyan, radius: CGFloat = 8) -> some View {
        self.modifier(HUDGlowModifier(color: color, radius: radius))
    }
}
