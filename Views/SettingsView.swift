import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        Form {
            Section("撮影モード") {
                Picker("", selection: $settings.captureMode) {
                    ForEach(CaptureMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("横向き") {
                Picker("", selection: $settings.sideOrientation) {
                    ForEach(SideOrientation.allCases) { orientation in
                        Text(orientation.title).tag(orientation)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("表示比率") {
                Picker("", selection: $settings.aspectMode) {
                    ForEach(AspectMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("データ保存")) {
                Text("画像はApplication Support/AkanukeLog配下に保存します。records.jsonでメタデータを管理します。")
                    .font(.footnote)
            }
        }
        .navigationTitle("設定")
    }
}
