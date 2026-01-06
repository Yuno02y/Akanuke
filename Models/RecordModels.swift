import Foundation
import SwiftUI

struct DayRecord: Identifiable, Codable {
    let id: String // YYYY-MM-DD
    var frontImagePath: String?

    var hasFront: Bool { frontImagePath != nil }

    func progress() -> DayProgress {
        hasFront ? .captured : .notStarted
    }
}

enum DayProgress: String {
    case notStarted
    case captured

    var label: String {
        switch self {
        case .notStarted: return "未撮影"
        case .captured: return "前のみ"
        }
    }

    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .captured: return .blue
        }
    }
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "ja_JP")
        return df
    }()
}

extension Date {
    var yyyyMMdd: String {
        DateFormatter.yyyyMMdd.string(from: self)
    }

    func startOfMonth(using calendar: Calendar = .current) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: comps) ?? self
    }
}
