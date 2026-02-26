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
                    .navigationTitle("BlueSky Monitor")
                    .toolbar {
                        Button("로그아웃") {
                            tokenStore.clear()
                        }
                    }
                }
                .task {
                    await viewModel.load()
                }
                .refreshable {
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
