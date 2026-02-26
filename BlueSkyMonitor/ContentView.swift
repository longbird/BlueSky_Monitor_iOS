import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("BlueSky Monitor")
                    .font(.title)
                    .bold()
                Text("모니터링 앱 초기 화면")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }
}

#Preview {
    ContentView()
}
