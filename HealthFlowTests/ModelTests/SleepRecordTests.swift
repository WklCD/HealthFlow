import Testing
import Foundation
@testable import HealthFlow

struct SleepRecordTests {

    @Test("默认值正确")
    func testDefaults() {
        let record = SleepRecord()
        #expect(record.quality == 0)
        #expect(record.duration == 0)
        #expect(record.source == "manual")
        #expect(record.note == nil)
        #expect(record.healthKitUUID == nil)
        #expect(record.deepSleep == nil)
        #expect(record.remSleep == nil)
    }
}