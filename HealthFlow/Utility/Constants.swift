import Foundation

enum Constants {
    enum HealthKit {
        static let syncDaysBack = 7
    }

    enum Alert {
        static let defaultSleepMinimumHours: Double = 6
        static let defaultHeartRateMin: Double = 50
        static let defaultHeartRateMax: Double = 100
        static let defaultWeightChangePercentThreshold: Double = 5
        static let defaultSedentaryDays: Int = 7
        static let alertRepeatWindowDays: Int = 7
    }

    enum UI {
        static let statCardHeight: CGFloat = 80
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let chartHeight: CGFloat = 200
    }

    enum Storage {
        static let foodImagesDirectory = "FoodImages"
        static let maxImageDimension: CGFloat = 1024
    }
}