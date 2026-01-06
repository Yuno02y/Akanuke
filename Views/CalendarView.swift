import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var records: RecordsStore
    @State private var displayMonth = Date().startOfMonth()
    private let calendar = Calendar.current

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
                        VStack {
                            Text("\(day.number)")
                                .frame(maxWidth: .infinity)
                            if let record = records.record(for: date) {
                                Circle()
                                    .fill(record.progress(captureMode: settings.captureMode).color)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(4)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground)))
                    }
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func generateDays() -> [DayCell] {
        let range = calendar.range(of: .day, in: .month, for: displayMonth) ?? 1...30
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

    struct DayCell: Identifiable {
        let id = UUID()
        let number: Int
        let date: Date?
    }
}
