import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MonitoringViewModel(api: LiveMonitoringAPI())
    @StateObject private var tokenStore = TokenStore.shared

    @State private var didForceLogin = false

    var body: some View {
        Group {
            if tokenStore.accessToken == nil {
                LoginView()
            } else {
                NavigationView {
                    VStack(spacing: 12) {
                        TextField("센터명 또는 코드 검색", text: $viewModel.centerSearchText)
                            .textFieldStyle(.roundedBorder)

                        Picker("센터", selection: $viewModel.selectedCenterId) {
                            ForEach(viewModel.filteredCenters, id: \.centerId) { center in
                                Text(center.centerName).tag(center.centerId)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        ZStack {
                            if viewModel.items.isEmpty && viewModel.isLoading {
                                ProgressView("불러오는 중...")
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(viewModel.items) { item in
                                            NavigationLink(destination: MonitorDetailView(item: item)) {
                                                MonitorRowView(item: item)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding()
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
                }
                .onChange(of: viewModel.selectedCenterId) { _ in
                    Task { await viewModel.load() }
                }
                .refreshable {
                    guard tokenStore.accessToken != nil else { return }
                    await viewModel.load()
                }
            }
        }
        .task {
            guard !didForceLogin else { return }
            didForceLogin = true
            tokenStore.clear()
        }
    }
}

#Preview {
    ContentView()
}
