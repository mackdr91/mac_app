import SwiftUI

public struct HUDStatusPill: View {
    public var text: String
    public var color: Color = HUDTheme.emerald
    public var isPulsing: Bool = false
    
    public init(text: String, color: Color = HUDTheme.emerald, isPulsing: Bool = false) {
        self.text = text
        self.color = color
        self.isPulsing = isPulsing
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color, radius: isPulsing ? 4 : 2)
            
            Text(text.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .tracking(0.8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.4), lineWidth: 1)
        )
    }
}
