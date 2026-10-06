# 本番環境デプロイメント計画
日付: 2026/10/06 14:57 JST

## 📌 現在の状況

### Git ブランチ構成
```
main              ← 本番環境用（安定版）
└─ AyatoriControl ← 開発ブランチ（コミット済み・プッシュ済み）
```

### ブランチの最新情報
- **現在のブランチ**: `AyatoriControl`
- **状態**: コミット済み・プッシュ済み ✅
- **ローカルブランチ**: `main`, `AyatoriControl`

### ローカル環境の状態
- ✅ Python 3.11.9 / Django 5.2.10
- ✅ PostgreSQL / Redis（Docker起動中）
- ✅ データベース復元完了（60ユーザー、1,853投稿）
- ✅ API・管理画面動作確認完了
- ✅ 機能改善実装完了（検索機能、画像修正）
- ✅ ドキュメント整理完了

### 本番サーバー情報
```
ホスト: toyboxssh.ayatori-inc.co.jp
ユーザー: app（予想）
OS: Linux（CentOS または Ubuntu）
構成: Django + PostgreSQL + Nginx/Caddy
```

---

## 🎯 本番環境デプロイメント計画

### フェーズ 1: 本番サーバー接続・環境確認（今日）

#### ステップ 1-1: SSH 接続
```bash
ssh app@toyboxssh.ayatori-inc.co.jp
# または
ssh root@toyboxssh.ayatori-inc.co.jp
```

#### ステップ 1-2: 環境確認
```bash
# ホームディレクトリ確認
pwd

# 既存プロジェクト構成を確認
ls -la ~/toybox/
ls -la ~/toybox/

# Python / Docker の状態確認
python3 --version
docker ps
docker images

# 現在のブランチ確認
cd ~/toybox && git branch -a
git log --oneline -5
```

#### ステップ 1-3: バックアップ確認
```bash
# 既存バックアップの確認
ls -la ~/toybox/backups/
ls -la ~/20260930/
```

### フェーズ 2: コード配置・更新（今日〜明日）

#### ステップ 2-1: リポジトリ更新
```bash
cd ~/toybox

# 現在のブランチ確認
git branch -a

# AyatoriControl ブランチをプル
git checkout AyatoriControl
git pull origin AyatoriControl

# または main ブランチから マージ
git checkout main
git pull origin main
git merge AyatoriControl
```

#### ステップ 2-2: 依存関係の更新
```bash
cd ~/toybox/backend

# Python 仮想環境確認
source venv/bin/activate  # Linux の場合

# 依存関係をインストール
pip install -r requirements.txt

# Django マイグレーション実行
python manage.py migrate

# スタティックファイル収集
python manage.py collectstatic --noinput
```

#### ステップ 2-3: 環境変数確認
```bash
# .env ファイルの確認
cat .env

# 本番向け環境変数の設定（必要に応じて）
# DB_HOST, DEBUG, ALLOWED_HOSTS など
```

### フェーズ 3: サービス再起動（本番稼働）

#### ステップ 3-1: Docker サービス再起動
```bash
# 現在のサービス確認
docker ps

# アプリケーション再起動
cd ~/toybox
docker compose restart web

# または全サービス再起動
docker compose restart
```

#### ステップ 3-2: ヘルスチェック
```bash
# ローカルでのヘルスチェック
curl http://localhost:8000/api/health/

# 本番ドメインでのチェック
curl https://toybox.ayatori-inc.co.jp/api/health/

# ブラウザで確認
# https://toybox.ayatori-inc.co.jp/
# https://toybox.ayatori-inc.co.jp/admin/
```

#### ステップ 3-3: ログ確認
```bash
# Docker ログ確認
docker logs -f toybox-web-1

# Nginx/Caddy ログ確認
tail -f /var/log/caddy.log
```

### フェーズ 4: バックアップ・メディア復元（本番稼働後）

#### ステップ 4-1: PostgreSQL リストア
```bash
# バックアップから復元
cd ~/toybox
# docker compose で DB サービスを確認
docker compose up -d db

# リストア実行
docker compose exec db pg_restore -U postgres -d toybox /tmp/toybox_backup.dump
```

#### ステップ 4-2: メディアボリューム復元
```bash
# 本番サーバーで tar.gz を展開
cd ~/toybox/public/uploads
tar -xzf ~/20260930/media_volume_20260929_210020.tar.gz

# オーナーシップ修正
sudo chown -R app:app ~/toybox/public/uploads/
```

#### ステップ 4-3: バックアップスクリプト確認
```bash
# scripts フォルダを確認
ls -la ~/toybox/scripts/

# cron ジョブ設定確認
crontab -l

# バックアップの定期実行を設定（必要に応じて）
crontab -e
```

---

## 📊 本番環境でのGit運用方針

### ブランチ戦略

#### 本番環境（Production）
- **ブランチ**: `main`
- **ポリシー**: マージされたコードのみ
- **更新方法**: `git pull origin main`

#### 開発環境（Development）
- **ブランチ**: `AyatoriControl`（現在）
- **目的**: 新機能開発・テスト
- **マージ**: テスト完了後に `main` にマージ

### 運用フロー

```
ローカル開発
  ↓
[変更 → コミット → プッシュ]
  ↓
AyatoriControl ブランチ（GitHub/Origin）
  ↓
[テスト OK]
  ↓
[Pull Request → Merge to main]
  ↓
main ブランチ
  ↓
[本番サーバーで git pull]
  ↓
本番環境に反映
```

### 推奨される運用ルール

1. **開発時**
   ```bash
   git checkout AyatoriControl
   git pull origin AyatoriControl
   # ... 開発 ...
   git add .
   git commit -m "feat: 機能説明"
   git push origin AyatoriControl
   ```

2. **テスト完了後**
   ```bash
   # Pull Request を作成
   # レビュー・テスト実施
   # Merge to main
   ```

3. **本番デプロイ時**
   ```bash
   cd ~/toybox
   git checkout main
   git pull origin main
   docker compose restart web
   ```

---

## 🔍 注意点・確認項目

### 本番環境での確認事項

- [ ] SSH 接続確認
- [ ] 既存 Git リポジトリ確認
- [ ] Python / Docker インストール確認
- [ ] PostgreSQL データ存在確認
- [ ] メディアボリューム状態確認
- [ ] Nginx/Caddy 動作確認
- [ ] SSL 証明書確認
- [ ] ファイアウォール設定確認

### デプロイ前のチェック

- [ ] `main` ブランチ状態確認
- [ ] ローカルで最終テスト完了
- [ ] バックアップ取得完了
- [ ] 環境変数設定確認
- [ ] スタティックファイル確認
- [ ] マイグレーション確認

### デプロイ後の検証

- [ ] `/api/health/` エンドポイント確認
- [ ] 管理画面 `/admin/` ログイン確認
- [ ] 記事一覧・検索機能確認
- [ ] API エンドポイント動作確認
- [ ] ログ出力確認（エラーなし）
- [ ] バックアップスクリプト動作確認

---

## 📝 本番環境 Git 設定（サーバー側）

### 初期設定（サーバー側で一度だけ実施）

```bash
# Git 設定
git config --global user.name "ToyBox System"
git config --global user.email "system@toybox.local"

# SSH キー確認
ls -la ~/.ssh/

# Git クローン（初期化）
# 既にリポジトリがある場合はスキップ
cd ~ && git clone origin.cursor.com/username/toybox
```

### 定期的な更新（デプロイ時）

```bash
cd ~/toybox
git checkout main
git fetch origin
git pull origin main
git status
```

---

## 🎯 本番環境への段階的な進め方

### 推奨スケジュール

| 日時 | フェーズ | 内容 |
|------|---------|------|
| **本日** | 1 | SSH接続・環境確認 |
| **明日** | 2 | コード配置・依存関係更新 |
| **明日** | 3 | サービス再起動・ヘルスチェック |
| **明後日** | 4 | バックアップ・メディア復元 |
| **その後** | - | 定期バックアップ確認 |

---

## ⚠️ リスク管理

### 本番環境での注意

1. **データ保全**
   - デプロイ前に必ずバックアップ取得
   - リストア手順を事前確認

2. **ダウンタイム最小化**
   - サービス再起動は夜間に実施（推奨）
   - ユーザーへの事前通知

3. **ロールバック計画**
   - 万が一のため、前のコミットに戻せるよう準備
   - `git revert` または `git reset` 対応

4. **モニタリング**
   - デプロイ後、ログを継続確認
   - `/api/health/` で定期確認
   - エラーログの監視

---

## 📄 関連ドキュメント

- `doc/LOCAL_SETUP_SUMMARY_20261006.md` - ローカル環境セットアップ
- `doc/SCRIPTS_ANALYSIS_20261006.md` - バックアップスクリプト
- `doc/MEDIA_RESTORE_ISSUE_20261006.md` - メディアリストア方法
- `README.md` - プロジェクト全体

---

**ステータス**: 📋 計画完成  
**次のステップ**: 本番サーバーへの SSH 接続  
**推奨実行時期**: 本日夜間または明日

