import SwiftUI

public struct HardwareTelemetryView: View {
    @Bindable var monitor = SystemMonitorService.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HARDWARE TELEMETRY")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(HUDTheme.cyan)
                            .tracking(1.5)
                        Text("Silicon Core Dynamics & Subsystem Sensors")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(HUDTheme.textSecondary)
                    }
                    Spacer()
                    
                    HUDStatusPill(
                        text: monitor.cpu.thermalState,
                        color: HUDTheme.emerald
                    )
                }
                .padding(16)
                .hudCard(cornerRadius: 12)
                
                // MARK: - CPU Per-Core Matrix
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(HUDTheme.cyan)
                        Text("PER-CORE LOAD MATRIX")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.textSecondary)
                        Spacer()
                        Text("\(monitor.cpu.coreUsages.count) LOGICAL CORES DETECTED")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(HUDTheme.textMuted)
                    }
                    
                    Divider().background(HUDTheme.borderSubtle)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                        ForEach(Array(monitor.cpu.coreUsages.enumerated()), id: \.offset) { index, usage in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("CORE \(index)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(HUDTheme.textSecondary)
                                    Spacer()
                                    Text(String(format: "%.1f%%", usage))
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(usage > 75.0 ? HUDTheme.crimson : (usage > 40.0 ? HUDTheme.amber : HUDTheme.cyan))
                                }
                                
                                HUDProgressBar(
                                    label: "",
                                    value: usage,
                                    accentColor: usage > 75.0 ? HUDTheme.crimson : (usage > 40.0 ? HUDTheme.amber : HUDTheme.cyan),
                                    height: 5,
                                    showPercentage: false
                                )
                            }
                            .padding(10)
                            .hudCard(cornerRadius: 8, borderColor: HUDTheme.borderSubtle)
                        }
                    }
                }
                .padding(16)
                .hudCard(cornerRadius: 12)
                
                // MARK: - Detailed Memory Architecture Breakdown
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "memorychip")
                            .foregroundColor(HUDTheme.purple)
                        Text("UNIFIED MEMORY SUB-ALLOCATIONS")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.textSecondary)
                        Spacer()
                        Text(monitor.memory.totalFormatted)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.textPrimary)
                    }
                    
                    Divider().background(HUDTheme.borderSubtle)
                    
                    VStack(spacing: 12) {
                        HUDProgressBar(
                            label: "App Active Memory (In-use by applications)",
                            value: Double(monitor.memory.activeBytes) / Double(max(monitor.memory.totalBytes, 1)) * 100.0,
                            detailText: ByteCountFormatter.string(fromByteCount: Int64(monitor.memory.activeBytes), countStyle: .memory),
                            accentColor: HUDTheme.purple,
                            height: 10
                        )
                        
                        HUDProgressBar(
                            label: "Wired Memory (OS Kernel locked, non-pageable)",
                            value: Double(monitor.memory.wiredBytes) / Double(max(monitor.memory.totalBytes, 1)) * 100.0,
                            detailText: ByteCountFormatter.string(fromByteCount: Int64(monitor.memory.wiredBytes), countStyle: .memory),
                            accentColor: HUDTheme.amber,
                            height: 10
                        )
                        
                        HUDProgressBar(
                            label: "Compressed Memory (RAM compressor swap-save)",
                            value: Double(monitor.memory.compressedBytes) / Double(max(monitor.memory.totalBytes, 1)) * 100.0,
                            detailText: ByteCountFormatter.string(fromByteCount: Int64(monitor.memory.compressedBytes), countStyle: .memory),
                            accentColor: HUDTheme.cobalt,
                            height: 10
                        )
                        
                        HUDProgressBar(
                            label: "Free Memory (Immediate headroom buffer)",
                            value: Double(monitor.memory.freeBytes) / Double(max(monitor.memory.totalBytes, 1)) * 100.0,
                            detailText: ByteCountFormatter.string(fromByteCount: Int64(monitor.memory.freeBytes), countStyle: .memory),
                            accentColor: HUDTheme.emerald,
                            height: 10
                        )
                    }
                }
                .padding(16)
                .hudCard(cornerRadius: 12)
                
                // MARK: - Power & Storage Footprint
                HStack(spacing: 16) {
                    // Power & Battery
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bolt.batteryblock.fill")
                                .foregroundColor(HUDTheme.emerald)
                            Text("POWER & BATTERY SUB-SYSTEM")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textSecondary)
                        }
                        
                        Divider().background(HUDTheme.borderSubtle)
                        
                        if monitor.battery.hasBattery {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("BATTERY LEVEL")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(HUDTheme.textMuted)
                                    Spacer()
                                    Text(String(format: "%.1f%%", monitor.battery.percentage))
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(HUDTheme.textPrimary)
                                }
                                
                                HStack {
                                    Text("POWER SOURCE")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(HUDTheme.textMuted)
                                    Spacer()
                                    Text(monitor.battery.isPluggedIn ? "AC Adapter" : "Battery")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(HUDTheme.cyan)
                                }
                                
                                HStack {
                                    Text("CHARGING STATUS")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(HUDTheme.textMuted)
                                    Spacer()
                                    Text(monitor.battery.isCharging ? "Charging" : "Discharging")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(monitor.battery.isCharging ? HUDTheme.emerald : HUDTheme.amber)
                                }
                            }
                        } else {
                            Text("Desktop Power (Direct AC Source Connected)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(HUDTheme.textSecondary)
                        }
                    }
                    .padding(16)
                    .hudCard(cornerRadius: 12)
                    .frame(maxWidth: .infinity)
                    
                    // Root Volume Mount
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "internaldrive")
                                .foregroundColor(HUDTheme.amber)
                            Text("ROOT VOLUME MOUNT")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textSecondary)
                        }
                        
                        Divider().background(HUDTheme.borderSubtle)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("MOUNT POINT")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(HUDTheme.textMuted)
                                Spacer()
                                Text(monitor.disk.mountPath)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(HUDTheme.cyan)
                            }
                            
                            HStack {
                                Text("ALLOCATED SPACE")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(HUDTheme.textMuted)
                                Spacer()
                                Text(monitor.disk.usedFormatted)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(HUDTheme.textPrimary)
                            }
                            
                            HStack {
                                Text("HEADROOM FREE")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(HUDTheme.textMuted)
                                Spacer()
                                Text(monitor.disk.freeFormatted)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(HUDTheme.emerald)
                            }
                        }
                    }
                    .padding(16)
                    .hudCard(cornerRadius: 12)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .background(HUDTheme.background)
    }
}
