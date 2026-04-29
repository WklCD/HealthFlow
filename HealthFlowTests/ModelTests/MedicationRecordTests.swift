import Testing
import Foundation
@testable import HealthFlow

struct MedicationRecordTests {

    @Test("takenAt 默认为 nil")
    func testTakenAtDefaultsNil() {
        let record = MedicationRecord()
        #expect(record.takenAt == nil)
    }

    @Test("source 默认为 manual")
    func testDefaultSource() {
        let record = MedicationRecord()
        #expect(record.source == "manual")
    }

    @Test("note 字段可读写")
    func testNoteField() {
        let record = MedicationRecord()
        record.note = "饭后服用"
        #expect(record.note == "饭后服用")
    }

    @Test("name 和 dosage 默认为空")
    func testNameAndDosageDefaults() {
        let record = MedicationRecord()
        #expect(record.name == "")
        #expect(record.dosage == "")
    }
}