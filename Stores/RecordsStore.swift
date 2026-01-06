import Foundation
import SwiftUI
import Combine

@MainActor
final class RecordsStore: ObservableObject {
    @Published private(set) var records: [String: DayRecord] = [:]
    private let fileURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base.appendingPathComponent("AkanukeLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("records.json")
        load()
    }

    func record(for date: Date) -> DayRecord? {
        records[date.yyyyMMdd]
    }

    func progress(for date: Date) -> DayProgress {
        record(for: date)?.progress() ?? DayProgress.notStarted
    }

    func upsertFront(for date: Date, imagePath: String) {
        var record = records[date.yyyyMMdd] ?? DayRecord(id: date.yyyyMMdd, frontImagePath: nil)
        record.frontImagePath = imagePath
        records[record.id] = record
        save()
    }

    func recentRecords(limit: Int = 7) -> [DayRecord] {
        let sorted = records.values.sorted { $0.id > $1.id }
        return Array(sorted.prefix(limit))
    }

    func allDatesSorted() -> [String] {
        records.keys.sorted()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([String: DayRecord].self, from: data)
            self.records = decoded
        } catch {
            print("Failed to load records: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save records: \(error)")
        }
    }
}
