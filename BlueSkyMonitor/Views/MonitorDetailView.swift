import SwiftUI
import UIKit

struct MonitorDetailView: View {
    let item: MonitorSummaryItem
    @StateObject private var viewModel: MonitoringDetailViewModel

    @State private var pendingAction: PBXAction?
    @State private var resultMessage: String = ""
    @State private var showResultAlert = false
    @State private var isPerforming = false
    @State private var isSSHRunning = false
    @State private var showChartLog = false
    @State private var showUpdateSheet = false
    @State private var updateVersion = ""

    init(item: MonitorSummaryItem) {
        self.item = item
        _viewModel = StateObject(wrappedValue: MonitoringDetailViewModel(centerId: item.centerId))
    }

    var body: some View {
        List {
            Section(header: Text("PBX 제어")) {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        actionButton("서버 종료") { confirm(.shutdown) }
                        actionButton("서버 재시작") { confirm(.reboot) }
                    }
                    HStack(spacing: 8) {
                        actionButton("IP-PBX 업데이트") { showUpdateSheet = true }
                        actionButton("IP-PBX 재시작") { confirm(.restartIPPBX) }
                    }
                    HStack(spacing: 8) {
                        actionButton("IP-PBX 설정 리로드") { showUnsupported("IP-PBX 설정 리로드는 추가 프로토콜이 필요합니다.") }
                        actionButton(isSSHRunning ? "SSH 서비스 중지" : "SSH 서비스 실행") {
                            confirm(isSSHRunning ? .serviceStopSSH : .serviceStartSSH)
                        }
                    }
                    HStack(spacing: 8) {
                        actionButton("차트 검색") { showChartLog = true }
                        actionButton("IP-PBX 설치") { showUnsupported("IP-PBX 설치는 SSH 기반 자동 설치로 별도 구현이 필요합니다.") }
                    }
                    HStack(spacing: 8) {
                        actionButton("복사") { copyIp() }
                        Spacer(minLength: 0)
                    }
                }
                .disabled(isPerforming)

                if isPerforming {
                    ProgressView("요청 중...")
                }
            }

            Section(header: Text("센터 요약")) {
                HStack {
                    Text("상태")
                    Spacer()
                    StatusBadge(status: item.status)
                }
                HStack {
                    Text("IP-PBX")
                    Spacer()
                    Text("\(item.ipPbxIp):\(item.ipPbxPort)")
                        .foregroundColor(.secondary)
                }
                HStack {
                    MetricView(title: "CPU", value: String(format: "%.1f%%", item.sysCpu))
                    MetricView(title: "MEM", value: String(format: "%.1f%%", item.sysMem))
                    MetricView(title: "DISK", value: String(format: "%.1f%%", item.storageUsedPercent))
                }
            }

            Section(header: Text("이력 (상세)")) {
                if viewModel.isLoading {
                    ProgressView("불러오는 중...")
                }
                ForEach(viewModel.records) { record in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SEQ #\(record.seq)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            MetricView(title: "CPU", value: String(format: "%.1f%%", record.cpu))
                            MetricView(title: "MEM", value: String(format: "%.1f%%", record.mem))
                            MetricView(title: "DISK", value: String(format: "%.1f%%", record.disk))
                        }
                        HStack {
                            MetricView(title: "RX", value: ByteFormatter.format(record.rxBytes))
                            MetricView(title: "TX", value: ByteFormatter.format(record.txBytes))
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle(item.centerName)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .confirmationDialog(pendingAction?.title ?? "", isPresented: Binding(get: {
            pendingAction != nil
        }, set: { value in
            if !value { pendingAction = nil }
        })) {
            Button("확인") {
                guard let action = pendingAction else { return }
                Task { await perform(action) }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text(pendingAction?.message ?? "")
        }
        .alert("알림", isPresented: $showResultAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(resultMessage)
        }
        .sheet(isPresented: $showChartLog) {
            ChartLogView(centerId: item.centerId)
        }
        .sheet(isPresented: $showUpdateSheet) {
            updateSheet
        }
    }

    private var updateSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("업데이트 버전")) {
                    TextField("버전 번호", text: $updateVersion)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("IP-PBX 업데이트")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { showUpdateSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("실행") {
                        let trimmed = updateVersion.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard let version = Int(trimmed) else {
                            resultMessage = "버전 번호를 확인해주세요."
                            showResultAlert = true
                            return
                        }
                        showUpdateSheet = false
                        confirm(.update(version: version))
                    }
                }
            }
        }
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
    }

    private func confirm(_ command: PBXCommand) {
        pendingAction = PBXAction(title: command.title, message: command.message, command: command)
    }

    private func showUnsupported(_ message: String) {
        resultMessage = message
        showResultAlert = true
    }

    private func copyIp() {
        UIPasteboard.general.string = item.ipPbxIp
        resultMessage = "IP-PBX IP가 복사되었습니다."
        showResultAlert = true
    }

    private func perform(_ action: PBXAction) async {
        isPerforming = true
        defer { isPerforming = false }

        do {
            let ok = try await PBXCommandClient.sendCommand(
                ip: item.ipPbxIp,
                callCenterCd: item.centerId,
                command: action.command.cmdValue
            )

            if ok {
                resultMessage = action.command.successMessage
                if action.command == .serviceStartSSH { isSSHRunning = true }
                if action.command == .serviceStopSSH { isSSHRunning = false }
            } else {
                resultMessage = action.command.failMessage
            }
        } catch {
            resultMessage = "요청에 실패했습니다."
        }
        showResultAlert = true
    }
}

private struct PBXAction {
    let title: String
    let message: String
    let command: PBXCommand
}

private enum PBXCommand: Equatable {
    case shutdown
    case reboot
    case update(version: Int)
    case restartIPPBX
    case serviceStartSSH
    case serviceStopSSH

    var title: String {
        switch self {
        case .shutdown: return "서버 종료"
        case .reboot: return "서버 재시작"
        case .update: return "IP-PBX 업데이트"
        case .restartIPPBX: return "IP-PBX 재시작"
        case .serviceStartSSH: return "SSH 서비스 실행"
        case .serviceStopSSH: return "SSH 서비스 중지"
        }
    }

    var message: String {
        switch self {
        case .shutdown: return "서버를 종료하시겠습니까?"
        case .reboot: return "서버를 재시작하시겠습니까?"
        case .update: return "IP-PBX를 업데이트하시겠습니까?"
        case .restartIPPBX: return "IP-PBX를 재시작하시겠습니까?"
        case .serviceStartSSH: return "SSH 서비스를 시작하겠습니까?"
        case .serviceStopSSH: return "SSH 서비스를 중지하겠습니까?"
        }
    }

    var cmdValue: String {
        switch self {
        case .shutdown: return "shutdown"
        case .reboot: return "reboot"
        case .update(let version): return "update_\(version)"
        case .restartIPPBX: return "restart_ippbx"
        case .serviceStartSSH: return "service_start_ssh"
        case .serviceStopSSH: return "service_stop_ssh"
        }
    }

    var successMessage: String {
        switch self {
        case .shutdown: return "서버가 종료되었습니다."
        case .reboot: return "서버가 재시작됩니다."
        case .update: return "IP-PBX가 업데이트됩니다."
        case .restartIPPBX: return "IP-PBX가 재시작됩니다."
        case .serviceStartSSH: return "SSH 서비스를 시작되었습니다."
        case .serviceStopSSH: return "SSH 서비스를 중지되었습니다."
        }
    }

    var failMessage: String {
        switch self {
        case .shutdown: return "서버종료가 실패하였습니다."
        case .reboot: return "서버 재시작이 실패하였습니다."
        case .update: return "IP-PBX 업데이트에 실패하였습니다."
        case .restartIPPBX: return "IP-PBX 재시작이 실패하였습니다."
        case .serviceStartSSH: return "SSH 서비스를 시작이 실패되었습니다."
        case .serviceStopSSH: return "SSH 서비스를 중지가 실패되었습니다."
        }
    }
}
