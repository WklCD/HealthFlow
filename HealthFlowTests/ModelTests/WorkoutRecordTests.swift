import Testing
import Foundation
@testable import HealthFlow

struct WorkoutRecordTests {

    @Test("默认 source 为 manual")
    func testDefaultSource() {
        let record = WorkoutRecord()
        #expect(record.source == "manual")
    }

    @Test("duration 默认值为 0")
    func testDefaultDuration() {
        let record = WorkoutRecord()
        #expect(record.duration == 0)
    }

    @Test("可选字段默认为 nil")
    func testOptionalDefaults() {
        let record = WorkoutRecord()
        #expect(record.healthKitUUID == nil)
        #expect(record.steps == nil)
        #expect(record.distance == nil)
        #expect(record.heartRateAvg == nil)
        #expect(record.heartRateMax == nil)
        #expect(record.note == nil)
    }
}