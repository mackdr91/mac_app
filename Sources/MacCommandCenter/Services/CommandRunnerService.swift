import Foundation
import SwiftUI
import Combine

private final class SafeDataBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()
    
    func append(_ chunk: Data) {
        lock.lock()
        defer { lock.unlock() }
        data.append(chunk)
    }
    
    func getData() -> Data {
        lock.lock()
        defer { lock.unlock() }
        return data
    }
}

@Observable
public final class CommandRunnerService: @unchecked Sendable {
    public static let shared = CommandRunnerService()
    
    public var logs: [CommandLogEntry] = []
    public var isRunning: Bool = false
    public var currentExecutingCommand: String?
    public var liveOutputBuffer: String = ""
    
    private var activeProcess: Process?
    
    private init() {}
    
    // MARK: - Execute Shell Command
    @discardableResult
    public func execute(
        command: String,
        parameter: String? = nil
    ) async -> CommandLogEntry {
        var finalCommand = command
        if let param = parameter, !param.isEmpty {
            finalCommand = String(format: command, param, param)
        }
        
        await MainActor.run {
            self.isRunning = true
            self.currentExecutingCommand = finalCommand
            self.liveOutputBuffer = "> Running: \(finalCommand)\n"
        }
        
        let startTime = Date()
        let process = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = errorPipe
        process.arguments = ["-c", finalCommand]
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        
        process.environment = ProcessInfo.processInfo.environment
        self.activeProcess = process
        
        let outBuffer = SafeDataBuffer()
        let errBuffer = SafeDataBuffer()
        
        let outHandle = pipe.fileHandleForReading
        let errHandle = errorPipe.fileHandleForReading
        
        outHandle.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            outBuffer.append(chunk)
            if let text = String(data: chunk, encoding: .utf8) {
                Task { @MainActor [weak self] in
                    self?.liveOutputBuffer.append(text)
                }
            }
        }
        
        errHandle.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            errBuffer.append(chunk)
            if let text = String(data: chunk, encoding: .utf8) {
                Task { @MainActor [weak self] in
                    self?.liveOutputBuffer.append(text)
                }
            }
        }
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            let errorText = "Execution Error: \(error.localizedDescription)\n"
            await MainActor.run {
                self.liveOutputBuffer.append(errorText)
            }
        }
        
        outHandle.readabilityHandler = nil
        errHandle.readabilityHandler = nil
        
        let exitCode = process.terminationStatus
        let duration = Date().timeIntervalSince(startTime)
        
        let stdoutString = String(data: outBuffer.getData(), encoding: .utf8) ?? ""
        let stderrString = String(data: errBuffer.getData(), encoding: .utf8) ?? ""
        let combinedOutput = (stdoutString + "\n" + stderrString).trimmingCharacters(in: .whitespacesAndNewlines)
        
        let entry = CommandLogEntry(
            timestamp: startTime,
            command: finalCommand,
            output: combinedOutput.isEmpty ? "Process completed with exit code \(exitCode)" : combinedOutput,
            isError: exitCode != 0,
            exitCode: exitCode,
            duration: duration
        )
        
        await MainActor.run {
            self.logs.insert(entry, at: 0)
            self.isRunning = false
            self.currentExecutingCommand = nil
            self.activeProcess = nil
            self.liveOutputBuffer.append("\n[Finished with exit code \(exitCode) in \(String(format: "%.2f", duration))s]\n")
        }
        
        return entry
    }
    
    public func terminateActiveProcess() {
        activeProcess?.terminate()
        activeProcess = nil
        isRunning = false
        currentExecutingCommand = nil
    }
    
    public func clearLogs() {
        logs.removeAll()
        liveOutputBuffer = ""
    }
}
