import Testing
import Foundation
@testable import HealthFlow

struct ExportServiceTests {

    @Test("CSV 导出包含正确表头和数据")
    func testCSVExportWorkouts() throws {
        let service = ExportService()
        let workout = WorkoutRecord()
        workout.exerciseType = "running"
        workout.duration = 1800
        workout.calories = 300
        workout.startTime = Date(timeIntervalSince1970: 0)

        let csv = try service.exportCSV(workouts: [workout])
        #expect(csv.contains("exerciseType,duration,calories,startTime"))
        #expect(csv.contains("running"))
        #expect(csv.contains("1800"))
        #expect(csv.contains("300"))
    }

    @Test("空数据集导出为空 CSV（仅表头）")
    func testEmptyCSVExport() throws {
        let service = ExportService()
        let csv = try service.exportCSV(workouts: [])
        #expect(csv.contains("exerciseType"))
    }

    @Test("exportToFile 创建文件并返回 URL")
    func testExportToFile() throws {
        let service = ExportService()
        let csv = "hello,test\n1,2"
        let url = try service.exportToFile(data: csv, filename: "test_export.csv")
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content == csv)
        try? FileManager.default.removeItem(at: url)
    }
}