import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var records: RecordsStore
    let recordDateString: String
    private let imageStore = ImageStore()

    private var recordDate: Date? {
        DateFormatter.yyyyMMdd.date(from: recordDateString)
    }

    var body: some View {
        List {
            if let record = records.records[recordDateString] {
                Section("写真") {
                    if let path = record.frontImagePath, let image = imageStore.loadImage(at: path) {
                        DetailImageView(title: "前", uiImage: image, aspectMode: settings.aspectMode)
                    }
                    if let path = record.sideImagePath, let image = imageStore.loadImage(at: path) {
                        let title = record.sideOrientation == .left ? "横（左）" : "横（右）"
                        DetailImageView(title: title, uiImage: image, aspectMode: settings.aspectMode)
                    }
                }
            } else {
                Text("記録がありません")
            }

            if let baseImage = baseImageForComparison() {
                Section("比較") {
                    CompareView(baseDate: recordDateString, baseImage: baseImage, aspectMode: settings.aspectMode)
                }
            }
        }
        .navigationTitle(recordDateString)
    }

    private func baseImageForComparison() -> UIImage? {
        guard let record = records.records[recordDateString] else { return nil }
        if let frontPath = record.frontImagePath, let image = imageStore.loadImage(at: frontPath) { return image }
        if let sidePath = record.sideImagePath, let image = imageStore.loadImage(at: sidePath) { return image }
        return nil
    }
}

struct DetailImageView: View {
    let title: String
    let uiImage: UIImage
    let aspectMode: AspectMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).bold()
            FlexibleImage(image: uiImage, aspectMode: aspectMode)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.vertical, 4)
    }
}

struct CompareView: View {
    @EnvironmentObject var records: RecordsStore
    let baseDate: String
    let baseImage: UIImage
    let aspectMode: AspectMode
    @State private var compareDate: String?
    private let imageStore = ImageStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("比較日", selection: Binding(get: {
                compareDate ?? baseDate
            }, set: { compareDate = $0 })) {
                ForEach(records.allDatesSorted(), id: \.self) { date in
                    Text(date).tag(date)
                }
            }
            .pickerStyle(.menu)

            HStack(alignment: .top) {
                VStack { Text(baseDate).font(.headline); FlexibleImage(image: baseImage, aspectMode: aspectMode) }
                if let compareDate, let compareImage = imageFor(dateString: compareDate) {
                    VStack { Text(compareDate).font(.headline); FlexibleImage(image: compareImage, aspectMode: aspectMode) }
                }
            }
        }
    }

    private func imageFor(dateString: String) -> UIImage? {
        guard let record = records.records[dateString] else { return nil }
        if let path = record.frontImagePath, let image = imageStore.loadImage(at: path) { return image }
        if let path = record.sideImagePath, let image = imageStore.loadImage(at: path) { return image }
        return nil
    }
}

struct FlexibleImage: View {
    let image: UIImage
    let aspectMode: AspectMode

    var body: some View {
        let base = Image(uiImage: image)
            .resizable()
            .scaledToFill()
        return Group {
            if aspectMode == .fourByFive {
                base
                    .aspectRatio(4.0/5.0, contentMode: .fit)
                    .clipped()
            } else {
                base.scaledToFit()
            }
        }
    }
}
