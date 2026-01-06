import SwiftUI

struct HomeView: View {
    @EnvironmentObject var records: RecordsStore
    @State private var showCapture = false

    var body: some View {
        NavigationStack {
            List {
                Section("今日の進捗") {
                    let todayProgress = records.progress(for: Date())
                    HStack {
                        Label(todayProgress.label, systemImage: progressIcon(for: todayProgress))
                            .foregroundStyle(todayProgress.color)
                        Spacer()
                        Text(Date(), style: .date)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(action: { showCapture = true }) {
                        Label("撮影する", systemImage: "camera")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }

                Section("直近の記録") {
                    ForEach(records.recentRecords()) { record in
                        NavigationLink(destination: DayDetailView(recordDateString: record.id)) {
                            DailyRecordRow(record: record)
                        }
                    }
                }
            }
            .navigationTitle("Akanuke")
            .sheet(isPresented: $showCapture) {
                CaptureFlowView()
                    .environmentObject(records)
            }
        }
    }

    private func progressIcon(for progress: DayProgress) -> String {
        switch progress {
        case .notStarted: return "circle"
        case .captured: return "checkmark.circle.fill"
        }
    }
}

struct DailyRecordRow: View {
    let record: DayRecord
    let imageStore = ImageStore()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let frontPath = record.frontImagePath, let image = imageStore.loadImage(at: frontPath) {
                ThumbnailView(image: image)
            }
            VStack(alignment: .leading) {
                Text(record.id)
                    .font(.headline)
                Text(record.hasFront ? "前 撮影済み" : "未撮影")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
