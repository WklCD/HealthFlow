import Testing
import Foundation
import SwiftData
@testable import HealthFlow

@MainActor
struct ProfileViewModelTests {

    @Test("加载时无 UserProfile 则自动创建")
    func testAutoCreateWhenEmpty() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, configurations: config)
        let viewModel = ProfileViewModel(modelContext: container.mainContext)

        viewModel.loadProfile()

        #expect(viewModel.profile != nil)
        #expect(viewModel.profile?.gender == "unset")
    }

    @Test("更新后保存生效")
    func testSaveUpdatesProfile() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, configurations: config)
        let viewModel = ProfileViewModel(modelContext: container.mainContext)
        viewModel.loadProfile()

        viewModel.saveProfile(
            name: "测试用户",
            gender: "male",
            birthDate: Calendar.current.date(byAdding: .year, value: -25, to: Date())!,
            height: 175,
            targetWeight: 70,
            targetSteps: 10000,
            targetSleepHours: 8,
            targetCalories: 2000
        )

        #expect(viewModel.profile?.name == "测试用户")
        #expect(viewModel.profile?.gender == "male")
        #expect(viewModel.profile?.height == 175)
        #expect(viewModel.profile?.targetSteps == 10000)
    }

    @Test("加载已有 UserProfile 时不重复创建")
    func testLoadExistingDoesNotDuplicate() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, configurations: config)
        let viewModel = ProfileViewModel(modelContext: container.mainContext)
        viewModel.loadProfile()
        let firstCount = try container.mainContext.fetch(FetchDescriptor<UserProfile>()).count
        #expect(firstCount == 1)

        viewModel.loadProfile()
        let secondCount = try container.mainContext.fetch(FetchDescriptor<UserProfile>()).count
        #expect(secondCount == 1)
    }
}