# Mac Command & Control Center (CyberDeck HUD)

A high-performance native macOS Command & Control Center built in Swift and SwiftUI. Featuring a **High-Tech Dark HUD** visual aesthetic, real-time hardware telemetry, process management with kill-switch controls, and an interactive developer script/terminal action deck.

## Features

- **Hybrid macOS Architecture**:
  - **Menu Bar Extra**: Persistent status bar item with mini CPU/RAM sparkline and quick-kill popover.
  - **Main HUD Dashboard**: Multi-pane native macOS window with glassmorphism, neon telemetry gauges, and log consoles.
- **Hardware Telemetry Monitor**:
  - Per-core CPU load and activity breakdown via Mach kernel APIs (`host_processor_info`).
  - Physical and virtual memory distribution (active, wired, compressed, cached) via `vm_statistics64`.
  - Disk I/O throughput and storage allocation.
  - Network I/O throughput and interface metrics.
  - Battery health and power draw readouts.
- **Process Commander (Task Manager)**:
  - Live process table sortable by CPU, Memory, PID, and User.
  - Quick Kill (`SIGTERM`) and Force Kill (`SIGKILL`) controls.
  - Detailed process inspect sheet.
- **Command Deck & Terminal Runner**:
  - Preset system and developer actions (DNS Flush, Port Buster, Docker Prune, DerivedData cleanup).
  - Live streaming terminal log viewer with monospace execution traces.

## Tech Stack

- **Platform**: macOS 14.0+ (Sonoma / Sequoia)
- **Language**: Swift 6.0 / Swift 5.9+
- **Framework**: SwiftUI, AppKit integration, Swift Concurrency (`@Observable`, `async/await`)
- **System Bridges**: Mach Kernel subsystem, `libproc`, `sysctl`, `Process`/`Pipe`

## License

MIT
