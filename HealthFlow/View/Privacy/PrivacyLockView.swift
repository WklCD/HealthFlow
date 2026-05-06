import SwiftUI

struct PrivacyLockView: View {
    let viewModel: PrivacyLockViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                Text("HealthFlow")
                    .font(.largeTitle.bold())
                Text("轻触以验证身份")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .onTapGesture {
            Task { await viewModel.authenticate() }
        }
        .onAppear {
            Task { await viewModel.authenticate() }
        }
    }
}