# Akanuke iOS MVP セットアップ

## フォルダ構成
```
AkanukeApp.swift
ContentView.swift
Models/
  RecordModels.swift
Stores/
  RecordsStore.swift
  ImageStore.swift
Views/
  HomeView.swift
  CalendarView.swift
  DayDetailView.swift
  SettingsView.swift
  Components/ThumbnailView.swift
  Capture/
    CaptureFlowView.swift
```

## Xcode プロジェクト作成と設定
1. Xcodeで新規 SwiftUI App を作成（Product Name: `Akanuke`）。
2. Deployment Target を iOS 18.0 以上に設定（例: 18.0）。
3. **Signing & Capabilities**
   - Automatically manage signing を ON。
   - Team に Personal Team を選択。
4. **Build Settings**
   - `GENERATE_INFOPLIST_FILE = YES`（デフォルトでオン）。プロジェクトで自動生成される Info.plist を使用し、手動で追記してください。
5. **Info / Permissions（必ず設定してください）**
   - `NSCameraUsageDescription`
     - 文言例: `毎日の顔写真（前）を記録して変化を確認するためにカメラを使用します。`
   - （必要に応じてのみ）`NSPhotoLibraryUsageDescription` と `NSPhotoLibraryAddUsageDescription` を追加。

## ファイル追加手順
1. 上記フォルダ構成で Swift ファイルを追加。
2. 既存の `AkanukeApp.swift` と `ContentView.swift` を置き換え（本リポジトリの内容をコピー）。
3. 実機ビルドしてカメラ権限ダイアログを確認。

## データ保存仕様
- 画像保存先: `Application Support/AkanukeLog/records/YYYY-MM-DD/`。
  - `front.jpg`
- メタデータ: `Application Support/AkanukeLog/records.json`（Codable）。
- 設定: 撮影・表示のカスタマイズ項目は廃止し、前面撮影のみ・表示比率はオリジナル固定です。

## 画面概要
- Home: 今日の進捗表示、撮影開始、直近記録のサムネ。
- Capture: 前のみ撮影・プレビュー・保存（UIImagePickerControllerラップ）。
- Calendar: 月表示、撮影済み日をマーク、タップで日別詳細。
- Day Detail: 前写真の表示と比較ビュー（任意日付と並べて比較）。
- Settings: 仕様説明と保存先の案内（設定変更項目なし）。

## 表示比率
- 保存/表示ともにオリジナル固定。
