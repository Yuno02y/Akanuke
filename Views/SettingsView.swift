import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("撮影") {
                Text("撮影は「前」のみ、表示比率はオリジナル固定です。")
                    .font(.subheadline)
            }

            Section("データ保存") {
                Text("画像は Application Support/AkanukeLog/records 配下に front.jpg として保存し、records.json でメタデータを管理します。")
                    .font(.footnote)
            }
        }
        .navigationTitle("設定")
    }
}
