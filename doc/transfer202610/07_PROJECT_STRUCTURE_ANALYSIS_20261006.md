# ToyBox プロジェクト構造分析
日付: 2026/10/06 14:45 JST

## 📁 プロジェクト全体構成

```
toybox/
├── LP/                          ← ランディングページ（HTML+CSS+JS）
│   ├── index.html              ※ Node.js 不要（静的ファイル）
│   ├── assets/
│   │   ├── js/
│   │   ├── css/
│   │   └── images/
│   └── README.md
│
├── backend/                      ← メインアプリケーション（Django）
│   ├── manage.py               ← Django コマンドツール
│   ├── requirements.txt         ← Python パッケージ一覧
│   ├── docker-compose.yml       ← PostgreSQL, Redis
│   ├── venv/                   ← Python 仮想環境
│   │
│   ├── src/                    ← データファイルのみ
│   │   └── data/
│   │       ├── card_master.tsv
│   │       └── card_master_new.tsv
│   │
│   ├── toybox/                 ← Django プロジェクト
│   ├── users/                  ← Django アプリ
│   ├── submissions/
│   ├── articles/               ← 記事機能
│   ├── gamification/
│   ├── lottery/
│   ├── sharing/
│   ├── frontend/               ← Django Templates（HTML）
│   ├── adminpanel/
│   ├── public/                 ← メディアファイル（画像・動画）
│   └── ...
│
├── docs/                        ← ドキュメント（Markdown）
│   └── migration/
│       ├── api_examples.md
│       ├── etl_mapping.md
│       ├── feature_map.md
│       └── compat_plan.md
│
├── doc/                         ← 追加ドキュメント
│   ├── setup/
│   ├── deployment/
│   ├── troubleshooting/
│   ├── backup/
│   ├── reference/
│   └── 移行作業時のメモ20261006.md
│
├── scripts/                     ← ユーティリティ（Shell/PowerShell）
│   ├── backup_nightly.sh
│   └── ...
│
├── .github/                     ← GitHub（CI/CD）
│   └── workflows/
│       └── deploy.yml          ← 自動デプロイ設定
│
└── README.md

```

---

## 🔍 Node.js の存在場所

### ❌ Node.js は **使用されていない** ✓

#### 確認内容
- **`package.json`**: ❌ なし（プロジェクトルートに存在しない）
- **`src/`フォルダ**: データファイル（`.tsv`）のみ
  - `card_master.tsv` - カードマスターデータ
  - `card_master_new.tsv` - 更新版データ
- **Node.js 実行ファイル**: ❌ なし
- **npm / yarn**: ❌ 使用していない

### 📝 REFACTORING_SUMMARY.md の混乱について

先ほど見た `REFACTORING_SUMMARY.md` に記載されていた内容：
```
- src/lib/upload.ts
- src/api/user.ts
- src/validation/user.ts
等は Express.js (Node.js) コードです
```

**これは過去のプロジェクト設計資料の可能性が高い** ↓

---

## 🎯 実際の技術スタック

### 現在の構成（2026/10/06 時点）

```
┌─────────────────────────────────────────────┐
│          ToyBox プロジェクト                   │
├─────────────────────────────────────────────┤
│                                              │
│  📘 Backend: Django 5.2.10                  │
│     • Python 3.11.9                         │
│     • Django REST Framework 3.15.2          │
│     • PostgreSQL 15                         │
│     • Redis 7                               │
│     • Celery 5.4.0                         │
│                                              │
│  🎨 Frontend: Django Templates              │
│     • HTML5                                 │
│     • CSS3                                  │
│     • JavaScript (バニラ)                    │
│     • HTMX (オプション)                      │
│                                              │
│  🌐 Web Server: Gunicorn (本番)             │
│     • Caddy (リバースプロキシ)               │
│                                              │
│  📄 Landing Page: 静的HTML                   │
│     • Node.js 不要                          │
│     • Pure HTML/CSS/JS                     │
│                                              │
└─────────────────────────────────────────────┘
```

---

## 📊 各フォルダの役割

| フォルダ | 用途 | 技術スタック | Node.js |
|----------|------|-------------|--------|
| **backend/** | メインアプリ | Django + Python | ❌ |
| **LP/** | ランディング | 静的HTML | ❌ |
| **docs/** | 移行ドキュメント | Markdown | ❌ |
| **doc/** | その他ドキュメント | Markdown | ❌ |
| **scripts/** | ユーティリティ | Bash / PowerShell | ❌ |
| **.github/** | CI/CD | GitHub Actions | ⚠️ |

---

## ⚠️ REFACTORING_SUMMARY.md について

### 現在の状況

**このファイルは「実装済みのリファクタリング」というより「参考資料」の可能性**

#### 証拠
1. **Node.js ファイルへの言及**
   ```
   - src/lib/upload.ts
   - src/api/user.ts
   - src/validation/user.ts
   ```
   実装中に確認したコードには存在しない

2. **Express.js の構文を使用**
   ```javascript
   // Express.js の記法
   app.post('/api/user/profile/avatar', ...)
   ```
   実際の Django では異なる（views.py で実装）

3. **DRF で既に実装済み**
   ```python
   # Django では既に実装
   class ArticleListCreateView(generics.ListCreateAPIView):
       # ... ここに upload や validation が存在
   ```

### 推測される背景

1. **過去のプロジェクト設計資料**
   - Node.js/Express での実装を検討していた時期があった
   - 後で Django に決定し、リファクタリング完了

2. **参考資料として残されている**
   - 開発チームが「何をしたのか」をドキュメント化
   - コード品質基準（アップロード制限、エラーハンドリング等）を記録

---

## 🎯 整理されるべき資料構成（推奨）

### 推奨される整理方法

```
docs/                              ← すべてのドキュメント
├── architecture/                  ← システム設計
│   ├── overview.md               ← 全体構成
│   ├── technology_stack.md       ← 技術選択
│   ├── data_model.md             ← ER図
│   └── api_design.md             ← API設計
│
├── setup/                         ← セットアップ
│   ├── local_environment.md      ← ローカル環境（完成版）
│   ├── server_deployment.md      ← サーバー構築
│   └── docker_setup.md
│
├── features/                      ← 機能説明
│   ├── articles.md
│   ├── gamification.md
│   ├── user_management.md
│   └── search.md
│
├── reference/                     ← リファレンス
│   ├── api_endpoints.md          ← API 一覧
│   ├── database_schema.md        ← スキーマ
│   └── environment_variables.md
│
├── troubleshooting/
│   ├── common_issues.md
│   ├── debugging.md
│   └── performance.md
│
└── archive/                       ← 参考資料（古い）
    └── refactoring_summary.md    ← Express.js 検討時代の資料
```

---

## ✅ 結論

### Node.js の使用有無

| 質問 | 回答 |
|------|------|
| **LP は Node.js ?** | ❌ いいえ。静的HTML |
| **Django バックエンドは Node.js ?** | ❌ いいえ。Python + Django |
| **プロジェクトのどこかに Node.js ?** | ❌ なし |
| **REFACTORING_SUMMARY.md について** | 📝 参考資料（過去の設計案） |

### 現在のスタック

```
✅ Python + Django + DRF
✅ PostgreSQL + Redis
✅ Gunicorn + Caddy
✅ Docker
❌ Node.js / Express（未使用）
```

---

## 📋 ドキュメント整理のアクション（推奨）

### 短期
1. **REFACTORING_SUMMARY.md を review**
   - 「参考資料」として明記
   - または `docs/archive/` に移動

2. **本日のドキュメントを統合**
   - `LOCAL_SETUP_SUMMARY_20261006.md` → `docs/setup/`
   - `ARTICLES_SEARCH_FEATURE_20261006.md` → `docs/features/`
   - など

### 中期
1. **docs/ を統合・整理**
   - `docs/migration/` と `doc/` を統一
   - 構造を明確にする

2. **README.md を更新**
   - 最新のセットアップ手順に更新

---

**ステータス**: ✅ 分析完了  
**結論**: Node.js は不要。Django のみで構成  
**推奨**: ドキュメント構造の整理

