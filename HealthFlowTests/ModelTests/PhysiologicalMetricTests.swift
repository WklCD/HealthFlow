import Testing
import Foundation
@testable import HealthFlow

struct PhysiologicalMetricTests {

    @Test("非血压类型 valueSystolic 和 valueDiastolic 为 nil")
    func testNonBloodPressureDualValuesNil() {
        let metric = PhysiologicalMetric()
        metric.metricType = "weight"
        #expect(metric.valueSystolic == nil)
        #expect(metric.valueDiastolic == nil)
    }

    @Test("measurementGroupID 默认为 nil")
    func testDefaultMeasurementGroupID() {
        let metric = PhysiologicalMetric()
        #expect(metric.measurementGroupID == nil)
    }

    @Test("source 默认为 manual")
    func testDefaultSource() {
        let metric = PhysiologicalMetric()
        #expect(metric.source == "manual")
    }

    @Test("value 默认值为 0")
    func testDefaultValue() {
        let metric = PhysiologicalMetric()
        #expect(metric.value == 0)
    }

    @Test("healthKitUUID 默认为 nil")
    func testHealthKitUUIDDefaultsToNil() {
        let metric = PhysiologicalMetric()
        #expect(metric.healthKitUUID == nil)
    }
}