import SwiftUI

public struct NetworkPortsView: View {
    @Bindable var monitor = SystemMonitorService.shared
    @Bindable var commandRunner = CommandRunnerService.shared
    @State private var targetPortInput: String = "8080"
    @State private var portInspectionResult: String = ""
    @State private var isInspectingPort: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NETWORK & PORTS INSPECTOR")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(HUDTheme.cyan)
                            .tracking(1.5)
                        Text("Interface Telemetry, Sockets & Port Listeners")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(HUDTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(16)
                .hudCard(cornerRadius: 12)
                
                // MARK: - Throughput Gauges
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(HUDTheme.emerald)
                            Text("INGRESS (DOWNLOAD)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textSecondary)
                            Spacer()
                            Text(monitor.network.downloadRateFormatted)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textPrimary)
                        }
                        
                        HUDSparkline(
                            data: monitor.netInHistory,
                            accentColor: HUDTheme.emerald,
                            gradient: HUDTheme.emeraldGradient,
                            height: 50
                        )
                    }
                    .padding(16)
                    .hudCard(cornerRadius: 12)
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(HUDTheme.cyan)
                            Text("EGRESS (UPLOAD)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textSecondary)
                            Spacer()
                            Text(monitor.network.uploadRateFormatted)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textPrimary)
                        }
                        
                        HUDSparkline(
                            data: monitor.netOutHistory,
                            accentColor: HUDTheme.cyan,
                            gradient: HUDTheme.cyanGradient,
                            height: 50
                        )
                    }
                    .padding(16)
                    .hudCard(cornerRadius: 12)
                    .frame(maxWidth: .infinity)
                }
                
                // MARK: - Port Buster / Targeted Port Query
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(HUDTheme.amber)
                        Text("PORT BUSTER (WHO IS USING THIS PORT?)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.textSecondary)
                        Spacer()
                    }
                    
                    Divider().background(HUDTheme.borderSubtle)
                    
                    HStack(spacing: 10) {
                        Text("TCP/UDP PORT:")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.textMuted)
                        
                        TextField("e.g. 3000, 8000, 8080", text: $targetPortInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.cyan)
                            .frame(width: 140)
                            .padding(8)
                            .hudCard(cornerRadius: 6, borderColor: HUDTheme.borderSubtle)
                        
                        Button(action: inspectPort) {
                            HStack(spacing: 4) {
                                Image(systemName: "magnifyingglass")
                                Text("INSPECT PORT")
                            }
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.background)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(HUDTheme.amber)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: killPortListeners) {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                Text("KILL LISTENERS")
                            }
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.crimson)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .hudCard(cornerRadius: 6, borderColor: HUDTheme.crimson.opacity(0.4), hasGlow: true)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if !portInspectionResult.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("INSPECTION TRACE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textMuted)
                            
                            Text(portInspectionResult)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(HUDTheme.textPrimary)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(hex: 0x05070B))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .padding(16)
                .hudCard(cornerRadius: 12)
                
                // MARK: - Quick Scans
                HStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await commandRunner.execute(command: "lsof -iTCP -sTCP:LISTEN -n -P | head -n 30")
                        }
                    }) {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundColor(HUDTheme.cyan)
                            Text("SCAN ALL LISTENING PORTS")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(HUDTheme.textMuted)
                        }
                        .padding(14)
                        .hudCard(cornerRadius: 10, borderColor: HUDTheme.borderSubtle)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        Task {
                            await commandRunner.execute(command: "netstat -an -f inet | grep ESTABLISHED | head -n 30")
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.swap")
                                .foregroundColor(HUDTheme.emerald)
                            Text("LIST ACTIVE TCP CONNECTIONS")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(HUDTheme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(HUDTheme.textMuted)
                        }
                        .padding(14)
                        .hudCard(cornerRadius: 10, borderColor: HUDTheme.borderSubtle)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .background(HUDTheme.background)
    }
    
    private func inspectPort() {
        let port = targetPortInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !port.isEmpty else { return }
        Task {
            let res = await commandRunner.execute(command: "lsof -i :\(port) || echo 'Port \(port) is free (no active listener)'")
            portInspectionResult = res.output
        }
    }
    
    private func killPortListeners() {
        let port = targetPortInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !port.isEmpty else { return }
        Task {
            let cmd = "lsof -ti :\(port) | xargs kill -9 2>&1 || echo 'No processes to kill on port \(port)'"
            let res = await commandRunner.execute(command: cmd)
            portInspectionResult = res.output.isEmpty ? "All processes on port \(port) killed." : res.output
        }
    }
}
