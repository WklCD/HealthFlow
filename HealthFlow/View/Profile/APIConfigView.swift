import SwiftUI

struct APIConfigView: View {
    @State private var endpoint: String = ""
    @State private var apiKey: String = ""
    @State private var modelId: String = ""
    @State private var saved = false
    @State private var validating = false
    @State private var validationMessage: String?

    private let keychainService = KeychainService()

    var body: some View {
        Form {
            Section("API 配置") {
                TextField("Endpoint URL", text: $endpoint)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                TextField("模型 ID（如 deepseek-chat）", text: $modelId)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                SecureField("API Key", text: $apiKey)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            Section {
                Button("保存配置") {
                    saveConfig()
                }
                .disabled(endpoint.isEmpty || apiKey.isEmpty || modelId.isEmpty)

                Button("验证连接") {
                    validateConnection()
                }
                .disabled(endpoint.isEmpty || apiKey.isEmpty || modelId.isEmpty || validating)

                if let message = validationMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(message.contains("成功") ? .green : .red)
                }

                if saved {
                    Text("配置已保存")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Section("说明") {
                Text("支持兼容 OpenAI 格式的国产大模型 API（如智谱、DeepSeek、通义千问等）。\n\nEndpoint 需要包含完整路径，如：https://api.deepseek.com/v1\n\n模型 ID 填写对应模型的标识，如：deepseek-chat、glm-4-flash、qwen-turbo 等")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("API 配置")
        .onAppear { loadConfig() }
    }

    private func loadConfig() {
        if let savedKey = ((try? keychainService.load(key: "healthflow_api_key")) ?? nil),
           let savedEndpoint = ((try? keychainService.load(key: "healthflow_endpoint")) ?? nil),
           let savedModelId = ((try? keychainService.load(key: "healthflow_model_id")) ?? nil) {
            apiKey = savedKey
            endpoint = savedEndpoint
            modelId = savedModelId
        }
    }

    private func saveConfig() {
        do {
            try keychainService.save(key: "healthflow_api_key", value: apiKey)
            try keychainService.save(key: "healthflow_endpoint", value: endpoint)
            try keychainService.save(key: "healthflow_model_id", value: modelId)
            saved = true
            validationMessage = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
        } catch {
            validationMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    private func validateConnection() {
        validating = true
        validationMessage = nil
        let service = AIService()
        service.configure(apiKey: apiKey, endpoint: endpoint, modelId: modelId)

        let context = HealthContext(dateRange: "", totalSteps: 0, totalWorkouts: 0,
            avgSleepHours: 0, avgSleepQuality: 0, avgDietCalories: 0,
            currentWeight: nil, avgHeartRate: nil, bloodPressureSummary: nil)

        Task {
            var received = false
            for await _ in service.sendMessage(prompt: "你好", context: context) {
                received = true
                break
            }
            await MainActor.run {
                validating = false
                validationMessage = received ? "✅ 连接成功" : "❌ 未收到响应，请检查配置"
            }
        }
    }
}