import SwiftUI
import AppKit

@main
struct MacCommandCenterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Bindable var monitor = SystemMonitorService.shared
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        Window("CyberDeck Command & Control", id: "main-dashboard") {
            MainDashboardView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1150, height: 750)
        
        MenuBarExtra {
            MenuBarView {
                openWindow(id: "main-dashboard")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            .preferredColorScheme(.dark)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "cpu")
                Text(String(format: "%.0f%%", monitor.cpu.overallUsage))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
    }
}
