import SwiftUI
import UIKit

struct CalendarView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var records: RecordsStore
    @State private var displayMonth = Date().startOfMonth()
    private let calendar = Calendar.current
    private let imageStore = ImageStore()

    var body: some View {
        NavigationStack {
            VStack {
                header
                monthGrid
                Spacer()
            }
            .padding()
            .navigationTitle("カレンダー")
        }
    }

    private var header: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) { Image(systemName: "chevron.left") }
            Spacer()
            Text(displayMonth, formatter: monthFormatter)
                .font(.headline)
            Spacer()
            Button(action: { changeMonth(by: 1) }) { Image(systemName: "chevron.right") }
        }
    }

    private var monthGrid: some View {
        let days = generateDays()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(["日","月","火","水","木","金","土"], id: \.self) { weekday in
                Text(weekday).font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(days) { day in
                if let date = day.date {
                    NavigationLink(destination: DayDetailView(recordDateString: date.yyyyMMdd)) {
                        DayCellView(
                            dayNumber: day.number,
                            progress: records.record(for: date)?.progress(captureMode: settings.captureMode),
                            aspectMode: settings.aspectMode,
                            thumbnail: loadThumbnail(for: date)
                        )
                    }
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func generateDays() -> [DayCell] {
        let range = calendar.range(of: .day, in: .month, for: displayMonth) ?? 1..<31
        let firstWeekday = calendar.component(.weekday, from: displayMonth)
        var cells: [DayCell] = Array(repeating: DayCell(number: 0, date: nil), count: firstWeekday - 1)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: displayMonth) {
                cells.append(DayCell(number: day, date: date))
            }
        }
        return cells
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayMonth) {
            displayMonth = newDate.startOfMonth()
        }
    }

    private var monthFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ja_JP")
        df.dateFormat = "yyyy年MM月"
        return df
    }

    private func loadThumbnail(for date: Date) -> UIImage? {
        guard let record = records.record(for: date) else { return nil }
        if let frontPath = record.frontImagePath, let image = imageStore.loadImage(at: frontPath) {
            return image
        }
        if let sidePath = record.sideImagePath, let image = imageStore.loadImage(at: sidePath) {
            return image
        }
        return nil
    }

    struct DayCellView: View {
        let dayNumber: Int
        let progress: DayProgress?
        let aspectMode: AspectMode
        let thumbnail: UIImage?

        var body: some View {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))

                if let thumbnail {
                    FlexibleImage(image: thumbnail, aspectMode: aspectMode)
                        .aspectRatio(1, contentMode: .fill)
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .clipped()
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(dayNumber)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(.top, 6)
                        .padding(.leading, 6)
                    if let progress {
                        Circle()
                            .fill(progress.color)
                            .frame(width: 8, height: 8)
                            .padding(.leading, 6)
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 76, maxHeight: 90)
        }
    }

    struct DayCell: Identifiable {
        let id = UUID()
        let number: Int
        let date: Date?
    }
}
