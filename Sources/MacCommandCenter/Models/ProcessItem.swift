import Foundation

public struct ProcessItem: Identifiable, Sendable, Hashable {
    public var id: Int32 { pid }
    public let pid: Int32
    public let ppid: Int32
    public let name: String
    public let user: String
    public var cpuPercentage: Double
    public var memoryBytes: UInt64
    public var virtualMemoryBytes: UInt64
    public let status: String
    public let threadCount: Int
    public let path: String
    
    public init(
        pid: Int32,
        ppid: Int32 = 0,
        name: String,
        user: String = "unknown",
        cpuPercentage: Double = 0.0,
        memoryBytes: UInt64 = 0,
        virtualMemoryBytes: UInt64 = 0,
        status: String = "Running",
        threadCount: Int = 1,
        path: String = ""
    ) {
        self.pid = pid
        self.ppid = ppid
        self.name = name
        self.user = user
        self.cpuPercentage = cpuPercentage
        self.memoryBytes = memoryBytes
        self.virtualMemoryBytes = virtualMemoryBytes
        self.status = status
        self.threadCount = threadCount
        self.path = path
    }
    
    public var memoryFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryBytes), countStyle: .memory)
    }
    
    public var cpuFormatted: String {
        String(format: "%.1f%%", cpuPercentage)
    }
    
    public var pidFormatted: String {
        String(format: "%d", pid)
    }
    
    public var pidHexFormatted: String {
        String(format: "0x%04X", pid)
    }
}
