# スクリプト・自動化ツール分析
日付: 2026/10/06 14:52 JST

## 📋 スクリプト一覧

### 1. ルート直下の .bat（Docker起動用）

| ファイル | 用途 | 実行環境 |
|----------|------|---------|
| **start-all-docker.bat** | Docker 全サービス起動 | Windows |
| **start-backend.bat** | バックエンドのみ起動 | Windows |
| **start-frontend-dev.bat** | フロントエンド開発環境起動 | Windows |
| **stop-all-docker.bat** | Docker 全サービス停止 | Windows |

**用途**: ローカル開発環境の起動・停止

---

### 2. ルート直下の .ps1（テスト用）

| ファイル | 用途 | 実行環境 |
|----------|------|---------|
| **test_backup.ps1** | バックアップ機能のテスト | Windows PowerShell |
| **test_restore.ps1** | リストア機能のテスト | Windows PowerShell |

**用途**: Windows でのバックアップ・リストア動作確認

---

### 3. backend/ の .ps1（管理・初期化用）

| ファイル | 用途 | 実行環境 | 本番対応 |
|----------|------|---------|---------|
| **load_card_master.ps1** | カードマスターデータ読み込み | Windows | ✅ 本番で使用可能 |
| **make.ps1** | ビルド・コンパイル補助 | Windows | ⚠️ 開発用 |
| **Makefile.ps1** | Make コマンドの互換スクリプト | Windows | ⚠️ 開発用 |
| **reset_database.ps1** | DBリセット（開発用） | Windows | ❌ 開発のみ |
| **restore_from_prod.ps1** | 本番からのリストア | Windows | ✅ 本番対応 |
| **restore_media_local.ps1** | メディアローカルリストア | Windows | ⚠️ 開発用 |
| **verify_media_restore.ps1** | メディア復元確認 | Windows | ⚠️ 開発用 |

**用途**: Django アプリケーション管理・初期化

---

### 4. scripts/ の .sh（実運用用）

#### バックアップ関連
| ファイル | 用途 | 実行環境 | 本番対応 |
|----------|------|---------|---------|
| **backup_nightly.sh** | ナイトリーバックアップ | Linux/Unix | ✅ 本番で使用中 |
| **backup_database.sh** | DBバックアップ | Linux/Unix | ✅ 本番で使用中 |
| **backup_media_from_prod.sh** | メディアバックアップ | Linux/Unix | ✅ 本番で使用中 |
| **backup_retention.sh** | バックアップ保持管理 | Linux/Unix | ✅ 本番で使用中 |
| **backup_volumes.sh** | Volumeバックアップ | Linux/Unix | ✅ 本番で使用中 |
| **backup_volumes_incremental.sh** | 増分バックアップ | Linux/Unix | ✅ 本番で使用中 |

#### リストア・デプロイ関連
| ファイル | 用途 | 実行環境 | 本番対応 |
|----------|------|---------|---------|
| **restore_backup.sh** | バックアップからのリストア | Linux/Unix | ✅ 本番で使用中 |
| **deploy.sh** | 本番へのデプロイ | Linux/Unix | ✅ 本番で使用中 |
| **send_backup_notification.sh** | バックアップ完了通知 | Linux/Unix | ✅ 本番で使用中 |
| **_inspect_static.sh** | スタティック検査 | Linux/Unix | ⚠️ 開発用 |

**用途**: 本番環境での定期バックアップ・復元・デプロイ

---

## 🎯 あなたの質問への回答

> 実際にバックアップするときに使うのはまた別のところにあるんよね？

### ✅ その通りです！

#### 開発環境（Windows）で使うもの
```
C:\github\toybox\
├── test_backup.ps1        ← テスト用（Windows）
├── test_restore.ps1       ← テスト用（Windows）
└── backend/
    ├── reset_database.ps1 ← 開発用（DB リセット）
    └── restore_from_prod.ps1 ← 本番データのインポート
```

#### 本番環境（Linux サーバー）で使う（実運用）
```
toyboxssh.ayatori-inc.co.jp
~/toybox/scripts/
├── backup_nightly.sh              ← 毎晩自動実行
├── backup_database.sh             ← DBバックアップ
├── backup_media_from_prod.sh      ← メディアバックアップ
├── backup_retention.sh            ← 保持管理
├── backup_volumes.sh              ← Volume バックアップ
├── restore_backup.sh              ← 災害時の復元
├── deploy.sh                      ← デプロイメント
└── send_backup_notification.sh    ← 通知送信
```

---

## 📊 スクリプトの役割分布

```
┌──────────────────────────────────────────────────────────┐
│                     スクリプト・ツール体系                │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  📍 ローカル開発環境（Windows）                            │
│     •.bat      : Docker 起動・停止                       │
│     •.ps1      : テスト・初期化・データ復元              │
│                                                            │
│  📍 本番環境（Linux サーバー）                             │
│     •.sh       : 定期バックアップ（cron自動実行）        │
│     •.sh       : 災害復旧・デプロイメント               │
│                                                            │
│  📍 バックアップストレージ                                │
│     •20260930/ : 手動バックアップ（静的）               │
│     •本番側    : 定期バックアップ（自動）               │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

---

## 🔄 バックアップフロー

### 本番環境での自動バックアップフロー

```
毎日 00:00
    ↓
[backup_nightly.sh が実行]
    ↓
[backup_database.sh]
[backup_media_from_prod.sh]
[backup_volumes.sh]
    ↓
[backup_retention.sh で保持期間チェック]
    ↓
[send_backup_notification.sh で通知送信]
    ↓
バックアップ完了ログ記録
```

### 災害時のリストアフロー

```
障害検知
    ↓
[restore_backup.sh 実行]
    ↓
バックアップから復元
    ↓
[deploy.sh で本番へデプロイ]
    ↓
サービス復旧
```

---

## ⚙️ 現在の状態

### 開発環境（ローカル）
✅ Docker 起動スクリプト（.bat）は整理済み
✅ テスト・初期化スクリプト（.ps1）は整理対象
⚠️ `backend/` の .ps1 は mixed（開発用 + 本番対応）

### 本番環境
✅ `scripts/` の .sh は全て本番で使用中
✅ 定期バックアップ稼働中（cron スケジュール）
✅ 実際のバックアップは本番サーバー側で管理

---

## 📋 推奨される整理方針

### すぐにやるべき（フェーズ 1）
1. **ルート直下の .bat は `scripts/` に移動**
   ```
   start-all-docker.bat → scripts/dev/start-all-docker.bat
   start-backend.bat    → scripts/dev/start-backend.bat
   start-frontend-dev.bat → scripts/dev/start-frontend-dev.bat
   stop-all-docker.bat  → scripts/dev/stop-all-docker.bat
   ```

2. **ルート直下の .ps1 は `backend/scripts/` に移動**
   ```
   test_backup.ps1  → backend/scripts/test_backup.ps1
   test_restore.ps1 → backend/scripts/test_restore.ps1
   ```

3. **backend/ の .ps1 を分類**
   ```
   開発用:
   • reset_database.ps1
   • restore_media_local.ps1
   • verify_media_restore.ps1
   • make.ps1
   • Makefile.ps1
   
   本番対応:
   • load_card_master.ps1
   • restore_from_prod.ps1
   ```

### 本番環境移行後（フェーズ 2）
1. **scripts/ の .sh を本番サーバーで確認**
2. **cron 設定の確認**
3. **バックアップ自動化の検証**

---

## 📁 推奨される構成（整理後）

```
toybox/
├── scripts/
│   ├── README.md
│   ├── backup/                  ← 本番バックアップスクリプト
│   │   ├── backup_nightly.sh
│   │   ├── backup_database.sh
│   │   ├── backup_media_from_prod.sh
│   │   ├── backup_retention.sh
│   │   └── ...
│   │
│   ├── deploy/                  ← デプロイメント
│   │   ├── deploy.sh
│   │   └── send_backup_notification.sh
│   │
│   ├── dev/                     ← 開発用
│   │   ├── start-all-docker.bat
│   │   ├── start-backend.bat
│   │   ├── start-frontend-dev.bat
│   │   ├── stop-all-docker.bat
│   │   └── _inspect_static.sh
│   │
│   └── legacy/                  ← 古いセットアップスクリプト
│       ├── fix-nginx-conflict.sh
│       ├── setup-app-user.sh
│       └── ...
│
└── backend/
    ├── scripts/                 ← バックエンド管理スクリプト
    │   ├── test_backup.ps1
    │   ├── test_restore.ps1
    │   ├── load_card_master.ps1
    │   ├── reset_database.ps1
    │   └── restore_from_prod.ps1
    │
    └── ...
```

---

## ✅ まとめ

### 現在の状況
- **本番バックアップ**: `scripts/` の `.sh` で本番サーバーで実行中 ✓
- **開発テスト**: ルートと `backend/` の `.ps1` で Windows で実行
- **状態**: 役割別に分散している（わかりづらい）

### ユーザーの正しい指摘
- 本番で実際に使われているのは `scripts/` 配下
- 開発用と本番用が混在している
- 整理が必要

### 推奨される次のステップ
1. **今日**: `scripts/` を `dev/`, `backup/`, `deploy/`, `legacy/` に分類
2. **近日**: `backend/` の `.ps1` を整理
3. **本番移行時**: サーバー側の cron スケジュール確認

---

**ステータス**: 📊 分析完了  
**推奨実行時期**: フェーズ 1 を今日実施  
**複雑度**: 中（分類と移動のみ）

