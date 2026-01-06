import SwiftUI
import UIKit

struct CalendarView: View {
    @EnvironmentObject var records: RecordsStore

    // ✅ ここに1回だけ置く（structの中）
    @AppStorage("calendar_show_weekdays") private var showWeekdays: Bool = true

    @State private var displayMonth = Date().startOfMonth()

    private let calendar = Calendar.current
    private let imageStore = ImageStore()

    private let gridSpacing: CGFloat = 6
    private let cellRatio: CGFloat = 4.0 / 5.0
    private let corner: CGFloat = 10

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    header
                    monthGrid
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.headline)
            }

            Spacer()

            Text(displayMonth, formatter: monthFormatter)
                .font(.headline)

            Spacer()

            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.headline)
            }

            // 右上：曜日表示トグル（アイコンのみ）
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    showWeekdays.toggle()
                }
            } label: {
                Image(systemName: showWeekdays ? "calendar" : "square.grid.3x3")
                    .font(.headline)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showWeekdays ? "曜日を非表示" : "曜日を表示")
        }
        .padding(.vertical, 4)
    }

    private var monthGrid: some View {
        let days = generateDays()

        // モードで切替
        let isGallery = !showWeekdays
        let columnCount = isGallery ? 3 : 7
        let spacing: CGFloat = isGallery ? 10 : gridSpacing

        return LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: spacing),
                count: columnCount
            ),
            spacing: spacing
        ) {
            // 曜日（カレンダーモードのみ）
            if showWeekdays {
                ForEach(["日","月","火","水","木","金","土"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.75))
                        .frame(maxWidth: .infinity)
                }
            }

            // セル
            ForEach(days) { day in
                if let date = day.date {
                    let thumb = loadThumbnail(for: date)

                    if let thumb {
                        // 写真あり → タップ可
                        NavigationLink(destination: DayDetailView(recordDateString: date.yyyyMMdd)) {
                            DayCellView(
                                dayNumber: day.number,
                                thumbnail: thumb,
                                ratio: cellRatio,
                                corner: corner
                            )
                        }
                        .buttonStyle(.plain)

                    } else if showWeekdays {
                        // カレンダーモードのみ：写真なしセル
                        DayCellView(
                            dayNumber: day.number,
                            thumbnail: nil,
                            ratio: cellRatio,
                            corner: corner
                        )
                        .opacity(0.55)
                        .allowsHitTesting(false)
                    }
                } else if showWeekdays {
                    // 月初の空白（カレンダーモードのみ）
                    Color.clear
                        .aspectRatio(cellRatio, contentMode: .fit)
                }
            }
        }
    }

    // MARK: - Date generation

    private func generateDays() -> [DayCell] {
        let range = calendar.range(of: .day, in: .month, for: displayMonth) ?? 1..<31
        let firstWeekday = calendar.component(.weekday, from: displayMonth)

        var cells: [DayCell] = Array(
            repeating: DayCell(number: 0, date: nil),
            count: max(firstWeekday - 1, 0)
        )

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

    // MARK: - Thumbnail

    private func loadThumbnail(for date: Date) -> UIImage? {
        guard let record = records.record(for: date) else { return nil }

        if let frontPath = record.frontImagePath,
           let image = imageStore.loadImage(at: frontPath) {
            return image
        }

        return nil
    }

    // MARK: - Views

    struct DayCellView: View {
        let dayNumber: Int
        let thumbnail: UIImage?
        let ratio: CGFloat
        let corner: CGFloat

        private let placeholderColor = Color(.tertiarySystemFill)

        var body: some View {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: corner)
                    .fill(placeholderColor)
                    .overlay {
                        if let thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: corner))

                Text("\(dayNumber)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.55)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.85), lineWidth: 1))
                    .padding(4)
            }
            .aspectRatio(ratio, contentMode: .fit)
        }
    }

    struct DayCell: Identifiable {
        let id = UUID()
        let number: Int
        let date: Date?
    }
}
