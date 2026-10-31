import Foundation

// MARK: - CPU Metrics
public struct CPUMetrics: Sendable {
    public var overallUsage: Double = 0.0
    public var userPercentage: Double = 0.0
    public var systemPercentage: Double = 0.0
    public var idlePercentage: Double = 100.0
    public var coreUsages: [Double] = []
    public var physicalCores: Int = 0
    public var logicalCores: Int = 0
    public var modelName: String = "Apple Silicon"
    public var thermalState: String = "Nominal"
    
    public init() {}
}

// MARK: - Memory Metrics
public enum MemoryPressureLevel: String, Sendable {
    case normal = "NOMINAL"
    case warning = "ELEVATED"
    case critical = "CRITICAL"
}

public struct MemoryMetrics: Sendable {
    public var totalBytes: UInt64 = 0
    public var activeBytes: UInt64 = 0
    public var wiredBytes: UInt64 = 0
    public var compressedBytes: UInt64 = 0
    public var freeBytes: UInt64 = 0
    public var appMemoryBytes: UInt64 = 0
    public var usedPercentage: Double = 0.0
    public var pressureLevel: MemoryPressureLevel = .normal
    
    public init() {}
    
    public var usedBytes: UInt64 {
        return activeBytes + wiredBytes + compressedBytes
    }
    
    public var totalFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .memory)
    }
    
    public var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(usedBytes), countStyle: .memory)
    }
    
    public var freeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(freeBytes), countStyle: .memory)
    }
}

// MARK: - Disk Metrics
public struct DiskMetrics: Sendable {
    public var totalBytes: UInt64 = 0
    public var freeBytes: UInt64 = 0
    public var usedBytes: UInt64 = 0
    public var usedPercentage: Double = 0.0
    public var readBytesPerSec: Double = 0.0
    public var writeBytesPerSec: Double = 0.0
    public var mountPath: String = "/"
    
    public init() {}
    
    public var totalFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
    }
    
    public var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(usedBytes), countStyle: .file)
    }
    
    public var freeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(freeBytes), countStyle: .file)
    }
    
    public var readRateFormatted: String {
        "\(ByteCountFormatter.string(fromByteCount: Int64(readBytesPerSec), countStyle: .file))/s"
    }
    
    public var writeRateFormatted: String {
        "\(ByteCountFormatter.string(fromByteCount: Int64(writeBytesPerSec), countStyle: .file))/s"
    }
}

// MARK: - Network Metrics
public struct NetworkMetrics: Sendable {
    public var bytesInPerSec: Double = 0.0
    public var bytesOutPerSec: Double = 0.0
    public var totalBytesIn: UInt64 = 0
    public var totalBytesOut: UInt64 = 0
    public var primaryInterface: String = "en0"
    
    public init() {}
    
    public var downloadRateFormatted: String {
        "\(ByteCountFormatter.string(fromByteCount: Int64(bytesInPerSec), countStyle: .file))/s"
    }
    
    public var uploadRateFormatted: String {
        "\(ByteCountFormatter.string(fromByteCount: Int64(bytesOutPerSec), countStyle: .file))/s"
    }
}

// MARK: - Battery Metrics
public struct BatteryMetrics: Sendable {
    public var hasBattery: Bool = false
    public var percentage: Double = 100.0
    public var isCharging: Bool = false
    public var isPluggedIn: Bool = true
    public var timeRemainingMinutes: Int = -1
    public var health: String = "Good"
    
    public init() {}
}
