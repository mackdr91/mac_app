import SwiftUI

public struct CommandDeckView: View {
    @Bindable var commandRunner = CommandRunnerService.shared
    @State private var customCommandText: String = ""
    @State private var parameterInputs: [String: String] = [:]
    @State private var selectedCategory: CommandCategory? = nil
    
    public init() {}
    
    private var filteredPresets: [ScriptCommand] {
        if let cat = selectedCategory {
            return ScriptCommand.presets.filter { $0.category == cat }
        }
        return ScriptCommand.presets
    }
    
    public var body: some View {
        HSplitView {
            // MARK: - Left Pane: Preset Cards & Custom Command Input
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("COMMAND DECK")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(HUDTheme.cyan)
                            .tracking(1.5)
                        Text("System Automation & Developer Script Runner")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(HUDTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Category Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterPill(title: "ALL", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        
                        ForEach(CommandCategory.allCases, id: \.self) { cat in
                            filterPill(title: cat.rawValue, isSelected: selectedCategory == cat) {
                                selectedCategory = cat
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Custom Terminal Input Bar
                VStack(alignment: .leading, spacing: 8) {
                    Text("CUSTOM SHELL DISPATCH")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textMuted)
                    
                    HStack(spacing: 8) {
                        Text("$")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(HUDTheme.cyan)
                        
                        TextField("e.g. ping -c 3 google.com, uptime, vm_stat", text: $customCommandText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(HUDTheme.textPrimary)
                            .onSubmit {
                                runCustomCommand()
                            }
                        
                        Button(action: runCustomCommand) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                Text("EXEC")
                            }
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.background)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(HUDTheme.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(customCommandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || commandRunner.isRunning)
                    }
                    .padding(10)
                    .hudCard(cornerRadius: 8, borderColor: HUDTheme.cyan.opacity(0.4))
                }
                .padding(.horizontal, 20)
                
                // Presets Grid
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredPresets) { cmd in
                            presetCard(cmd)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .frame(minWidth: 420, maxWidth: 520)
            .background(HUDTheme.background)
            
            // MARK: - Right Pane: Live Streaming Monospace Terminal
            VStack(spacing: 0) {
                // Console Toolbar
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(commandRunner.isRunning ? HUDTheme.amber : HUDTheme.emerald)
                            .frame(width: 8, height: 8)
                            .shadow(color: commandRunner.isRunning ? HUDTheme.amber : HUDTheme.emerald, radius: 4)
                        
                        Text(commandRunner.isRunning ? "RUNNING SCRIPT..." : "TERMINAL CONSOLE (IDLE)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    if commandRunner.isRunning {
                        Button(action: { commandRunner.terminateActiveProcess() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "stop.fill")
                                Text("ABORT")
                            }
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(HUDTheme.crimson)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .hudCard(cornerRadius: 4, borderColor: HUDTheme.crimson.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(commandRunner.liveOutputBuffer, forType: .string)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(HUDTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Copy Terminal Output")
                    
                    Button(action: { commandRunner.clearLogs() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(HUDTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Clear Terminal Output")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(HUDTheme.panelBackground)
                
                Divider().background(HUDTheme.borderSubtle)
                
                // Terminal Output Area
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        Text(commandRunner.liveOutputBuffer.isEmpty ? "// Ready for input. Select a preset or enter shell command above.\n" : commandRunner.liveOutputBuffer)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(commandRunner.isRunning ? HUDTheme.cyan : HUDTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .id("bottom")
                    }
                    .background(Color(hex: 0x05070B))
                    .onChange(of: commandRunner.liveOutputBuffer) { _, _ in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(minWidth: 450)
            .background(Color(hex: 0x05070B))
        }
    }
    
    // MARK: - Preset Script Card
    private func presetCard(_ cmd: ScriptCommand) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: cmd.iconName)
                        .foregroundColor(HUDTheme.cyan)
                        .font(.system(size: 13, weight: .bold))
                    
                    Text(cmd.title)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textPrimary)
                }
                
                Spacer()
                
                if cmd.requiresSudo {
                    Text("SUDO")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.amber)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .hudCard(cornerRadius: 4, borderColor: HUDTheme.amber.opacity(0.3))
                }
                
                Button(action: {
                    let param = parameterInputs[cmd.id]
                    Task {
                        await commandRunner.execute(command: cmd.shellCommand, parameter: param)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                        Text("RUN")
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(HUDTheme.background)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(HUDTheme.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .disabled(commandRunner.isRunning)
            }
            
            Text(cmd.description)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(HUDTheme.textMuted)
            
            // Parameter Input if applicable
            if let placeholder = cmd.parameterPlaceholder {
                HStack {
                    Text("ARG:")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(HUDTheme.textMuted)
                    
                    TextField(placeholder, text: Binding(
                        get: { parameterInputs[cmd.id, default: ""] },
                        set: { parameterInputs[cmd.id] = $0 }
                    ))
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(HUDTheme.textPrimary)
                }
                .padding(6)
                .hudCard(cornerRadius: 6, borderColor: HUDTheme.borderSubtle)
            }
        }
        .padding(12)
        .hudCard(cornerRadius: 10, borderColor: HUDTheme.borderSubtle)
    }
    
    private func filterPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? HUDTheme.background : HUDTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? HUDTheme.cyan : HUDTheme.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? HUDTheme.cyan : HUDTheme.borderSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    private func runCustomCommand() {
        let cmd = customCommandText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return }
        customCommandText = ""
        Task {
            await commandRunner.execute(command: cmd)
        }
    }
}
