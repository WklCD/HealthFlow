import Foundation

final class ExportService {
    func exportCSV(workouts: [WorkoutRecord]) throws -> String {
        let headers = "exerciseType,duration,calories,startTime"
        if workouts.isEmpty {
            return headers
        }
        return headers + "\n" + workouts.map { workout in
            let exerciseType = workout.exerciseType.contains(",") ? "\"\(workout.exerciseType)\"" : workout.exerciseType
            return "\(exerciseType),\(workout.duration),\(workout.calories),\(workout.startTime.timeIntervalSince1970)"
        }.joined(separator: "\n")
    }

    func exportCSV(sleeps: [SleepRecord]) throws -> String {
        let headers = "quality,duration,startTime,endTime"
        if sleeps.isEmpty {
            return headers
        }
        return headers + "\n" + sleeps.map { sleep in
            "\(sleep.quality),\(sleep.duration),\(sleep.startTime.timeIntervalSince1970),\(sleep.endTime.timeIntervalSince1970)"
        }.joined(separator: "\n")
    }

    func exportCSV(metrics: [PhysiologicalMetric]) throws -> String {
        let headers = "metricType,value,unit,timestamp"
        if metrics.isEmpty {
            return headers
        }
        return headers + "\n" + metrics.map { metric in
            "\(metric.metricType),\(metric.value),\(metric.unit),\(metric.timestamp.timeIntervalSince1970)"
        }.joined(separator: "\n")
    }

    func exportCSV(diets: [DietRecord]) throws -> String {
        let headers = "mealType,totalCalories,totalProtein,totalCarbs,totalFat,timestamp"
        if diets.isEmpty {
            return headers
        }
        return headers + "\n" + diets.map { diet in
            let mealType = diet.mealType.contains(",") ? "\"\(diet.mealType)\"" : diet.mealType
            return "\(mealType),\(diet.totalCalories),\(diet.totalProtein),\(diet.totalCarbs),\(diet.totalFat),\(diet.timestamp.timeIntervalSince1970)"
        }.joined(separator: "\n")
    }

    func exportCSV(medications: [MedicationRecord]) throws -> String {
        let headers = "name,dosage,scheduledTime,takenAt"
        if medications.isEmpty {
            return headers
        }
        return headers + "\n" + medications.map { med in
            let name = med.name.contains(",") ? "\"\(med.name)\"" : med.name
            let takenAt = med.takenAt?.timeIntervalSince1970.description ?? ""
            return "\(name),\(med.dosage),\(med.scheduledTime.timeIntervalSince1970),\(takenAt)"
        }.joined(separator: "\n")
    }

    func exportToFile(data: String, filename: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        try data.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}