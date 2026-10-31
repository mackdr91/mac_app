import Foundation

public enum CommandCategory: String, Sendable, CaseIterable {
    case network = "NETWORK"
    case developer = "DEVELOPER"
    case system = "SYSTEM"
    case security = "SECURITY"
}

public struct ScriptCommand: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let category: CommandCategory
    public let shellCommand: String
    public let requiresSudo: Bool
    public let iconName: String
    public let parameterPlaceholder: String?
    
    public init(
        id: String,
        title: String,
        description: String,
        category: CommandCategory,
        shellCommand: String,
        requiresSudo: Bool = false,
        iconName: String,
        parameterPlaceholder: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.shellCommand = shellCommand
        self.requiresSudo = requiresSudo
        self.iconName = iconName
        self.parameterPlaceholder = parameterPlaceholder
    }
}

public struct CommandLogEntry: Identifiable, Sendable {
    public let id = UUID()
    public let timestamp: Date
    public let command: String
    public let output: String
    public let isError: Bool
    public let exitCode: Int32
    public let duration: Double
    
    public var timestampFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}

public extension ScriptCommand {
    static let presets: [ScriptCommand] = [
        ScriptCommand(
            id: "flush-dns",
            title: "Flush DNS Cache",
            description: "Clears local DNS cache and restarts mDNSResponder daemon",
            category: .network,
            shellCommand: "dscacheutil -flushcache && sudo killall -HUP mDNSResponder && echo 'DNS Cache Flushed Successfully'",
            requiresSudo: true,
            iconName: "network"
        ),
        ScriptCommand(
            id: "port-buster",
            title: "Port Buster / Inspector",
            description: "Finds processes bound to a given TCP/UDP port and displays their PIDs",
            category: .network,
            shellCommand: "lsof -i :%@ || echo 'No active listener on port %@'",
            requiresSudo: false,
            iconName: "bolt.horizontal",
            parameterPlaceholder: "e.g. 3000, 8080"
        ),
        ScriptCommand(
            id: "docker-prune",
            title: "Docker System Prune",
            description: "Reclaims disk space by removing unused containers, networks, and dangling images",
            category: .developer,
            shellCommand: "docker system prune -f 2>&1 || echo 'Docker daemon not running or not found'",
            requiresSudo: false,
            iconName: "shippingbox"
        ),
        ScriptCommand(
            id: "clean-xcode",
            title: "Purge Xcode DerivedData",
            description: "Removes accumulated DerivedData build caches to fix build anomalies and free GBs",
            category: .developer,
            shellCommand: "rm -rf ~/Library/Developer/Xcode/DerivedData/* && echo 'DerivedData Purged Successfully'",
            requiresSudo: false,
            iconName: "hammer"
        ),
        ScriptCommand(
            id: "brew-cleanup",
            title: "Homebrew Cleanup",
            description: "Removes stale lock files and outdated downloads for all formulae and casks",
            category: .developer,
            shellCommand: "brew cleanup -s 2>&1 || echo 'Homebrew cleanup finished'",
            requiresSudo: false,
            iconName: "mug"
        ),
        ScriptCommand(
            id: "purge-memory",
            title: "Purge System Memory",
            description: "Forces macOS to flush disk caches and inactive memory blocks",
            category: .system,
            shellCommand: "sudo purge && echo 'Memory Purge Complete'",
            requiresSudo: true,
            iconName: "memorychip"
        ),
        ScriptCommand(
            id: "active-connections",
            title: "Active TCP Sockets",
            description: "Lists all currently established network connections and remote hosts",
            category: .network,
            shellCommand: "netstat -an -f inet | grep ESTABLISHED | head -n 30",
            requiresSudo: false,
            iconName: "antenna.radiowaves.left.and.right"
        ),
        ScriptCommand(
            id: "listen-ports",
            title: "Listening Ports",
            description: "Scans all open TCP listeners on localhost and wildcard interfaces",
            category: .security,
            shellCommand: "lsof -iTCP -sTCP:LISTEN -n -P",
            requiresSudo: false,
            iconName: "lock.shield"
        )
    ]
}
