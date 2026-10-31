import SwiftUI

public struct HUDSparkline: View {
    public var data: [Double]
    public var accentColor: Color = HUDTheme.cyan
    public var gradient: LinearGradient = HUDTheme.cyanGradient
    public var minVal: Double?
    public var maxVal: Double?
    public var height: CGFloat = 45
    public var showGridLines: Bool = true
    
    public init(
        data: [Double],
        accentColor: Color = HUDTheme.cyan,
        gradient: LinearGradient = HUDTheme.cyanGradient,
        minVal: Double? = nil,
        maxVal: Double? = nil,
        height: CGFloat = 45,
        showGridLines: Bool = true
    ) {
        self.data = data
        self.accentColor = accentColor
        self.gradient = gradient
        self.minVal = minVal
        self.maxVal = maxVal
        self.height = height
        self.showGridLines = showGridLines
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let points = calculatePoints(in: geometry.size)
            
            ZStack {
                if showGridLines {
                    // Subtle horizontal grid guides
                    VStack {
                        Divider().background(HUDTheme.borderSubtle.opacity(0.3))
                        Spacer()
                        Divider().background(HUDTheme.borderSubtle.opacity(0.3))
                        Spacer()
                        Divider().background(HUDTheme.borderSubtle.opacity(0.3))
                    }
                }
                
                if points.count > 1 {
                    // Filled Area under Curve
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: geometry.size.height))
                        for pt in points {
                            path.addLine(to: pt)
                        }
                        path.addLine(to: CGPoint(x: points.last!.x, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.25), accentColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Line Stroke
                    Path { path in
                        path.move(to: points[0])
                        for pt in points.dropFirst() {
                            path.addLine(to: pt)
                        }
                    }
                    .stroke(
                        gradient,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: accentColor.opacity(0.5), radius: 4, x: 0, y: 0)
                }
            }
        }
        .frame(height: height)
    }
    
    private func calculatePoints(in size: CGSize) -> [CGPoint] {
        guard !data.isEmpty else { return [] }
        
        let calculatedMin = minVal ?? (data.min() ?? 0.0)
        let calculatedMax = maxVal ?? (data.max() ?? 100.0)
        let range = max(calculatedMax - calculatedMin, 1.0)
        
        let stepX = size.width / CGFloat(max(data.count - 1, 1))
        
        return data.enumerated().map { index, val in
            let clampedVal = min(max(val, calculatedMin), calculatedMax)
            let normalizedY = CGFloat((clampedVal - calculatedMin) / range)
            let y = size.height - (normalizedY * size.height)
            let x = CGFloat(index) * stepX
            return CGPoint(x: x, y: y)
        }
    }
}
