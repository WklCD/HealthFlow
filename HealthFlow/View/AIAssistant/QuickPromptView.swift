import SwiftUI

struct QuickPromptView: View {
    let onSelect: (QuickPromptType) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(QuickPromptType.allCases, id: \.rawValue) { type in
                    Button(type.displayName) { onSelect(type) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.purple)
                }
            }
            .padding(.horizontal)
        }
    }
}