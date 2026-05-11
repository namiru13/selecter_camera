# selecter_camera ⛷️📸

スキー滑走の撮影に特化した、**滑走者自動検出機能付き・サムネイル自動埋め込みカメラアプリケーション**です。

スキーヤーが滑走する動画を撮影し、LINEやその他のメッセンジャーアプリで送信した際に、自動的に「滑走者の名前と姿」がベストショットの状態でサムネイル表示されるように動画を加工・保存します。

---

## 🌟 主な機能

1. **滑走者の事前登録 (Skier Registration)**
   * 滑走者の「名前」と当日の「ウェア姿（写真）」を登録します。
   * 登録時に画像から自動でウェアの色特徴量ヒストグラム（HSV色空間）を抽出し、比較データとして保存します。

2. **撮影中のリアルタイム滑走者提案 (Real-time Skier Matching)**
   * 撮影中、ImageStreamからフレームを間引き、端末内AIで人物（Person）を検出します。
   * 検出された人物領域のウェア色ヒストグラムを、事前登録されたデータとコサイン類似度でリアルタイムに照合します。
   * 類似度が一定の閾値を超えた場合、「滑走者は〇〇さんですか？」というフローティングボタンで提案を行います。

3. **物理サムネイルの埋め込み (FFmpeg Video Processing)**
   * LINE等で送信した際に、メタデータに依存しない「動画の物理的な1フレーム目」にベストショット画像と名前をテキスト描画した静止画（0.1秒のイントロ動画）をFFmpegで結合します。
   * **加工フロー:**
     * ベストショット静止画に「名前」を描画し `thumbnail.jpg` を生成。
     * 静止画を 0.1秒 の動画 `intro.mp4` に変換。
     * `intro.mp4` + 撮影した動画を物理的に結合し、`final_output.mp4` として出力。

4. **撮影補助・カメラ安定化 (Camera Stabilization & Leveler)**
   * ジャイロおよび加速度センサーと連携し、ゲレンデでの傾きを補正するための水準器ガイドラインを画面に表示します。

---

## 🛠️ 技術スタック

* **Framework:** Flutter (Dart)
* **State Management:** Flutter Riverpod (`flutter_riverpod`)
* **Camera:** `camera` package
* **Video Player:** `video_player`
* **Video Editing & Synthesis:** `ffmpeg_kit_flutter_new` (FFmpeg Kit)
* **Storage & Saving:** `path_provider`, `gal` (アルバム保存)
* **Sensors:** `sensors_plus`, `native_device_orientation`
* **Utilities:** `uuid`, `equatable`

---

## 🚀 セットアップと実行方法

### 📋 前提条件

* **Flutter SDK:** `>=3.8.1 <4.0.0`
* **Android SDK:** `minSdkVersion: 24`, `targetSdkVersion: 34`
* **iOS:** `iOS 13.0` 以上

### ⚙️ 導入手順

1. **リポジトリのクローン:**
   ```bash
   git clone https://github.com/namiru13/selecter_camera.git
   cd selecter_camera
   ```

2. **依存パッケージの取得:**
   ```bash
   flutter pub get
   ```

3. **アプリケーションの実行:**
   ```bash
   flutter run
   ```

---

## 📱 必要なパーミッション（権限）の設定

アプリケーションを動作させるために、以下の権限が必要です。

### Android
* `android.permission.CAMERA`（カメラ撮影用）
* `android.permission.RECORD_AUDIO`（動画の音声配信用）
* `android.permission.WRITE_EXTERNAL_STORAGE` / `READ_MEDIA_VIDEO`（メディア保存用）

### iOS (`Info.plist`)
* `NSCameraUsageDescription`（カメラ撮影用）
* `NSMicrophoneUsageDescription`（音声付き動画の撮影用）
* `NSPhotoLibraryUsageDescription`（アルバムからのウェア登録写真読み込み、動画プレビュー用）
* `NSPhotoLibraryAddUsageDescription`（撮影した加工済み動画のアルバム保存用）

---

## ⚖️ ライセンス

このプロジェクトは **Apache License 2.0** のもとで公開されています。詳細については [LICENSE](LICENSE) ファイルをご参照ください。
