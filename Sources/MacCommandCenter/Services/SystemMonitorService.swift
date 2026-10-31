import Foundation
import SwiftUI
import Combine
import IOKit.ps
import Darwin

@Observable
public final class SystemMonitorService: @unchecked Sendable {
    public static let shared = SystemMonitorService()
    
    // MARK: - Current Metrics
    public var cpu: CPUMetrics = CPUMetrics()
    public var memory: MemoryMetrics = MemoryMetrics()
    public var disk: DiskMetrics = DiskMetrics()
    public var network: NetworkMetrics = NetworkMetrics()
    public var battery: BatteryMetrics = BatteryMetrics()
    
    // MARK: - Telemetry History (for Sparklines)
    public var cpuHistory: [Double] = Array(repeating: 0.0, count: 40)
    public var memoryHistory: [Double] = Array(repeating: 0.0, count: 40)
    public var netInHistory: [Double] = Array(repeating: 0.0, count: 40)
    public var netOutHistory: [Double] = Array(repeating: 0.0, count: 40)
    
    // MARK: - Internal Sampling State
    private var timer: Timer?
    private var previousCPULoad: [processor_cpu_load_info]?
    private var previousNetIn: UInt64 = 0
    private var previousNetOut: UInt64 = 0
    private var previousSampleTime: Date = Date()
    private let sampleInterval: TimeInterval = 1.0
    
    private init() {
        initHardwareInfo()
        updateAllMetrics()
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    public func startMonitoring() {
        stopMonitoring()
        timer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
            self?.updateAllMetrics()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Update Metrics Cycle
    public func updateAllMetrics() {
        let now = Date()
        let elapsed = max(now.timeIntervalSince(previousSampleTime), 0.1)
        previousSampleTime = now
        
        updateCPUMetrics()
        updateMemoryMetrics()
        updateDiskMetrics()
        updateNetworkMetrics(elapsed: elapsed)
        updateBatteryMetrics()
        
        // Append to history buffers
        cpuHistory.append(cpu.overallUsage)
        if cpuHistory.count > 40 { cpuHistory.removeFirst() }
        
        memoryHistory.append(memory.usedPercentage)
        if memoryHistory.count > 40 { memoryHistory.removeFirst() }
        
        netInHistory.append(network.bytesInPerSec / 1024.0) // KB/s
        if netInHistory.count > 40 { netInHistory.removeFirst() }
        
        netOutHistory.append(network.bytesOutPerSec / 1024.0) // KB/s
        if netOutHistory.count > 40 { netOutHistory.removeFirst() }
    }
    
    // MARK: - Hardware Static Info
    private func initHardwareInfo() {
        // Physical and logical core count
        var ncpu: Int32 = 0
        var size = MemoryLayout<Int32>.size
        if sysctlbyname("hw.physicalcpu", &ncpu, &size, nil, 0) == 0 {
            cpu.physicalCores = Int(ncpu)
        }
        if sysctlbyname("hw.logicalcpu", &ncpu, &size, nil, 0) == 0 {
            cpu.logicalCores = Int(ncpu)
        }
        
        // Model brand string
        var brandSize: Int = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &brandSize, nil, 0)
        if brandSize > 0 {
            var brandChars = [CChar](repeating: 0, count: brandSize)
            sysctlbyname("machdep.cpu.brand_string", &brandChars, &brandSize, nil, 0)
            let brand = brandChars.withUnsafeBufferPointer { ptr in
                ptr.baseAddress != nil ? String(cString: ptr.baseAddress!) : ""
            }.trimmingCharacters(in: .whitespacesAndNewlines)
            if !brand.isEmpty {
                cpu.modelName = brand
            }
        } else {
            // Check Apple Silicon chip name
            var modelSize: Int = 0
            sysctlbyname("hw.model", nil, &modelSize, nil, 0)
            if modelSize > 0 {
                var modelChars = [CChar](repeating: 0, count: modelSize)
                sysctlbyname("hw.model", &modelChars, &modelSize, nil, 0)
                let model = modelChars.withUnsafeBufferPointer { ptr in
                    ptr.baseAddress != nil ? String(cString: ptr.baseAddress!) : ""
                }
                if !model.isEmpty {
                    cpu.modelName = model
                }
            }
        }
        
        // Total RAM
        var memSize: UInt64 = 0
        var memVarSize = MemoryLayout<UInt64>.size
        if sysctlbyname("hw.memsize", &memSize, &memVarSize, nil, 0) == 0 {
            memory.totalBytes = memSize
        }
    }
    
    // MARK: - CPU Sampling via Mach Kernel
    private func updateCPUMetrics() {
        var processorCount: natural_t = 0
        var processorInfo: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        
        let hostPort = mach_host_self()
        let result = host_processor_info(
            hostPort,
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &processorInfo,
            &infoCount
        )
        
        guard result == KERN_SUCCESS, let info = processorInfo else { return }
        
        let cpuLoadInfo = info.withMemoryRebound(to: processor_cpu_load_info.self, capacity: Int(processorCount)) { pointer in
            Array(UnsafeBufferPointer(start: pointer, count: Int(processorCount)))
        }
        
        // Deallocate mach memory
        let deallocSize = vm_size_t(infoCount * mach_msg_type_number_t(MemoryLayout<integer_t>.size))
        vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: info)), deallocSize)
        
        guard let prev = previousCPULoad, prev.count == cpuLoadInfo.count else {
            previousCPULoad = cpuLoadInfo
            return
        }
        
        var totalUserTicks: UInt32 = 0
        var totalSystemTicks: UInt32 = 0
        var totalIdleTicks: UInt32 = 0
        var totalNiceTicks: UInt32 = 0
        var perCoreUsages: [Double] = []
        
        for i in 0..<cpuLoadInfo.count {
            let user = cpuLoadInfo[i].cpu_ticks.0 - prev[i].cpu_ticks.0
            let system = cpuLoadInfo[i].cpu_ticks.1 - prev[i].cpu_ticks.1
            let idle = cpuLoadInfo[i].cpu_ticks.2 - prev[i].cpu_ticks.2
            let nice = cpuLoadInfo[i].cpu_ticks.3 - prev[i].cpu_ticks.3
            
            let coreTotal = user + system + idle + nice
            if coreTotal > 0 {
                let coreActive = user + system + nice
                let corePct = (Double(coreActive) / Double(coreTotal)) * 100.0
                perCoreUsages.append(min(max(corePct, 0.0), 100.0))
            } else {
                perCoreUsages.append(0.0)
            }
            
            totalUserTicks += user
            totalSystemTicks += system
            totalIdleTicks += idle
            totalNiceTicks += nice
        }
        
        let totalTicks = totalUserTicks + totalSystemTicks + totalIdleTicks + totalNiceTicks
        if totalTicks > 0 {
            let active = totalUserTicks + totalSystemTicks + totalNiceTicks
            cpu.overallUsage = (Double(active) / Double(totalTicks)) * 100.0
            cpu.userPercentage = (Double(totalUserTicks) / Double(totalTicks)) * 100.0
            cpu.systemPercentage = (Double(totalSystemTicks) / Double(totalTicks)) * 100.0
            cpu.idlePercentage = (Double(totalIdleTicks) / Double(totalTicks)) * 100.0
        }
        cpu.coreUsages = perCoreUsages
        previousCPULoad = cpuLoadInfo
    }
    
    // MARK: - Memory Sampling via Mach Host Statistics
    private func updateMemoryMetrics() {
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64()
        
        let hostPort = mach_host_self()
        let result = withUnsafeMutablePointer(to: &vmStats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { integerPointer in
                host_statistics64(hostPort, HOST_VM_INFO64, integerPointer, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return }
        
        let pageSize = UInt64(getpagesize())
        let active = UInt64(vmStats.active_count) * pageSize
        let wired = UInt64(vmStats.wire_count) * pageSize
        let compressed = UInt64(vmStats.compressor_page_count) * pageSize
        let free = UInt64(vmStats.free_count) * pageSize
        let purgeable = UInt64(vmStats.purgeable_count) * pageSize
        
        memory.activeBytes = active
        memory.wiredBytes = wired
        memory.compressedBytes = compressed
        memory.freeBytes = free + purgeable
        memory.appMemoryBytes = active + UInt64(vmStats.inactive_count) * pageSize
        
        let used = active + wired + compressed
        if memory.totalBytes > 0 {
            memory.usedPercentage = min(max((Double(used) / Double(memory.totalBytes)) * 100.0, 0.0), 100.0)
            if memory.usedPercentage > 85.0 {
                memory.pressureLevel = .critical
            } else if memory.usedPercentage > 70.0 {
                memory.pressureLevel = .warning
            } else {
                memory.pressureLevel = .normal
            }
        }
    }
    
    // MARK: - Disk Metrics via statfs
    private func updateDiskMetrics() {
        var stat = statfs()
        if statfs("/", &stat) == 0 {
            let blockSize = UInt64(stat.f_bsize)
            let total = UInt64(stat.f_blocks) * blockSize
            let free = UInt64(stat.f_bavail) * blockSize
            let used = total > free ? total - free : 0
            
            disk.totalBytes = total
            disk.freeBytes = free
            disk.usedBytes = used
            if total > 0 {
                disk.usedPercentage = (Double(used) / Double(total)) * 100.0
            }
        }
    }
    
    // MARK: - Network Throughput via getifaddrs
    private func updateNetworkMetrics(elapsed: TimeInterval) {
        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0, let first = ifap else { return }
        defer { freeifaddrs(ifap) }
        
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let current = ptr {
            let flags = Int32(current.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0
            
            if isUp && !isLoopback, let data = current.pointee.ifa_data {
                let ifData = data.assumingMemoryBound(to: if_data.self)
                totalIn += UInt64(ifData.pointee.ifi_ibytes)
                totalOut += UInt64(ifData.pointee.ifi_obytes)
            }
            ptr = current.pointee.ifa_next
        }
        
        network.totalBytesIn = totalIn
        network.totalBytesOut = totalOut
        
        if previousNetIn > 0 && totalIn >= previousNetIn && elapsed > 0 {
            network.bytesInPerSec = Double(totalIn - previousNetIn) / elapsed
        }
        if previousNetOut > 0 && totalOut >= previousNetOut && elapsed > 0 {
            network.bytesOutPerSec = Double(totalOut - previousNetOut) / elapsed
        }
        
        previousNetIn = totalIn
        previousNetOut = totalOut
    }
    
    // MARK: - Battery & Power via IOKit
    private func updateBatteryMetrics() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let firstSource = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, firstSource)?.takeUnretainedValue() as? [String: Any] else {
            battery.hasBattery = false
            return
        }
        
        battery.hasBattery = true
        if let current = desc[kIOPSCurrentCapacityKey] as? Int,
           let maxCap = desc[kIOPSMaxCapacityKey] as? Int, maxCap > 0 {
            battery.percentage = (Double(current) / Double(maxCap)) * 100.0
        }
        
        if let isCharging = desc[kIOPSIsChargingKey] as? Bool {
            battery.isCharging = isCharging
        }
        
        if let timeToEmpty = desc[kIOPSTimeToEmptyKey] as? Int {
            battery.timeRemainingMinutes = timeToEmpty
        }
    }
}
