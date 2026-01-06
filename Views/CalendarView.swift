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
        let thumbnail: UIImage?

        private let thumbnailAspectRatio: CGFloat = 4.0 / 5.0 // 固定比率（カレンダー用）
        private let placeholderColor = Color(.tertiarySystemFill) // 単色プレースホルダー

        var body: some View {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(placeholderColor)
                    .aspectRatio(thumbnailAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity, minHeight: 76)
                    .overlay {
                        if let thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                                .aspectRatio(thumbnailAspectRatio, contentMode: .fill)
                                .clipped()
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack {
                    Text("\(dayNumber)")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.4))
                        )
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(thumbnailAspectRatio, contentMode: .fit)
        }
    }

    struct DayCell: Identifiable {
        let id = UUID()
        let number: Int
        let date: Date?
    }
}
