import Foundation
import SwiftUI
import LocalAuthentication

@Observable
final class PrivacyLockViewModel {
    var isAuthenticated = false
    var showLock = true

    var needsAuthentication: Bool {
        UserDefaults.standard.bool(forKey: "privacy_lock_enabled")
    }

    func authenticate() async {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isAuthenticated = true
            return
        }
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "验证身份以查看您的健康数据"
            )
            await MainActor.run {
                isAuthenticated = result
                if result { showLock = false }
            }
        } catch {
            isAuthenticated = false
        }
    }

    func lock() {
        showLock = true
        isAuthenticated = false
    }
}