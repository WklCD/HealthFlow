import SwiftUI
import Charts

struct TodayTrendChart: View {
    let dataPoints: [HourStepData]

    var body: some View {
        Chart(dataPoints) { point in
            AreaMark(
                x: .value("时间", point.hour),
                y: .value("步数", point.steps)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            LineMark(
                x: .value("时间", point.hour),
                y: .value("步数", point.steps)
            )
            .foregroundStyle(Color.orange)
        }
        .frame(height: Constants.UI.chartHeight)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 4)) { _ in
                AxisValueLabel(format: .dateTime.hour())
            }
        }
    }
}

struct HourStepData: Identifiable {
    let id = UUID()
    let hour: Date
    let steps: Int
}