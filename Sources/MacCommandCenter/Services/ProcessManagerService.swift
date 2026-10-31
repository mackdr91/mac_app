import Foundation
import SwiftUI
import Combine
import Darwin

@Observable
public final class ProcessManagerService: @unchecked Sendable {
    public static let shared = ProcessManagerService()
    
    public var processes: [ProcessItem] = []
    public var filteredProcesses: [ProcessItem] = []
    public var searchQuery: String = "" {
        didSet { applyFilter() }
    }
    public var sortOption: ProcessSortOption = .cpuDescending {
        didSet { applySort() }
    }
    
    public var topCPUProcesses: [ProcessItem] {
        Array(processes.sorted { $0.cpuPercentage > $1.cpuPercentage }.prefix(5))
    }
    
    public var topMemoryProcesses: [ProcessItem] {
        Array(processes.sorted { $0.memoryBytes > $1.memoryBytes }.prefix(5))
    }
    
    public var isLoading: Bool = false
    public var lastErrorMessage: String?
    
    // Previous CPU sample cache [PID: (userTicks, systemTicks, timestamp)]
    private var previousSamples: [Int32: (UInt64, UInt64, Date)] = [:]
    private var timer: Timer?
    
    public enum ProcessSortOption: String, CaseIterable, Sendable {
        case cpuDescending = "CPU (High to Low)"
        case memoryDescending = "Memory (High to Low)"
        case nameAscending = "Name (A-Z)"
        case pidAscending = "PID (Ascending)"
    }
    
    private init() {
        refreshProcesses()
        startPeriodicRefresh()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    public func startPeriodicRefresh() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refreshProcesses()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    public func stopPeriodicRefresh() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Process Enumeration
    public func refreshProcesses() {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            let items = self.fetchProcessList()
            
            await MainActor.run {
                self.processes = items
                self.applyFilter()
            }
        }
    }
    
    private func fetchProcessList() -> [ProcessItem] {
        let maxPids = 4096
        var pids = [pid_t](repeating: 0, count: maxPids)
        let byteCount = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(maxPids * MemoryLayout<pid_t>.size))
        guard byteCount > 0 else { return [] }
        
        let pidCount = Int(byteCount) / MemoryLayout<pid_t>.size
        let now = Date()
        var items: [ProcessItem] = []
        var newSamples: [Int32: (UInt64, UInt64, Date)] = [:]
        
        for i in 0..<pidCount {
            let pid = pids[i]
            guard pid > 0 else { continue }
            
            // Task info (memory & cpu ticks)
            var taskInfo = proc_taskinfo()
            let taskResult = proc_pidinfo(
                pid,
                PROC_PIDTASKINFO,
                0,
                &taskInfo,
                Int32(MemoryLayout<proc_taskinfo>.size)
            )
            guard taskResult == MemoryLayout<proc_taskinfo>.size else { continue }
            
            // BSD info (PID, PPID, UID, status)
            var bsdInfo = proc_bsdinfo()
            let bsdResult = proc_pidinfo(
                pid,
                PROC_PIDTBSDINFO,
                0,
                &bsdInfo,
                Int32(MemoryLayout<proc_bsdinfo>.size)
            )
            
            let ppid = bsdResult > 0 ? Int32(bsdInfo.pbi_ppid) : 0
            let uid = bsdResult > 0 ? bsdInfo.pbi_uid : 0
            let user = resolveUsername(uid: uid)
            
            // Name
            var name = ""
            var nameBuffer = [CChar](repeating: 0, count: 256)
            let nameResult = proc_name(pid, &nameBuffer, UInt32(nameBuffer.count))
            if nameResult > 0 {
                name = nameBuffer.withUnsafeBufferPointer { ptr in
                    ptr.baseAddress != nil ? String(cString: ptr.baseAddress!) : ""
                }
            }
            if name.isEmpty && bsdResult > 0 {
                let comm = withUnsafeBytes(of: bsdInfo.pbi_comm) { rawBuffer in
                    String(cString: rawBuffer.baseAddress!.assumingMemoryBound(to: CChar.self))
                }
                name = comm
            }
            if name.isEmpty {
                name = "PID \(pid)"
            }
            
            // Path
            var pathBuffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
            let pathResult = proc_pidpath(pid, &pathBuffer, UInt32(pathBuffer.count))
            let path = pathResult > 0 ? pathBuffer.withUnsafeBufferPointer { ptr in
                ptr.baseAddress != nil ? String(cString: ptr.baseAddress!) : ""
            } : ""
            
            // CPU Calculation over interval
            let userTicks = taskInfo.pti_total_user
            let systemTicks = taskInfo.pti_total_system
            newSamples[pid] = (userTicks, systemTicks, now)
            
            var cpuPct = 0.0
            if let prev = previousSamples[pid] {
                let elapsed = now.timeIntervalSince(prev.2)
                if elapsed > 0.1 {
                    let userDelta = userTicks >= prev.0 ? userTicks - prev.0 : 0
                    let sysDelta = systemTicks >= prev.1 ? systemTicks - prev.1 : 0
                    let totalTime = Double(userDelta + sysDelta) / 1_000_000_000.0
                    cpuPct = (totalTime / elapsed) * 100.0
                }
            }
            
            let item = ProcessItem(
                pid: pid,
                ppid: ppid,
                name: name,
                user: user,
                cpuPercentage: min(cpuPct, 1600.0),
                memoryBytes: taskInfo.pti_resident_size,
                virtualMemoryBytes: taskInfo.pti_virtual_size,
                status: "Running",
                threadCount: Int(taskInfo.pti_threadnum),
                path: path
            )
            items.append(item)
        }
        
        self.previousSamples = newSamples
        return items
    }
    
    private func resolveUsername(uid: uid_t) -> String {
        if uid == 0 { return "root" }
        if let pw = getpwuid(uid) {
            return String(cString: pw.pointee.pw_name)
        }
        return "\(uid)"
    }
    
    // MARK: - Filter and Sort
    public func applyFilter() {
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filteredProcesses = processes
        } else {
            let query = searchQuery.lowercased()
            filteredProcesses = processes.filter {
                $0.name.lowercased().contains(query) ||
                "\($0.pid)".contains(query) ||
                $0.user.lowercased().contains(query)
            }
        }
        applySort()
    }
    
    private func applySort() {
        switch sortOption {
        case .cpuDescending:
            filteredProcesses.sort { $0.cpuPercentage > $1.cpuPercentage }
        case .memoryDescending:
            filteredProcesses.sort { $0.memoryBytes > $1.memoryBytes }
        case .nameAscending:
            filteredProcesses.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .pidAscending:
            filteredProcesses.sort { $0.pid < $1.pid }
        }
    }
    
    // MARK: - Process Signals / Kill Operations
    @discardableResult
    public func terminateProcess(pid: Int32, force: Bool = false) -> Bool {
        let signal = force ? SIGKILL : SIGTERM
        let result = kill(pid, signal)
        if result == 0 {
            processes.removeAll { $0.pid == pid }
            filteredProcesses.removeAll { $0.pid == pid }
            lastErrorMessage = nil
            return true
        } else {
            let errorDesc = String(cString: strerror(errno))
            lastErrorMessage = "Failed to terminate PID \(pid): \(errorDesc)"
            return false
        }
    }
    
    @discardableResult
    public func pauseProcess(pid: Int32) -> Bool {
        return kill(pid, SIGSTOP) == 0
    }
    
    @discardableResult
    public func resumeProcess(pid: Int32) -> Bool {
        return kill(pid, SIGCONT) == 0
    }
}
