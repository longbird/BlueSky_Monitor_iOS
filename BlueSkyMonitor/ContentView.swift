import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MonitoringViewModel(api: LiveMonitoringAPI())
    @StateObject private var tokenStore = TokenStore.shared

    @State private var pendingAction: PBXAction?
    @State private var resultMessage: String = ""
    @State private var showResultAlert = false
    @State private var isPerforming = false
    @State private var isSSHRunning = false
    @State private var showUpdateSheet = false
    @State private var updateVersion = ""

    var body: some View {
        Group {
            if tokenStore.accessToken == nil {
                LoginView()
            } else {
                NavigationView {
                    VStack(spacing: 12) {
                        TextField("센터명 또는 코드 검색", text: $viewModel.centerSearchText)
                            .textFieldStyle(.roundedBorder)
                            .onTapGesture { viewModel.isUserInteracting = true }

                        Picker("센터", selection: $viewModel.selectedCenterId) {
                            ForEach(viewModel.filteredCenters, id: \.centerId) { center in
                                Text(center.centerName).tag(center.centerId)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture { viewModel.isUserInteracting = true }

                        ZStack {
                            if viewModel.items.isEmpty && viewModel.isLoading {
                                ProgressView("불러오는 중...")
                            } else {
                                ScrollView {
                                    if !viewModel.chartSeries.isEmpty {
                                        ChartSection(chartSeries: viewModel.chartSeries)
                                            .padding(.vertical, 4)
                                    }

                                    LazyVStack(spacing: 12) {
                                        ForEach(viewModel.items) { item in
                                            NavigationLink(destination: MonitorDetailView(item: item)) {
                                                MonitorRowView(item: item)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding()

                                    pbxControlSection
                                        .padding(.bottom, 24)
                                }
                            }

                            if let message = viewModel.errorMessage {
                                VStack(spacing: 8) {
                                    Text("오류 발생")
                                        .font(.headline)
                                    Text(message)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Button("다시 시도") {
                                        Task { await viewModel.load() }
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(radius: 6)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .navigationTitle("BlueSky Monitor")
                    .toolbar {
                        Button("로그아웃") {
                            tokenStore.clear()
                        }
                    }
                }
                .task(id: tokenStore.accessToken) {
                    guard tokenStore.accessToken != nil else { return }
                    await viewModel.loadCenters()
                    await viewModel.load()
                    await viewModel.loadCharts()
                    viewModel.startAutoRefresh(intervalSeconds: 3.0)
                }
                .onChange(of: viewModel.selectedCenterId) { _ in
                    viewModel.isUserInteracting = false
                    Task {
                        await viewModel.load()
                        await viewModel.loadCharts()
                    }
                }
                .refreshable {
                    guard tokenStore.accessToken != nil else { return }
                    await viewModel.load()
                    await viewModel.loadCharts()
                }
                .onDisappear {
                    viewModel.stopAutoRefresh()
                }
                .onSubmit(of: .text) {
                    viewModel.isUserInteracting = false
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
                .sheet(isPresented: $showUpdateSheet) {
                    updateSheet
                }
            }
        }
    }

    private var pbxControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PBX 제어")
                .font(.headline)

            if let item = selectedItem {
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
                        actionButton("IP-PBX 설정 리로드") {
                            resultMessage = "IP-PBX 설정 리로드는 추가 프로토콜이 필요합니다."
                            showResultAlert = true
                        }
                        actionButton(isSSHRunning ? "SSH 서비스 중지" : "SSH 서비스 실행") {
                            confirm(isSSHRunning ? .serviceStopSSH : .serviceStartSSH)
                        }
                    }
                }
                .disabled(isPerforming)

                if isPerforming {
                    ProgressView("요청 중...")
                }

                Text("현재 선택 센터: \(item.centerName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("센터를 선택하면 PBX 제어가 활성화됩니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var selectedItem: MonitorSummaryItem? {
        if !viewModel.selectedCenterId.isEmpty {
            return viewModel.items.first { $0.centerId == viewModel.selectedCenterId }
        }
        return viewModel.items.first
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

    private func perform(_ action: PBXAction) async {
        guard let item = selectedItem else { return }

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

#Preview {
    ContentView()
}
