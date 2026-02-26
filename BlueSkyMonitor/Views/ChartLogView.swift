import SwiftUI

struct ChartLogView: View {
    let centerId: String
    @StateObject private var viewModel: MonitoringChartViewModel

    init(centerId: String) {
        self.centerId = centerId
        _viewModel = StateObject(wrappedValue: MonitoringChartViewModel(centerId: centerId, minutes: 30))
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("불러오는 중...")
                        .padding(.top, 24)
                }

                if !viewModel.chartSeries.isEmpty {
                    ChartSection(chartSeries: viewModel.chartSeries)
                        .padding(.top, 8)
                } else if !viewModel.isLoading {
                    Text("차트 데이터가 없습니다.")
                        .foregroundColor(.secondary)
                        .padding(.top, 24)
                }

                Spacer()
            }
            .navigationTitle("차트 검색")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
}
