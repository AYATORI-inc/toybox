# Toybox 移行プロジェクト ドキュメント一覧（2026/10/07）

## 📋 ドキュメント全体像

```
doc/transfer202610/
├── 🔴 [必読] STATUS_SUMMARY_20261007.md          ← 現在地を 5分で把握
├── 🔴 [必読] MIGRATION_MASTERPLAN_THISWEEK_20261007.md  ← 本週中の完全ガイド
├── 🔴 [必読] PRE_MIGRATION_CHECKLIST_THISWEEK_20261007.md ← チェックリスト
│
├── 📊 既存本番の調査・分析
│   ├── EXISTING_PRODUCTION_SURVEY_20261007.md   ← 既存本番の構成（2026/10/07 確認）
│   ├── PRODUCTION_GOTCHAS_20261006.md           ← 本番環境での注意点
│   └── SCRIPTS_ANALYSIS_20261006.md             ← バックアップスクリプト分析
│
├── 🏗️ 新規本番セットアップ（完了）
│   ├── PRODUCTION_DOCKER_SETUP_20261006.md      ← 新規本番 Docker セットアップ
│   ├── PRODUCTION_DEPLOYMENT_PLAN_20261006.md   ← デプロイメント計画
│   └── DATA_RESTORE_REPORT_20261006.md          ← データリストア手順
│
├── 💻 ローカル環境セットアップ（完了）
│   ├── LOCAL_SETUP_SUMMARY_20261006.md          ← ローカル環境セットアップ報告書
│   ├── PROJECT_STRUCTURE_ANALYSIS_20261006.md   ← プロジェクト構成分析
│   └── ORGANIZATION_PLAN_20261006.md            ← ドキュメント整理計画
│
├── 🔧 機能改善
│   ├── ARTICLES_SEARCH_FEATURE_20261006.md      ← 検索機能実装
│   ├── ARTICLES_IMAGE_FIX_20261006.md           ← 画像修正
│   └── MEDIA_RESTORE_ISSUE_20261006.md          ← メディアリストア課題
│
└── 📝 進行中
    └── 移行作業時のメモ20261006.md             ← 作業ログ（更新中）
```

---

## 🚀 本週中の移行・最優先ドキュメント

### 1️⃣ 現在地把握（5分で読む）

📄 **STATUS_SUMMARY_20261007.md**
- 現在の進捗（70%）
- 既存本番の状態（ディスク 84.7% 使用中 ⚠️）
- 新規本番の準備状況
- 今すぐやるべきこと

### 2️⃣ 実行計画（15分で読む）

📄 **MIGRATION_MASTERPLAN_THISWEEK_20261007.md**
- 5 つのステップ（火曜〜金曜）
- 時系列スケジュール
- リスク管理
- ロールバック計画

### 3️⃣ チェックリスト（参照）

📄 **PRE_MIGRATION_CHECKLIST_THISWEEK_20261007.md**
- 情報収集フェーズ（今すぐ）
- バックアップ取得（火曜）
- 新規本番テスト（水曜）
- DNS 切替（木夜/金朝）

---

## 📊 既存本番の状態（2026/10/07 確認済み）

### ドキュメント
📄 **EXISTING_PRODUCTION_SURVEY_20261007.md**

**サーバー情報**
```
ホスト: vm-c2dd3545-73
IP: 160.251.168.144
OS: Ubuntu 24.04.3 LTS
ディスク: 84.7% 使用 ⚠️
メモリ: 84% 使用 ⚠️
```

**稼働サービス（本番）**
- ✅ toybox-caddy-1（ポート 80/443）
- ✅ toybox-web-1（ポート 8000）
- ✅ toybox-db-1（PostgreSQL 15）
- ✅ toybox-redis-1（Redis 7）
- ✅ toybox-worker-1（Celery）
- ✅ toybox-beat-1（Celery Beat）

**稼働期間**: 3ヶ月以上（安定稼働）

**問題点**
- ⚠️ Git にコミットなし
- ⚠️ ディスク逼迫
- ⚠️ テスト環境（backend-*）が失敗状態

---

## 🏗️ 新規本番セットアップ（ほぼ完了）

### ドキュメント
📄 **PRODUCTION_DOCKER_SETUP_20261006.md**
📄 **PRODUCTION_DEPLOYMENT_PLAN_20261006.md**

**サーバー情報**
```
ホスト: toyboxssh.ayatori-inc.co.jp
IP: 192.168.122.140
OS: Ubuntu 24.04.4 LTS
ディスク: 200GB ✅
状態: 準備完了
```

**完了事項**
- ✅ Docker/Docker Compose インストール
- ✅ Python 3.11 インストール
- ✅ PostgreSQL/Redis Docker コンテナ起動
- ✅ Django マイグレーション実行
- ✅ スーパーユーザー作成
- ✅ テストデータリストア（60ユーザー、277記事）
- ✅ API ヘルスチェック確認

**残作業**
- [ ] Caddy 設定（リバースプロキシ & SSL）
- [ ] Cloudflare 接続
- [ ] メディアボリューム復元（5.8GB）

---

## 💻 ローカル環境セットアップ（完了）

### ドキュメント
📄 **LOCAL_SETUP_SUMMARY_20261006.md**
📄 **PROJECT_STRUCTURE_ANALYSIS_20261006.md**

**完了事項**
- ✅ Python 3.11 + venv セットアップ
- ✅ Docker Compose（PostgreSQL, Redis）
- ✅ pip install（38 パッケージ）
- ✅ Django マイグレーション
- ✅ テストユーザー作成
- ✅ API テスト成功

**テストデータ**
- 60 ユーザー復元
- 1,853 投稿復元
- 10,620 リアクション復元

---

## 🔧 機能改善（確認済み）

### ドキュメント
📄 **ARTICLES_SEARCH_FEATURE_20261006.md**
📄 **ARTICLES_IMAGE_FIX_20261006.md**
📄 **MEDIA_RESTORE_ISSUE_20261006.md**

**実装完了**
- ✅ 記事検索機能（全文検索対応）
- ✅ 画像パス修正
- ✅ メディアボリューム復元手順確立

---

## 📝 作業ログ

📄 **移行作業時のメモ20261006.md**
- Phase 1-4 完了ログ
- データリストア結果
- 新規本番セットアップログ

---

## 🎯 今週中の実行フロー

```
【月曜 (今日)】
  ✅ 既存本番の構成把握（90% 完了）
  ⏳ 残り設定ファイル取得（Caddyfile, docker-compose.prod.yml）

【火曜 (明日)】
  ☐ バックアップ取得（DB ダンプ + メディア）
  ☐ 新規本番でテスト実施
  ☐ ローカル PC に保存

【水曜】
  ☐ DNS TTL 短縮（Cloudflare）
  ☐ 最終検証（API, Caddy）

【木曜夜 or 金曜朝】
  ☐ 本番切替実行（DNS A レコード変更）
  ☐ ダウンタイム: 5-10 分
  ☐ 外部から https://toybox.ayatori-inc.co.jp に接続確認

【金曜午後】
  ☐ 既存本番を安全に停止
  ☐ ドキュメント最終更新
```

---

## 🚨 重要な注意点

### ⚠️ 既存本番のリソース逼迫

```
ディスク: 84.7% 使用 (98.24GB)
メモリ: 84% 使用
Swap: 54% 使用

対策:
1. バックアップ取得後、即座にローカル転送
2. 新規本番へのリストア後に削除
```

### ⚠️ Git の問題

```
既存本番: Git にコミットなし
新規本番: git clone 済み

対応: 新規本番を本番として使用
```

### ⚠️ Caddy の SSL 設定

```
既存本番: Caddy で HTTPS 対応（Let's Encrypt?)
新規本番: 構築予定

確認事項:
- Caddyfile を完全にコピーできるか
- SSL 証明書の自動更新設定
```

---

## 📞 すぐにやることリスト

### 🔴 今日中に実行

```bash
cd /var/www/toybox && {
  echo "=== 1. CADDYFILE ===" && cat Caddyfile && \
  echo -e "\n=== 2. DOCKER-COMPOSE.PROD.YML ===" && cat docker-compose.prod.yml && \
  echo -e "\n=== 3. DISK USAGE ===" && du -sh /var/www/toybox/* | sort -h && \
  echo -e "\n=== 4. GIT REMOTE ===" && git remote -v && \
  echo -e "\n=== 5. UPLOADS SIZE ===" && du -sh /var/www/toybox/backend/public/uploads && \
  echo -e "\n=== 6. DATA COUNTS ===" && \
  docker exec toybox-db-1 psql -U postgres -d toybox -c \
  "SELECT 'users' as table_name, COUNT(*) as count FROM auth_user 
   UNION SELECT 'articles', COUNT(*) FROM articles_article 
   UNION SELECT 'reactions', COUNT(*) FROM reactions_reaction;"
}
```

**出力をコピーして貼り付けてください。**

---

## ✅ 移行前の最終チェックリスト

- [ ] Caddyfile 内容確認
- [ ] docker-compose.prod.yml 確認
- [ ] ユーザー/記事数記録
- [ ] バックアップ取得（火曜）
- [ ] 新規本番テスト（水曜）
- [ ] DNS TTL 短縮（水曜）
- [ ] 本番切替（金曜朝）
- [ ] 検証完了

---

**作成日**: 2026/10/07 11:20 JST  
**作成者**: AI Assistant  
**ステータス**: 🚀 本週中完了予定  
**次のアクション**: サーバーから設定ファイル取得

