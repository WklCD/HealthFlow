import SwiftUI
import SwiftData

struct AIAssistantView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AIAssistantViewModel?
    @State private var inputText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let vm = viewModel {
                    messageListView(vm: vm)
                    inputBar(vm: vm)
                } else {
                    loadingView
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

    private func messageListView(vm: AIAssistantViewModel) -> some View {
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
                        ForEach(vm.messages, id: \.timestamp) { message in
                            ChatBubbleView(
                                message: message,
                                isStreaming: vm.isStreaming && message == vm.messages.last && message.role == "assistant"
                            )
                            .id(message.timestamp)
                        }
                    }
                    .padding()
                }
            }
            .onChange(of: vm.messages.count) { _, _ in
                if let last = vm.messages.last {
                    withAnimation { proxy.scrollTo(last.timestamp, anchor: .bottom) }
                }
            }
            .onChange(of: vm.isStreaming) { _, isStreaming in
                if !isStreaming, let last = vm.messages.last {
                    withAnimation { proxy.scrollTo(last.timestamp, anchor: .bottom) }
                }
            }
        }
    }

    private func inputBar(vm: AIAssistantViewModel) -> some View {
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

                Button {
                    let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    inputText = ""
                    Task { await vm.sendMessage(text) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(vm.isStreaming ? .gray : .purple)
                }
                .disabled(vm.isStreaming)

                Menu {
                    Button("清除对话", role: .destructive) {
                        vm.clearConversation()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private var loadingView: some View {
        VStack {
            ProgressView()
                .padding()
            Text("加载中...")
                .foregroundStyle(.secondary)
        }
    }
}