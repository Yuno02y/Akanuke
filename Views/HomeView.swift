import SwiftUI

struct HomeView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var records: RecordsStore
    @State private var showCapture = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            List {
                Section("今日の進捗") {
                    let todayProgress = records.progress(for: Date(), captureMode: settings.captureMode)
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
                            DailyRecordRow(record: record, aspectMode: settings.aspectMode)
                        }
                    }
                }
            }
            .navigationTitle("Akanuke")
            .sheet(isPresented: $showCapture) {
                CaptureFlowView()
                    .environmentObject(settings)
                    .environmentObject(records)
            }
        }
    }

    private func progressIcon(for progress: DayProgress) -> String {
        switch progress {
        case .notStarted: return "circle"
        case .frontOnly, .sideOnly: return "clock"
        case .complete: return "checkmark.circle.fill"
        }
    }
}

struct DailyRecordRow: View {
    let record: DayRecord
    let aspectMode: AspectMode
    let imageStore = ImageStore()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let frontPath = record.frontImagePath, let image = imageStore.loadImage(at: frontPath) {
                ThumbnailView(image: image, aspectMode: aspectMode)
            }
            if let sidePath = record.sideImagePath, let image = imageStore.loadImage(at: sidePath) {
                ThumbnailView(image: image, aspectMode: aspectMode)
            }
            VStack(alignment: .leading) {
                Text(record.id)
                    .font(.headline)
                Text(progressText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var progressText: String {
        switch (record.hasFront, record.hasSide) {
        case (true, true): return "前・横 撮影済み"
        case (true, false): return "前のみ"
        case (false, true): return "横のみ"
        default: return "未撮影"
        }
    }
}
