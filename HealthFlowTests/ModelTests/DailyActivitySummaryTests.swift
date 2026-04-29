import Testing
import Foundation
@testable import HealthFlow

struct DailyActivitySummaryTests {

    @Test("默认 source 为 healthkit")
    func testDefaultSource() {
        let summary = DailyActivitySummary()
        #expect(summary.source == "healthkit")
    }

    @Test("healthKitUUID 默认为 nil")
    func testHealthKitUUIDDefaultsToNil() {
        let summary = DailyActivitySummary()
        #expect(summary.healthKitUUID == nil)
    }

    @Test("所有数值字段默认值为 0")
    func testNumericDefaults() {
        let summary = DailyActivitySummary()
        #expect(summary.steps == 0)
        #expect(summary.calories == 0)
        #expect(summary.distance == 0)
    }

    @Test("standHours 默认为 nil")
    func testStandHoursDefaultsToNil() {
        let summary = DailyActivitySummary()
        #expect(summary.standHours == nil)
    }
}