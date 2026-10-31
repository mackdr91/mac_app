import SwiftUI

public enum NavigationSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case telemetry = "Hardware"
    case processes = "Processes"
    case commands = "Command Deck"
    case network = "Network & Ports"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .telemetry: return "cpu"
        case .processes: return "list.bullet.rectangle.portrait"
        case .commands: return "terminal"
        case .network: return "antenna.radiowaves.left.and.right"
        }
    }
}

public struct SidebarView: View {
    @Binding var selectedSection: NavigationSection
    @Bindable var monitor = SystemMonitorService.shared
    
    public init(selectedSection: Binding<NavigationSection>) {
        self._selectedSection = selectedSection
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Branding
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(HUDTheme.cyan.opacity(0.15))
                        .frame(width: 34, height: 34)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(HUDTheme.cyan, lineWidth: 1.5)
                        )
                        .shadow(color: HUDTheme.cyan.opacity(0.5), radius: 6)
                    
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(HUDTheme.cyan)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("CYBERDECK")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(HUDTheme.textPrimary)
                        .tracking(1.5)
                    
                    Text("COMMAND CENTER")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.cyan)
                        .tracking(1.0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 24)
            
            Divider().background(HUDTheme.borderSubtle)
            
            // Navigation Links
            VStack(spacing: 4) {
                ForEach(NavigationSection.allCases) { section in
                    let isSelected = selectedSection == section
                    Button(action: { selectedSection = section }) {
                        HStack(spacing: 10) {
                            Image(systemName: section.iconName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(isSelected ? HUDTheme.cyan : HUDTheme.textSecondary)
                                .frame(width: 20)
                            
                            Text(section.rawValue.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(isSelected ? HUDTheme.textPrimary : HUDTheme.textSecondary)
                            
                            Spacer()
                            
                            if isSelected {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(HUDTheme.cyan)
                                    .frame(width: 3, height: 16)
                                    .shadow(color: HUDTheme.cyan, radius: 4)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isSelected ? HUDTheme.cardElevated : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? HUDTheme.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            
            Spacer()
            
            // Bottom HUD Quick Sparkline
            VStack(alignment: .leading, spacing: 8) {
                Text("SYS TELEMETRY")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(HUDTheme.textMuted)
                
                HStack {
                    Text("CPU")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.cyan)
                    Spacer()
                    Text(String(format: "%.1f%%", monitor.cpu.overallUsage))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textPrimary)
                }
                
                HUDProgressBar(
                    label: "",
                    value: monitor.cpu.overallUsage,
                    accentColor: HUDTheme.cyan,
                    height: 4,
                    showPercentage: false
                )
                
                HStack {
                    Text("RAM")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.purple)
                    Spacer()
                    Text(String(format: "%.1f%%", monitor.memory.usedPercentage))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textPrimary)
                }
                
                HUDProgressBar(
                    label: "",
                    value: monitor.memory.usedPercentage,
                    accentColor: HUDTheme.purple,
                    height: 4,
                    showPercentage: false
                )
            }
            .padding(14)
            .hudCard(cornerRadius: 8, borderColor: HUDTheme.borderSubtle)
            .padding(12)
        }
        .frame(width: 220)
        .background(HUDTheme.panelBackground)
    }
}
