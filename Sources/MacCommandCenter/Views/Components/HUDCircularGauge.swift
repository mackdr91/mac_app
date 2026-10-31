import SwiftUI

public struct HUDCircularGauge: View {
    public var value: Double // 0.0 to 100.0
    public var title: String
    public var subtitle: String?
    public var accentColor: Color = HUDTheme.cyan
    public var gradient: LinearGradient = HUDTheme.cyanGradient
    public var size: CGFloat = 120
    public var lineWidth: CGFloat = 10
    
    public init(
        value: Double,
        title: String,
        subtitle: String? = nil,
        accentColor: Color = HUDTheme.cyan,
        gradient: LinearGradient = HUDTheme.cyanGradient,
        size: CGFloat = 120,
        lineWidth: CGFloat = 10
    ) {
        self.value = value
        self.title = title
        self.subtitle = subtitle
        self.accentColor = accentColor
        self.gradient = gradient
        self.size = size
        self.lineWidth = lineWidth
    }
    
    private var normalizedProgress: Double {
        min(max(value / 100.0, 0.0), 1.0)
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(HUDTheme.borderSubtle, lineWidth: lineWidth)
                    .frame(width: size, height: size)
                
                // Progress Arc
                Circle()
                    .trim(from: 0.0, to: CGFloat(normalizedProgress))
                    .stroke(
                        gradient,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: size, height: size)
                    .shadow(color: accentColor.opacity(0.4), radius: 6, x: 0, y: 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: value)
                
                // Central Readout
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: size * 0.22, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textPrimary)
                    
                    Text("%")
                        .font(.system(size: size * 0.1, weight: .semibold, design: .monospaced))
                        .foregroundColor(accentColor)
                }
            }
            
            // Labels
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(HUDTheme.textSecondary)
                .tracking(1.2)
            
            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(HUDTheme.textMuted)
            }
        }
    }
}
