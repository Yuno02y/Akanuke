import Foundation
import SwiftUI

enum CaptureMode: String, CaseIterable, Identifiable, Codable {
    case frontAndSide
    case frontOnly
    case sideOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .frontAndSide: return "前 + 横"
        case .frontOnly: return "前のみ"
        case .sideOnly: return "横のみ"
        }
    }

    var requiresFront: Bool { self != .sideOnly }
    var requiresSide: Bool { self != .frontOnly }
}

enum SideOrientation: String, CaseIterable, Identifiable, Codable {
    case right
    case left

    var id: String { rawValue }

    var title: String {
        switch self {
        case .right: return "横（右向き）"
        case .left: return "横（左向き）"
        }
    }

    var fileComponent: String {
        switch self {
        case .right: return "side_right"
        case .left: return "side_left"
        }
    }
}

enum AspectMode: String, CaseIterable, Identifiable, Codable {
    case original
    case fourByFive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .original: return "オリジナル"
        case .fourByFive: return "4:5"
        }
    }
}

enum PhotoAngle: Codable, Hashable {
    case front
    case side(SideOrientation)

    var fileNameComponent: String {
        switch self {
        case .front: return "front"
        case .side(let orientation): return orientation.fileComponent
        }
    }
}

struct DayRecord: Identifiable, Codable {
    let id: String // YYYY-MM-DD
    var frontImagePath: String?
    var sideImagePath: String?
    var sideOrientation: SideOrientation?

    var hasFront: Bool { frontImagePath != nil }
    var hasSide: Bool { sideImagePath != nil }

    func progress(captureMode: CaptureMode) -> DayProgress {
        let frontDone = hasFront || !captureMode.requiresFront
        let sideDone = hasSide || !captureMode.requiresSide

        if frontDone && sideDone { return .complete }
        if frontDone { return .frontOnly }
        if sideDone { return .sideOnly }
        return .notStarted
    }
}

enum DayProgress: String {
    case notStarted
    case frontOnly
    case sideOnly
    case complete

    var label: String {
        switch self {
        case .notStarted: return "未撮影"
        case .frontOnly: return "前のみ"
        case .sideOnly: return "横のみ"
        case .complete: return "完了"
        }
    }

    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .frontOnly: return .blue
        case .sideOnly: return .orange
        case .complete: return .green
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
