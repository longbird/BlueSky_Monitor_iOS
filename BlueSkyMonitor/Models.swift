import Foundation

struct MonitorSummaryResponse: Codable {
    let timestamp: Date
    let items: [MonitorSummaryItem]
}

struct MonitorSummaryItem: Codable, Identifiable {
    var id: String { centerId }
    let centerId: String
    let centerName: String
    let connect: Bool
    let sysCpu: Double
    let sysMem: Double
    let storageUsedPercent: Double
    let netRxBytes: Int64
    let netTxBytes: Int64
    let ipPbxIp: String
    let status: MonitorStatus
}

struct MonitorDetailResponse: Codable {
    let centerId: String
    let centerName: String
    let servers: [MonitorServer]
}

struct MonitorServer: Codable, Identifiable {
    var id: String { serverId + host + String(port) }
    let serverId: String
    let host: String
    let port: Int
    let status: MonitorStatus
    let cpu: Double
    let mem: Double
    let disk: Double
    let rxBps: Int64
    let txBps: Int64
    let lastUpdated: Date
}

enum MonitorStatus: String, Codable {
    case good
    case normal
    case bad
    case offline
    case unused
}
