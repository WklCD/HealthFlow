import SwiftUI
import SwiftData

struct ChatBubbleData: Identifiable, Equatable {
    let id: PersistentIdentifier
    let role: String
    let content: String
}

struct ChatBubbleView: View {
    let data: ChatBubbleData
    let isStreaming: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if data.role == "assistant" {
                assistantAvatar
                bubbleContent
                Spacer(minLength: 50)
            } else {
                Spacer(minLength: 50)
                bubbleContent
                userAvatar
            }
        }
    }

    private var assistantAvatar: some View {
        Image(systemName: "brain.head.profile")
            .foregroundStyle(.purple)
            .font(.title2)
    }

    private var userAvatar: some View {
        Image(systemName: "person.circle.fill")
            .foregroundStyle(.blue)
            .font(.title2)
    }

    private var bubbleContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(data.role == "user" ? "你" : "AI 助手")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            HStack(spacing: 0) {
                Text(data.content)
                    .font(.body)
                if isStreaming {
                    BlinkingCursor()
                }
            }
        }
        .padding(12)
        .background(data.role == "user" ? Color.blue.opacity(0.1) : Color.purple.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: 280, alignment: .leading)
    }
}

struct BlinkingCursor: View {
    @State private var visible = true

    var body: some View {
        Text("│")
            .foregroundStyle(.purple)
            .opacity(visible ? 1 : 0)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: visible)
            .onAppear { visible.toggle() }
    }
}