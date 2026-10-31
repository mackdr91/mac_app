import SwiftUI

public struct ProcessCommanderView: View {
    @Bindable var processManager = ProcessManagerService.shared
    @State private var selectedProcess: ProcessItem?
    @State private var showConfirmKill: Bool = false
    @State private var processToKill: ProcessItem?
    @State private var forceKillTarget: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            // MARK: - Filter & Control Toolbar
            HStack(spacing: 12) {
                // Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(HUDTheme.textMuted)
                    
                    TextField("Search process name, PID, or user...", text: $processManager.searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(HUDTheme.textPrimary)
                    
                    if !processManager.searchQuery.isEmpty {
                        Button(action: { processManager.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(HUDTheme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .hudCard(cornerRadius: 8, borderColor: HUDTheme.borderSubtle)
                .frame(maxWidth: 320)
                
                Spacer()
                
                // Sort Picker
                Menu {
                    ForEach(ProcessManagerService.ProcessSortOption.allCases, id: \.self) { option in
                        Button(action: { processManager.sortOption = option }) {
                            HStack {
                                Text(option.rawValue)
                                if processManager.sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(processManager.sortOption.rawValue)
                    }
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(HUDTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .hudCard(cornerRadius: 8, borderColor: HUDTheme.borderSubtle)
                }
                .menuStyle(.borderlessButton)
                
                // Refresh Button
                Button(action: {
                    processManager.refreshProcesses()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("REFRESH")
                    }
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(HUDTheme.cyan)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .hudCard(cornerRadius: 8, borderColor: HUDTheme.cyan.opacity(0.4), hasGlow: true)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Error Banner if kill failed
            if let error = processManager.lastErrorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(HUDTheme.crimson)
                    Text(error)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(HUDTheme.crimson)
                    Spacer()
                    Button(action: { processManager.lastErrorMessage = nil }) {
                        Image(systemName: "xmark")
                            .foregroundColor(HUDTheme.crimson)
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .hudCard(cornerRadius: 8, borderColor: HUDTheme.crimson.opacity(0.4))
                .padding(.horizontal, 20)
            }
            
            // MARK: - Table Header
            HStack(spacing: 12) {
                Text("PID")
                    .frame(width: 80, alignment: .leading)
                Text("PROCESS NAME")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("USER")
                    .frame(width: 90, alignment: .leading)
                Text("THREADS")
                    .frame(width: 70, alignment: .trailing)
                Text("CPU %")
                    .frame(width: 80, alignment: .trailing)
                Text("MEMORY")
                    .frame(width: 90, alignment: .trailing)
                Text("ACTION")
                    .frame(width: 130, alignment: .center)
            }
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(HUDTheme.textMuted)
            .padding(.horizontal, 28)
            .padding(.vertical, 8)
            .background(HUDTheme.panelBackground)
            
            // MARK: - Process Rows List
            ScrollView(.vertical) {
                LazyVStack(spacing: 4) {
                    ForEach(processManager.filteredProcesses) { proc in
                        processRow(proc)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(HUDTheme.background)
        .confirmationDialog(
            "Terminate Process?",
            isPresented: $showConfirmKill,
            titleVisibility: .visible
        ) {
            Button(forceKillTarget ? "Force Kill (SIGKILL)" : "Terminate (SIGTERM)", role: .destructive) {
                if let target = processToKill {
                    processManager.terminateProcess(pid: target.pid, force: forceKillTarget)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let target = processToKill {
                Text("Are you sure you want to kill \(target.name) (PID: \(target.pid))?")
            }
        }
        .sheet(item: $selectedProcess) { proc in
            processDetailSheet(proc)
        }
    }
    
    // MARK: - Single Process Row
    private func processRow(_ proc: ProcessItem) -> some View {
        HStack(spacing: 12) {
            // PID
            HStack(spacing: 4) {
                Text(proc.pidHexFormatted)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(HUDTheme.textMuted)
                Text("(\(proc.pid))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(HUDTheme.textSecondary)
            }
            .frame(width: 80, alignment: .leading)
            
            // Name & Path preview
            Button(action: { selectedProcess = proc }) {
                HStack(spacing: 8) {
                    Image(systemName: "app.dashed")
                        .foregroundColor(HUDTheme.cyan)
                        .font(.system(size: 12))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(proc.name)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.textPrimary)
                            .lineLimit(1)
                        
                        if !proc.path.isEmpty {
                            Text(proc.path)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(HUDTheme.textDim)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // User
            Text(proc.user)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(HUDTheme.textSecondary)
                .frame(width: 90, alignment: .leading)
                .lineLimit(1)
            
            // Thread Count
            Text("\(proc.threadCount)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(HUDTheme.textMuted)
                .frame(width: 70, alignment: .trailing)
            
            // CPU %
            Text(proc.cpuFormatted)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(proc.cpuPercentage > 40.0 ? HUDTheme.crimson : (proc.cpuPercentage > 10.0 ? HUDTheme.amber : HUDTheme.textSecondary))
                .frame(width: 80, alignment: .trailing)
            
            // Memory
            Text(proc.memoryFormatted)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(HUDTheme.textPrimary)
                .frame(width: 90, alignment: .trailing)
            
            // Action Buttons
            HStack(spacing: 6) {
                // Quick Kill (SIGTERM)
                Button(action: {
                    processToKill = proc
                    forceKillTarget = false
                    showConfirmKill = true
                }) {
                    Text("KILL")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.amber)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .hudCard(cornerRadius: 4, borderColor: HUDTheme.amber.opacity(0.3))
                }
                .buttonStyle(.plain)
                .help("Graceful Kill (SIGTERM)")
                
                // Force Kill (SIGKILL)
                Button(action: {
                    processToKill = proc
                    forceKillTarget = true
                    showConfirmKill = true
                }) {
                    Text("FORCE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.crimson)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .hudCard(cornerRadius: 4, borderColor: HUDTheme.crimson.opacity(0.4), hasGlow: true)
                }
                .buttonStyle(.plain)
                .help("Force Kill (SIGKILL -9)")
            }
            .frame(width: 130, alignment: .center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .hudCard(cornerRadius: 8, borderColor: HUDTheme.borderSubtle)
    }
    
    // MARK: - Process Detail Inspector Sheet
    private func processDetailSheet(_ proc: ProcessItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PROCESS INSPECTOR")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(HUDTheme.cyan)
                    Text(proc.name)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textPrimary)
                }
                Spacer()
                Button("Done") {
                    selectedProcess = nil
                }
                .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
            
            Divider().background(HUDTheme.borderSubtle)
            
            VStack(spacing: 10) {
                detailRow(label: "Process ID (PID)", value: "\(proc.pid) (\(proc.pidHexFormatted))")
                detailRow(label: "Parent PID (PPID)", value: "\(proc.ppid)")
                detailRow(label: "Owner / UID", value: proc.user)
                detailRow(label: "Active Threads", value: "\(proc.threadCount)")
                detailRow(label: "CPU Utilization", value: proc.cpuFormatted)
                detailRow(label: "Physical Memory (RSS)", value: proc.memoryFormatted)
                detailRow(label: "Virtual Memory (VSize)", value: ByteCountFormatter.string(fromByteCount: Int64(proc.virtualMemoryBytes), countStyle: .memory))
                detailRow(label: "Binary Path", value: proc.path.isEmpty ? "Kernel / System Process" : proc.path)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    processManager.pauseProcess(pid: proc.pid)
                }) {
                    Text("Pause (SIGSTOP)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.amber)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .hudCard(cornerRadius: 8, borderColor: HUDTheme.amber.opacity(0.4))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    processManager.resumeProcess(pid: proc.pid)
                }) {
                    Text("Resume (SIGCONT)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.emerald)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .hudCard(cornerRadius: 8, borderColor: HUDTheme.emerald.opacity(0.4))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    processManager.terminateProcess(pid: proc.pid, force: true)
                    selectedProcess = nil
                }) {
                    Text("Force Terminate")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.crimson)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .hudCard(cornerRadius: 8, borderColor: HUDTheme.crimson.opacity(0.4), hasGlow: true)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(width: 550, height: 420)
        .background(HUDTheme.panelBackground)
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(HUDTheme.textMuted)
                .frame(width: 180, alignment: .leading)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(HUDTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
