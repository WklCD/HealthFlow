import Testing
import Foundation
@testable import HealthFlow

@Suite(.serialized)
struct PrivacyLockViewModelTests {

    @Test("隐私锁禁用时不需要验证")
    func testNotEnabled() {
        UserDefaults.standard.set(false, forKey: "privacy_lock_enabled")
        let vm = PrivacyLockViewModel()
        #expect(vm.needsAuthentication == false)
    }

    @Test("隐私锁启用时需要验证")
    func testEnabled() {
        UserDefaults.standard.set(true, forKey: "privacy_lock_enabled")
        let vm = PrivacyLockViewModel()
        #expect(vm.needsAuthentication == true)
    }

    @Test("lock() 重置认证状态")
    func testLockResetsState() {
        UserDefaults.standard.set(true, forKey: "privacy_lock_enabled")
        let vm = PrivacyLockViewModel()
        vm.isAuthenticated = true
        vm.showLock = false
        vm.lock()
        #expect(vm.isAuthenticated == false)
        #expect(vm.showLock == true)
    }

    @Test("初始状态：未认证且显示锁屏")
    func testInitialState() {
        let vm = PrivacyLockViewModel()
        #expect(vm.isAuthenticated == false)
        #expect(vm.showLock == true)
    }
}