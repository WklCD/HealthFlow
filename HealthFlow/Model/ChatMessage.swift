import Foundation
import SwiftData

@Model
final class ChatMessage {
    var role: String = ""
    var content: String = ""
    var timestamp: Date = Date()
    var promptType: String?

    init(role: String = "", content: String = "", timestamp: Date = Date(), promptType: String? = nil) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.promptType = promptType
    }
}