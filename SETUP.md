# Akanuke iOS MVP セットアップ

## フォルダ構成
```
AkanukeApp.swift
ContentView.swift
Models/
  RecordModels.swift
Stores/
  SettingsStore.swift
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
   - `GENERATE_INFOPLIST_FILE = YES`（デフォルトでオン）。本リポジトリには `Info.plist` を同梱し、`NSCameraUsageDescription` を定義済みです。
5. **Info / Permissions**
   - `NSCameraUsageDescription`（同梱の `Info.plist` に設定済み）
     - 文言: `毎日の顔写真（前・横）を記録して変化を確認するためにカメラを使用します。`
   - （必要に応じてのみ）`NSPhotoLibraryUsageDescription` と `NSPhotoLibraryAddUsageDescription` を追加。

## ファイル追加手順
1. 上記フォルダ構成で Swift ファイルを追加。
2. 既存の `AkanukeApp.swift` と `ContentView.swift` を置き換え（本リポジトリの内容をコピー）。
3. 実機ビルドしてカメラ権限ダイアログを確認。

## データ保存仕様
- 画像保存先: `Application Support/AkanukeLog/records/YYYY-MM-DD/`。
  - `front.jpg`
  - `side_right.jpg` または `side_left.jpg`
- メタデータ: `Application Support/AkanukeLog/records.json`（Codable）。
- 設定: `UserDefaults` に `captureMode`, `sideOrientation`, `aspectMode` を保存。

## 画面概要
- Home: 今日の進捗表示、撮影開始、直近記録のサムネ。
- Capture: 前/横の撮影・プレビュー・保存（UIImagePickerControllerラップ）。
- Calendar: 月表示、撮影済み日をマーク、タップで日別詳細。
- Day Detail: 前/横表示と比較ビュー（任意日付と並べて比較）。
- Settings: 撮影モード・横向き・表示比率を変更。

## 表示比率
- 保存はオリジナル。
- 表示のみ `original` / `4:5` を切り替え（クロップは表示時のみ）。
