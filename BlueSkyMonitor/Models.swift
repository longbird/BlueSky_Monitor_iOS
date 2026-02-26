import Foundation

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
    let timestamp: Date?
}

struct MonitorSummaryData: Codable {
    let timestamp: Date
    let items: [MonitorSummaryItem]
}

struct CenterInfo: Codable {
    let centerId: String
    let centerName: String
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
    let ipPbxPort: Int
    let status: MonitorStatus
}

struct MonitorDetailData: Codable {
    let centerId: String
    let records: [MonitorDetailRecord]
}

struct ChartResponseData: Codable {
    let metric: String
    let points: [ChartPoint]
}

struct ChartPoint: Codable {
    let t: Date
    let v: Double
}

struct MonitorDetailRecord: Codable, Identifiable {
    var id: Int { seq }
    let seq: Int
    let centerId: String
    let cpu: Double
    let mem: Double
    let disk: Double
    let rxBytes: Int64
    let txBytes: Int64
}

enum MonitorStatus: String, Codable {
    case good
    case normal
    case bad
    case offline
    case unused
}
