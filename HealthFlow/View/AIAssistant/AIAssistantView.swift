import SwiftUI
import SwiftData

struct AIAssistantView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AIAssistantViewModel?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let vm = viewModel {
                    MessageListView(vm: vm)
                    InputBarView(vm: vm)
                } else {
                    ProgressView()
                        .padding()
                    Text("加载中...")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("AI 助手")
        }
        .tabItem {
            Label("AI 助手", systemImage: "brain")
        }
        .task {
            let keychainService = KeychainService()
            let aiService = AIService()
            let apiKey = (try? keychainService.load(key: "healthflow_api_key")) ?? nil
            let endpoint = (try? keychainService.load(key: "healthflow_endpoint")) ?? nil
            let modelId = (try? keychainService.load(key: "healthflow_model_id")) ?? nil
            if let apiKey, let endpoint, let modelId {
                aiService.configure(apiKey: apiKey, endpoint: endpoint, modelId: modelId)
            }
            let vm = AIAssistantViewModel(modelContext: modelContext, aiService: aiService)
            viewModel = vm
        }
    }
}

struct MessageListView: View {
    let vm: AIAssistantViewModel

    private var bubbleData: [ChatBubbleData] {
        vm.messages.map { ChatBubbleData(id: $0.id, role: $0.role, content: $0.content) }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if vm.messages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundStyle(.purple)
                        Text("向 AI 助手提问吧")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        QuickPromptView { type in
                            Task { await vm.sendQuickPrompt(type) }
                        }
                    }
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(bubbleData) { data in
                            ChatBubbleView(
                                data: data,
                                isStreaming: vm.isStreaming && data.id == bubbleData.last?.id && data.role == "assistant"
                            )
                            .id(data.id)
                        }
                    }
                    .padding()
                }
            }
            .onChange(of: bubbleData.count) { _, _ in
                if let last = bubbleData.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: vm.isStreaming) { _, isStreaming in
                if !isStreaming, let last = bubbleData.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }
}

struct InputBarView: View {
    let vm: AIAssistantViewModel
    @State private var inputText = ""
    @State private var showClearConfirm = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            if !vm.messages.isEmpty {
                QuickPromptView { type in
                    Task { await vm.sendQuickPrompt(type) }
                }
            }

            HStack(spacing: 12) {
                TextField("输入健康问题...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .focused($isInputFocused)

                Button {
                    let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    inputText = ""
                    isInputFocused = false
                    Task { await vm.sendMessage(text) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(vm.isStreaming ? .gray : .purple)
                }
                .disabled(vm.isStreaming)

                Button {
                    showClearConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
        .confirmationDialog("清除对话", isPresented: $showClearConfirm) {
            Button("清除所有对话记录", role: .destructive) {
                vm.clearConversation()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要清除所有对话记录吗？此操作不可撤销。")
        }
    }
}