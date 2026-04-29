import Testing
@testable import HealthFlow

struct MetricTypeTests {

    @Test("所有指标类型都有正确的单位")
    func allMetricTypesHaveCorrectUnit() {
        #expect(MetricType.weight.unit == "kg")
        #expect(MetricType.heartRate.unit == "bpm")
        #expect(MetricType.bloodOxygen.unit == "%")
        #expect(MetricType.bodyTemperature.unit == "°C")
        #expect(MetricType.bloodPressure.unit == "mmHg")
        #expect(MetricType.bloodGlucose.unit == "mmol/L")
    }

    @Test("血压类型需要双值")
    func bloodPressureRequiresDualValues() {
        #expect(MetricType.bloodPressure.requiresDualValues == true)
        #expect(MetricType.weight.requiresDualValues == false)
    }

    @Test("所有 displayName 非空")
    func displayNameIsNotEmptyForAllCases() {
        for type in MetricType.allCases {
            #expect(!type.displayName.isEmpty)
        }
    }

    @Test("所有 normalRangeDescription 非空")
    func normalRangeDescriptionIsNotEmptyForAllCases() {
        for type in MetricType.allCases {
            #expect(!type.normalRangeDescription.isEmpty)
        }
    }
}