import SwiftUI

public struct MainDashboardView: View {
    @State private var selectedSection: NavigationSection = .overview
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 0) {
            // Sidebar Navigation
            SidebarView(selectedSection: $selectedSection)
            
            Divider().background(HUDTheme.borderSubtle)
            
            // Content Pane
            Group {
                switch selectedSection {
                case .overview:
                    SystemOverviewView()
                case .telemetry:
                    HardwareTelemetryView()
                case .processes:
                    ProcessCommanderView()
                case .commands:
                    CommandDeckView()
                case .network:
                    NetworkPortsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(HUDTheme.background)
        .frame(minWidth: 1050, minHeight: 700)
    }
}
