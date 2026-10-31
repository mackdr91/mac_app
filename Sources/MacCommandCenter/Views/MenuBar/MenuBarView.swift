import SwiftUI

public struct MenuBarView: View {
    @Bindable var monitor = SystemMonitorService.shared
    @Bindable var processManager = ProcessManagerService.shared
    @Bindable var commandRunner = CommandRunnerService.shared
    public var onOpenMainWindow: () -> Void
    
    public init(onOpenMainWindow: @escaping () -> Void = {}) {
        self.onOpenMainWindow = onOpenMainWindow
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(HUDTheme.cyan)
                        .frame(width: 8, height: 8)
                        .shadow(color: HUDTheme.cyan, radius: 4)
                    
                    Text("CYBERDECK C2")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundColor(HUDTheme.cyan)
                        .tracking(1.2)
                }
                
                Spacer()
                
                Button(action: onOpenMainWindow) {
                    HStack(spacing: 4) {
                        Image(systemName: "macwindow")
                        Text("EXPAND")
                    }
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(HUDTheme.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .hudCard(cornerRadius: 4, borderColor: HUDTheme.cyan.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            
            Divider().background(HUDTheme.borderSubtle)
            
            // Mini Gauges Row
            HStack(spacing: 10) {
                // CPU
                VStack(spacing: 4) {
                    Text("CPU")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textMuted)
                    Text(String(format: "%.1f%%", monitor.cpu.overallUsage))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.cyan)
                    HUDProgressBar(label: "", value: monitor.cpu.overallUsage, accentColor: HUDTheme.cyan, height: 4, showPercentage: false)
                }
                .padding(8)
                .hudCard(cornerRadius: 6, borderColor: HUDTheme.borderSubtle)
                
                // RAM
                VStack(spacing: 4) {
                    Text("RAM")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textMuted)
                    Text(String(format: "%.1f%%", monitor.memory.usedPercentage))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.purple)
                    HUDProgressBar(label: "", value: monitor.memory.usedPercentage, accentColor: HUDTheme.purple, height: 4, showPercentage: false)
                }
                .padding(8)
                .hudCard(cornerRadius: 6, borderColor: HUDTheme.borderSubtle)
                
                // NET IN
                VStack(spacing: 4) {
                    Text("NET DOWN")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textMuted)
                    Text(monitor.network.downloadRateFormatted)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.emerald)
                        .lineLimit(1)
                    HUDProgressBar(label: "", value: min(monitor.network.bytesInPerSec / 1024.0 / 10.0, 100.0), accentColor: HUDTheme.emerald, height: 4, showPercentage: false)
                }
                .padding(8)
                .hudCard(cornerRadius: 6, borderColor: HUDTheme.borderSubtle)
            }
            
            // Top Resource Hogs List
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("TOP RESOURCE CONSUMERS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textMuted)
                    Spacer()
                    Text("QUICK KILL")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.crimson)
                }
                
                ForEach(processManager.topCPUProcesses.prefix(3)) { proc in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(proc.name)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textPrimary)
                                .lineLimit(1)
                            
                            Text("PID \(proc.pid) • \(proc.memoryFormatted)")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(HUDTheme.textMuted)
                        }
                        
                        Spacer()
                        
                        Text(proc.cpuFormatted)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(proc.cpuPercentage > 30.0 ? HUDTheme.crimson : HUDTheme.amber)
                        
                        Button(action: {
                            processManager.terminateProcess(pid: proc.pid, force: false)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(HUDTheme.crimson)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(6)
                    .hudCard(cornerRadius: 6, borderColor: HUDTheme.borderSubtle)
                }
            }
            
            Divider().background(HUDTheme.borderSubtle)
            
            // Quick Actions & Quit
            HStack(spacing: 8) {
                Button(action: {
                    Task {
                        await commandRunner.execute(command: "dscacheutil -flushcache && sudo killall -HUP mDNSResponder")
                    }
                }) {
                    Text("Flush DNS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .hudCard(cornerRadius: 6, borderColor: HUDTheme.cyan.opacity(0.3))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    Task {
                        await commandRunner.execute(command: "sudo purge")
                    }
                }) {
                    Text("Purge RAM")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .hudCard(cornerRadius: 6, borderColor: HUDTheme.purple.opacity(0.3))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 360)
        .background(HUDTheme.panelBackground)
    }
}
