import SwiftUI

public struct SystemOverviewView: View {
    @Bindable var monitor = SystemMonitorService.shared
    @Bindable var processManager = ProcessManagerService.shared
    @Bindable var commandRunner = CommandRunnerService.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // MARK: - Top Telemetry Banner
                topBanner
                
                // MARK: - 4 Core Gauges Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    cpuCard
                    memoryCard
                    networkCard
                    diskCard
                }
                
                // MARK: - Quick Action Deck & Top Resource Hogs
                HStack(alignment: .top, spacing: 16) {
                    topProcessesCard
                    quickActionsCard
                }
            }
            .padding(20)
        }
        .background(HUDTheme.background)
    }
    
    // MARK: - Top System Header Banner
    private var topBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Text("CYBERDECK C2")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(HUDTheme.cyan)
                        .tracking(2.0)
                    
                    HUDStatusPill(
                        text: monitor.memory.pressureLevel.rawValue,
                        color: monitor.memory.pressureLevel == .critical ? HUDTheme.crimson : (monitor.memory.pressureLevel == .warning ? HUDTheme.amber : HUDTheme.emerald),
                        isPulsing: monitor.memory.pressureLevel != .normal
                    )
                }
                
                Text("\(monitor.cpu.modelName) • \(monitor.cpu.physicalCores) Cores / \(monitor.cpu.logicalCores) Threads")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(HUDTheme.textSecondary)
            }
            
            Spacer()
            
            // Battery / Power Status
            if monitor.battery.hasBattery {
                HStack(spacing: 8) {
                    Image(systemName: monitor.battery.isCharging ? "battery.100.bolt" : "battery.100")
                        .font(.system(size: 16))
                        .foregroundColor(monitor.battery.percentage < 20 ? HUDTheme.crimson : HUDTheme.emerald)
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f%%", monitor.battery.percentage))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.textPrimary)
                        
                        Text(monitor.battery.isCharging ? "CHARGING" : (monitor.battery.timeRemainingMinutes > 0 ? "\(monitor.battery.timeRemainingMinutes)m LEFT" : "ON BATTERY"))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.textMuted)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .hudCard(cornerRadius: 8, borderColor: HUDTheme.borderSubtle)
            }
            
            // Pulse Indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(HUDTheme.cyan)
                    .frame(width: 8, height: 8)
                    .shadow(color: HUDTheme.cyan, radius: 4)
                
                Text("REALTIME LINK")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(HUDTheme.cyan)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .hudCard(cornerRadius: 8, borderColor: HUDTheme.cyan.opacity(0.3), hasGlow: true)
        }
        .padding(16)
        .hudCard(cornerRadius: 12)
    }
    
    // MARK: - CPU Metric Card
    private var cpuCard: some View {
        HUDMetricCard(title: "Processor Load", iconName: "cpu", accentColor: HUDTheme.cyan) {
            HStack(spacing: 20) {
                HUDCircularGauge(
                    value: monitor.cpu.overallUsage,
                    title: "Total Load",
                    subtitle: "\(monitor.cpu.physicalCores) P-Cores",
                    accentColor: HUDTheme.cyan,
                    gradient: HUDTheme.cyanGradient,
                    size: 100,
                    lineWidth: 8
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    HUDProgressBar(
                        label: "User",
                        value: monitor.cpu.userPercentage,
                        accentColor: HUDTheme.cyan,
                        height: 6
                    )
                    
                    HUDProgressBar(
                        label: "System",
                        value: monitor.cpu.systemPercentage,
                        accentColor: HUDTheme.amber,
                        height: 6
                    )
                    
                    HUDProgressBar(
                        label: "Idle",
                        value: monitor.cpu.idlePercentage,
                        accentColor: HUDTheme.textMuted,
                        height: 6
                    )
                    
                    // Sparkline
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HISTORY (40s)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.textMuted)
                        
                        HUDSparkline(
                            data: monitor.cpuHistory,
                            accentColor: HUDTheme.cyan,
                            gradient: HUDTheme.cyanGradient,
                            minVal: 0.0,
                            maxVal: 100.0,
                            height: 30
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Memory Metric Card
    private var memoryCard: some View {
        HUDMetricCard(title: "Physical Memory", iconName: "memorychip", accentColor: HUDTheme.purple) {
            HStack(spacing: 20) {
                HUDCircularGauge(
                    value: monitor.memory.usedPercentage,
                    title: "RAM Used",
                    subtitle: "\(monitor.memory.usedFormatted) / \(monitor.memory.totalFormatted)",
                    accentColor: HUDTheme.purple,
                    gradient: LinearGradient(colors: [HUDTheme.purple, HUDTheme.cobalt], startPoint: .topLeading, endPoint: .bottomTrailing),
                    size: 100,
                    lineWidth: 8
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    HUDProgressBar(
                        label: "Active",
                        value: Double(monitor.memory.activeBytes) / Double(max(monitor.memory.totalBytes, 1)) * 100.0,
                        detailText: ByteCountFormatter.string(fromByteCount: Int64(monitor.memory.activeBytes), countStyle: .memory),
                        accentColor: HUDTheme.purple,
                        height: 6
                    )
                    
                    HUDProgressBar(
                        label: "Wired",
                        value: Double(monitor.memory.wiredBytes) / Double(max(monitor.memory.totalBytes, 1)) * 100.0,
                        detailText: ByteCountFormatter.string(fromByteCount: Int64(monitor.memory.wiredBytes), countStyle: .memory),
                        accentColor: HUDTheme.amber,
                        height: 6
                    )
                    
                    HUDProgressBar(
                        label: "Compressed",
                        value: Double(monitor.memory.compressedBytes) / Double(max(monitor.memory.totalBytes, 1)) * 100.0,
                        detailText: ByteCountFormatter.string(fromByteCount: Int64(monitor.memory.compressedBytes), countStyle: .memory),
                        accentColor: HUDTheme.cobalt,
                        height: 6
                    )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HISTORY (40s)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.textMuted)
                        
                        HUDSparkline(
                            data: monitor.memoryHistory,
                            accentColor: HUDTheme.purple,
                            gradient: LinearGradient(colors: [HUDTheme.purple, HUDTheme.cobalt], startPoint: .leading, endPoint: .trailing),
                            minVal: 0.0,
                            maxVal: 100.0,
                            height: 30
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Network Metric Card
    private var networkCard: some View {
        HUDMetricCard(title: "Network Throughput", iconName: "antenna.radiowaves.left.and.right", accentColor: HUDTheme.emerald) {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    // Download Block
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(HUDTheme.emerald)
                            Text("DOWNLOAD")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textSecondary)
                        }
                        
                        Text(monitor.network.downloadRateFormatted)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Upload Block
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(HUDTheme.cyan)
                            Text("UPLOAD")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textSecondary)
                        }
                        
                        Text(monitor.network.uploadRateFormatted)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Network Sparklines
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIVE TRAFFIC (KB/s)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textMuted)
                    
                    HUDSparkline(
                        data: monitor.netInHistory,
                        accentColor: HUDTheme.emerald,
                        gradient: HUDTheme.emeraldGradient,
                        height: 45
                    )
                }
            }
        }
    }
    
    // MARK: - Disk Metric Card
    private var diskCard: some View {
        HUDMetricCard(title: "Storage & Volume", iconName: "internaldrive", accentColor: HUDTheme.amber) {
            HStack(spacing: 20) {
                HUDCircularGauge(
                    value: monitor.disk.usedPercentage,
                    title: "Macintosh HD",
                    subtitle: "\(monitor.disk.freeFormatted) Free",
                    accentColor: HUDTheme.amber,
                    gradient: HUDTheme.amberGradient,
                    size: 100,
                    lineWidth: 8
                )
                
                VStack(alignment: .leading, spacing: 10) {
                    HUDProgressBar(
                        label: "Used Space",
                        value: monitor.disk.usedPercentage,
                        detailText: monitor.disk.usedFormatted,
                        accentColor: HUDTheme.amber,
                        height: 8
                    )
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TOTAL CAPACITY")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textMuted)
                            Text(monitor.disk.totalFormatted)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("FREE CAPACITY")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textMuted)
                            Text(monitor.disk.freeFormatted)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.emerald)
                        }
                    }
                    .padding(8)
                    .hudCard(cornerRadius: 6, borderColor: HUDTheme.borderSubtle)
                }
            }
        }
    }
    
    // MARK: - Top Resource Hogs
    private var topProcessesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(HUDTheme.crimson)
                Text("HIGH-LOAD PROCESSES")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(HUDTheme.textSecondary)
                Spacer()
                Text("AUTO-KILL GUARD")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(HUDTheme.crimson)
            }
            
            Divider().background(HUDTheme.borderSubtle)
            
            ForEach(processManager.topCPUProcesses.prefix(4)) { proc in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(proc.name)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.textPrimary)
                            .lineLimit(1)
                        
                        Text("PID \(proc.pid) • \(proc.memoryFormatted)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(HUDTheme.textMuted)
                    }
                    
                    Spacer()
                    
                    Text(proc.cpuFormatted)
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundColor(proc.cpuPercentage > 50.0 ? HUDTheme.crimson : HUDTheme.amber)
                        .padding(.trailing, 8)
                    
                    Button(action: {
                        processManager.terminateProcess(pid: proc.pid, force: false)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(HUDTheme.crimson)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .help("Terminate process (SIGTERM)")
                }
                .padding(8)
                .hudCard(cornerRadius: 6, borderColor: HUDTheme.borderSubtle)
            }
        }
        .padding(14)
        .hudCard(cornerRadius: 12)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Quick Action Deck
    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(HUDTheme.amber)
                Text("COMMAND DECK SHORTCUTS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(HUDTheme.textSecondary)
                Spacer()
            }
            
            Divider().background(HUDTheme.borderSubtle)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(ScriptCommand.presets.prefix(4)) { cmd in
                    Button(action: {
                        Task {
                            await commandRunner.execute(command: cmd.shellCommand)
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: cmd.iconName)
                                    .foregroundColor(HUDTheme.cyan)
                                    .font(.system(size: 13))
                                Spacer()
                                if cmd.requiresSudo {
                                    Text("SUDO")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(HUDTheme.amber)
                                }
                            }
                            
                            Text(cmd.title)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textPrimary)
                                .lineLimit(1)
                            
                            Text(cmd.description)
                                .font(.system(size: 9, weight: .regular, design: .monospaced))
                                .foregroundColor(HUDTheme.textMuted)
                                .lineLimit(2)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .hudCard(cornerRadius: 8, borderColor: HUDTheme.borderSubtle)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .hudCard(cornerRadius: 12)
        .frame(maxWidth: .infinity)
    }
}
