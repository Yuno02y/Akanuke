import SwiftUI

struct DayDetailView: View {
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
                        DetailImageView(title: "前", uiImage: image)
                    }
                }
            } else {
                Text("記録がありません")
            }

            if let baseImage = baseImageForComparison() {
                Section("比較") {
                    CompareView(baseDate: recordDateString, baseImage: baseImage)
                }
            }
        }
        .navigationTitle(recordDateString)
    }

    private func baseImageForComparison() -> UIImage? {
        guard let record = records.records[recordDateString] else { return nil }
        if let frontPath = record.frontImagePath, let image = imageStore.loadImage(at: frontPath) { return image }
        return nil
    }
}

struct DetailImageView: View {
    let title: String
    let uiImage: UIImage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).bold()
            FlexibleImage(image: uiImage)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.vertical, 4)
    }
}

struct CompareView: View {
    @EnvironmentObject var records: RecordsStore
    let baseDate: String
    let baseImage: UIImage
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
                VStack { Text(baseDate).font(.headline); FlexibleImage(image: baseImage) }
                if let compareDate, let compareImage = imageFor(dateString: compareDate) {
                    VStack { Text(compareDate).font(.headline); FlexibleImage(image: compareImage) }
                }
            }
        }
    }

    private func imageFor(dateString: String) -> UIImage? {
        guard let record = records.records[dateString] else { return nil }
        if let path = record.frontImagePath, let image = imageStore.loadImage(at: path) { return image }
        return nil
    }
}

struct FlexibleImage: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
    }
}
