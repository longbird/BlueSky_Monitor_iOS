import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var didAutoLogin = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("BlueSky Monitor")
                    .font(.largeTitle)
                    .bold()

                TextField("관리자 ID", text: $viewModel.mgrId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                SecureField("비밀번호", text: $viewModel.mgrPwd)
                    .textFieldStyle(.roundedBorder)

                if let message = viewModel.errorMessage {
                    Text(message)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button {
                    Task { await viewModel.login() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("로그인")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("로그인")
            .task {
                guard !didAutoLogin else { return }
                didAutoLogin = true
                TokenStore.shared.clear()
                viewModel.mgrId = "testadmin"
                viewModel.mgrPwd = "1234"
                await viewModel.login()
            }
        }
    }
}
