import SwiftUI

public struct HUDProgressBar: View {
    public var label: String
    public var value: Double // 0.0 to 100.0
    public var detailText: String?
    public var accentColor: Color = HUDTheme.cyan
    public var height: CGFloat = 8
    public var showPercentage: Bool = true
    
    public init(
        label: String,
        value: Double,
        detailText: String? = nil,
        accentColor: Color = HUDTheme.cyan,
        height: CGFloat = 8,
        showPercentage: Bool = true
    ) {
        self.label = label
        self.value = value
        self.detailText = detailText
        self.accentColor = accentColor
        self.height = height
        self.showPercentage = showPercentage
    }
    
    private var normalizedProgress: Double {
        min(max(value / 100.0, 0.0), 1.0)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(HUDTheme.textSecondary)
                
                Spacer()
                
                if let detail = detailText {
                    Text(detail)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textPrimary)
                } else if showPercentage {
                    Text(String(format: "%.1f%%", value))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(accentColor)
                }
            }
            
            // Progress Track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(HUDTheme.borderSubtle)
                        .frame(height: height)
                    
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.8), accentColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * CGFloat(normalizedProgress), 0), height: height)
                        .shadow(color: accentColor.opacity(0.5), radius: 3)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
                }
            }
            .frame(height: height)
        }
    }
}
