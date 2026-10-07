# ドキュメント・スクリプト整理計画
日付: 2026/10/06 14:48 JST

## 📋 現在の散在状況

### ルートレベルの .sh ファイル（セットアップ用・古い）
```
C:\github\toybox\
├── fix-nginx-conflict.sh              ← 古い（本番用？）
├── fix-ssh-final.sh                   ← 古い
├── fix-ssh-setup.sh                   ← 古い
├── fix-ssh-via-existing-connection.sh ← 古い
├── restore_caddyfile.sh               ← 古い
├── setup-app-user-centos.sh           ← 古い
├── setup-app-user.sh                  ← 古い
├── setup-ssh-complete.sh              ← 古い
└── setup-ssh-key-manual.sh            ← 古い
```

### scripts/ フォルダ（アクティブ）
```
C:\github\toybox\scripts\
├── backup_database.sh                 ✓ 現在使用
├── backup_media_from_prod.sh          ✓ 現在使用
├── backup_nightly.sh                  ✓ 現在使用
├── backup_retention.sh                ✓ 現在使用
├── backup_volumes.sh                  ✓ 現在使用
├── backup_volumes_incremental.sh      ✓ 現在使用
├── deploy.sh                          ✓ 本番デプロイ
├── restore_backup.sh                  ✓ リストア用
├── send_backup_notification.sh        ✓ 通知用
└── _inspect_static.sh                 ✓ 検査用
```

### doc/ フォルダ（ドキュメント・混在）
```
C:\github\toybox\doc\
├── README.md
├── 移行作業時のメモ20261006.md       ✓ 新規（今日）
├── ARTICLES_IMAGE_FIX_20261006.md     ✓ 新規（今日）
├── ARTICLES_SEARCH_FEATURE_20261006.md ✓ 新規（今日）
├── DATA_RESTORE_REPORT_20261006.md    ✓ 新規（今日）
├── LOCAL_SETUP_SUMMARY_20261006.md    ✓ 新規（今日）
├── MEDIA_RESTORE_ISSUE_20261006.md    ✓ 新規（今日）
├── PROJECT_STRUCTURE_ANALYSIS_20261006.md ✓ 新規（今日）
│
├── 古いドキュメント（移動対象）
├── announcement_v2.0.txt              ← 古い
├── discord_v2.0.md                    ← 古い
├── TOYBOX_MANUAL.md                   ← 古い
├── TOYBOX_v2.0_バージョンアップ揃え.md ← 古い
├── toybox仕様.md                      ← 古い
├── TOYBOXサマリ.md                    ← 古い
├── カード概要.md                      ← 古い
├── 称号について.md                    ← 古い
├── 〇〇について.md                     ← 古い
│
├── 複数フォルダ
├── setup/                 ← セットアップドキュメント
├── deployment/            ← デプロイドキュメント
├── backup/                ← バックアップドキュメント
├── troubleshooting/       ← トラブルシューティング
├── reference/             ← リファレンス
└── legacy/                ← 古いドキュメント（作成予定）
```

---

## 🎯 整理計画

### フェーズ 1: 古いファイルを legacy に移動（今日）

#### 1-1. doc/legacy/ フォルダを作成
```powershell
New-Item -ItemType Directory -Path C:\github\toybox\doc\legacy -Force
```

#### 1-2. 古いドキュメントを移動
```powershell
Move-Item C:\github\toybox\doc\announcement_v2.0.txt C:\github\toybox\doc\legacy\
Move-Item C:\github\toybox\doc\discord_v2.0.md C:\github\toybox\doc\legacy\
Move-Item C:\github\toybox\doc\TOYBOX_MANUAL.md C:\github\toybox\doc\legacy\
Move-Item C:\github\toybox\doc\TOYBOX_v2.0_* C:\github\toybox\doc\legacy\
Move-Item C:\github\toybox\doc\toybox仕様.md C:\github\toybox\doc\legacy\
Move-Item C:\github\toybox\doc\TOYBOXサマリ.md C:\github\toybox\doc\legacy\
Move-Item C:\github\toybox\doc\カード概要.md C:\github\toybox\doc\legacy\
Move-Item C:\github\toybox\doc\称号について.md C:\github\toybox\doc\legacy\
```

#### 1-3. REFACTORING_SUMMARY.md を移動
```powershell
Move-Item C:\github\toybox\backend\REFACTORING_SUMMARY.md C:\github\toybox\doc\legacy\
```

#### 1-4. ルートの古い .sh ファイルを scripts/legacy に移動
```powershell
# scripts/legacy フォルダ作成
New-Item -ItemType Directory -Path C:\github\toybox\scripts\legacy -Force

# 古い .sh をまとめて移動
Move-Item C:\github\toybox\fix-*.sh C:\github\toybox\scripts\legacy\
Move-Item C:\github\toybox\restore_caddyfile.sh C:\github\toybox\scripts\legacy\
Move-Item C:\github\toybox\setup-*.sh C:\github\toybox\scripts\legacy\
```

---

### フェーズ 2: 新規ドキュメント構造の整備（今日〜明日）

#### 2-1. doc/ を整理
```
doc/
├── README.md                    ← 更新（ナビゲーション追加）
├── 移行作業時のメモ20261006.md  ← 新規
│
├── setup/
│   ├── LOCAL_SETUP_SUMMARY_20261006.md
│   ├── DOCKER_SETUP.md
│   ├── SERVER_SETUP.md
│   └── requirements.md
│
├── features/
│   ├── ARTICLES_SEARCH_FEATURE_20261006.md
│   ├── ARTICLES_IMAGE_FIX_20261006.md
│   ├── gamification.md
│   └── user_management.md
│
├── deployment/
│   ├── MEDIA_RESTORE_ISSUE_20261006.md
│   ├── deployment_guide.md
│   ├── server_configuration.md
│   └── backup_strategy.md
│
├── reference/
│   ├── PROJECT_STRUCTURE_ANALYSIS_20261006.md
│   ├── DATA_RESTORE_REPORT_20261006.md
│   ├── technology_stack.md
│   ├── environment_variables.md
│   └── api_endpoints.md
│
├── troubleshooting/
│   ├── common_issues.md
│   ├── debugging.md
│   └── faq.md
│
└── legacy/
    ├── REFACTORING_SUMMARY.md
    ├── announcement_v2.0.txt
    ├── discord_v2.0.md
    ├── TOYBOX_MANUAL.md
    ├── toybox仕様.md
    └── （その他古いドキュメント）
```

#### 2-2. scripts/ を整理
```
scripts/
├── README.md                          ← スクリプト一覧
├── backup_nightly.sh                  ✓ ナイトリーバックアップ
├── backup_database.sh                 ✓ DB バックアップ
├── backup_media_from_prod.sh          ✓ メディアバックアップ
├── backup_retention.sh                ✓ 保持期間管理
├── restore_backup.sh                  ✓ 復元スクリプト
├── deploy.sh                          ✓ デプロイスクリプト
├── send_backup_notification.sh        ✓ 通知スクリプト
│
├── dev/                               ← 開発用
│   └── _inspect_static.sh
│
└── legacy/                            ← 古いセットアップスクリプト
    ├── fix-nginx-conflict.sh
    ├── fix-ssh-final.sh
    ├── fix-ssh-setup.sh
    ├── fix-ssh-via-existing-connection.sh
    ├── restore_caddyfile.sh
    ├── setup-app-user-centos.sh
    ├── setup-app-user.sh
    ├── setup-ssh-complete.sh
    └── setup-ssh-key-manual.sh
```

---

### フェーズ 3: 本番環境移行後（将来）

#### 3-1. docs/migration をメインドキュメントに統合
```
docs/
├── README.md
├── guides/
│   ├── quickstart.md
│   ├── installation.md
│   └── configuration.md
│
├── api/
│   ├── overview.md
│   ├── authentication.md
│   ├── endpoints.md
│   └── examples.md
│
├── operations/
│   ├── deployment.md
│   ├── monitoring.md
│   ├── backup_restore.md
│   └── troubleshooting.md
│
└── development/
    ├── architecture.md
    ├── contributing.md
    ├── testing.md
    └── performance.md
```

#### 3-2. doc/ を廃止し docs/ に統一
```
doc/ は廃止
すべて docs/ に統合
```

---

## ✅ 実装ステップ

### 今日実施すること（フェーズ 1）

```powershell
# 1. legacy フォルダを作成
New-Item -ItemType Directory -Path C:\github\toybox\doc\legacy -Force
New-Item -ItemType Directory -Path C:\github\toybox\scripts\legacy -Force

# 2. 古いドキュメントを移動
$legacyDocs = @(
    'announcement_v2.0.txt',
    'discord_v2.0.md',
    'TOYBOX_MANUAL.md',
    'TOYBOX_v2.0_バージョンアップ揃え.md',
    'toybox仕様.md',
    'TOYBOXサマリ.md',
    'カード概要.md',
    '称号について.md'
)

foreach ($file in $legacyDocs) {
    $src = "C:\github\toybox\doc\$file"
    if (Test-Path $src) {
        Move-Item $src C:\github\toybox\doc\legacy\ -Force
        Write-Host "✅ 移動: $file"
    }
}

# 3. REFACTORING_SUMMARY.md を移動
Move-Item C:\github\toybox\backend\REFACTORING_SUMMARY.md C:\github\toybox\doc\legacy\ -Force

# 4. ルートの古い .sh を移動
$oldShScripts = @(
    'fix-nginx-conflict.sh',
    'fix-ssh-final.sh',
    'fix-ssh-setup.sh',
    'fix-ssh-via-existing-connection.sh',
    'restore_caddyfile.sh',
    'setup-app-user-centos.sh',
    'setup-app-user.sh',
    'setup-ssh-complete.sh',
    'setup-ssh-key-manual.sh'
)

foreach ($file in $oldShScripts) {
    $src = "C:\github\toybox\$file"
    if (Test-Path $src) {
        Move-Item $src C:\github\toybox\scripts\legacy\ -Force
        Write-Host "✅ 移動: $file"
    }
}

Write-Host ""
Write-Host "✅ 整理完了！"
```

---

## 📊 整理の効果

### Before（現在）
```
toybox/
├── fix-*.sh         ❌ ルートに散在
├── setup-*.sh       ❌ 
├── restore_*.sh     ❌
├── doc/
│   ├── 古いドキュメント（多数）   ❌ 混在
│   ├── 新規ドキュメント（今日）   ✓
│   └── サブフォルダ（setup, deployment等）✓
├── backend/
│   ├── REFACTORING_SUMMARY.md      ❌ 不要な場所
│   └── ...
└── scripts/
    └── （アクティブなスクリプト）   ✓
```

### After（整理後）
```
toybox/
├── doc/
│   ├── README.md                    ← ナビゲーション
│   ├── setup/                       ✓
│   ├── features/                    ✓
│   ├── deployment/                  ✓
│   ├── reference/                   ✓
│   ├── troubleshooting/             ✓
│   └── legacy/                      ← 古いドキュメント
│
├── scripts/
│   ├── README.md                    ← スクリプト一覧
│   ├── （アクティブなスクリプト）   ✓
│   ├── dev/                         ← 開発用
│   └── legacy/                      ← 古いセットアップスクリプト
│
└── backend/
    └── （REFACTORING_SUMMARY.md は doc/legacy へ移動）
```

---

## 🎯 タイムライン

| フェーズ | 内容 | タイミング |
|----------|------|-----------|
| **1** | 古いファイルを legacy に移動 | 今日（2026/10/06） |
| **2** | ドキュメント構造を整備 | 今日〜明日 |
| **3** | docs/ に統合（本番移行時） | 将来 |

---

**ステータス**: 📋 計画完成  
**推奨**: 本番環境移行後に最終的に統一  
**効果**: ドキュメント・スクリプトの一元管理

