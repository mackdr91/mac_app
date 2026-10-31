import SwiftUI

public struct HUDMetricCard<Content: View>: View {
    public var title: String
    public var iconName: String
    public var accentColor: Color = HUDTheme.cyan
    public var hasGlow: Bool = false
    public var content: () -> Content
    
    public init(
        title: String,
        iconName: String,
        accentColor: Color = HUDTheme.cyan,
        hasGlow: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.iconName = iconName
        self.accentColor = accentColor
        self.hasGlow = hasGlow
        self.content = content
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(accentColor)
                    
                    Text(title.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textSecondary)
                        .tracking(1.1)
                }
                
                Spacer()
                
                // Pulsing Status Dot
                Circle()
                    .fill(accentColor)
                    .frame(width: 6, height: 6)
                    .shadow(color: accentColor, radius: 4)
            }
            
            Divider()
                .background(HUDTheme.borderSubtle)
            
            // Custom Card Body
            content()
        }
        .padding(14)
        .hudCard(cornerRadius: 12, borderColor: HUDTheme.border, glowColor: accentColor, hasGlow: hasGlow)
    }
}
