# 本番環境セットアップ時の「おや？」ポイント
日付: 2026/10/06 15:27 JST

## 📋 概要

ローカル開発環境と本番環境の差分を洗い出し、セットアップ時に迷わないようにまとめたドキュメント。

---

## 🚨 重要な「おや？」リスト

### 1. **ローカルに存在するが本番に不要なファイル**

#### ❌ Windows/Mac 開発用スクリプト（本番では不要）
```
✗ *.bat ファイル（Windows Batch）
  - start-all-docker.bat
  - start-backend.bat
  - start-frontend-dev.bat
  - stop-all-docker.bat

✗ *.ps1 ファイル（PowerShell）
  - test_backup.ps1        ← テスト用
  - test_restore.ps1       ← テスト用
  - load_card_master.ps1   ← 開発用
  - make.ps1               ← ビルド用（開発）
  - create_test_users.ps1  ← テスト用
  - check_titles.py        ← テスト用
  - check_title_images.py  ← テスト用
  - reset_database.ps1     ← 開発用リセット
  - restore_from_prod.ps1  ← テスト用
  - restore_media_local.ps1 ← 開発用
  - verify_media_restore.ps1 ← テスト用
```

**対応**: 本番には SCP で転送する際、これらは除外する

#### ❌ ローカル開発専用ディレクトリ
```
✗ /backend/venv/          ← Python 仮想環境
✗ __pycache__/            ← Python キャッシュ
✗ *.pyc ファイル          ← Python コンパイル済み

✗ /backend/data/          ← テストデータ
  - games_idea.json
  - tricycle_media_ideas.json

✗ /backend/tests/         ← 開発テスト
```

**対応**: .gitignore または .deployignore で除外

#### ❌ ローカルテスト用バックアップファイル
```
✗ /backend/backup_before_restore_20261006_142904.sql
✗ /backend/backup_current_20251217_152233.sql
✗ /backend/celerybeat-schedule  ← Celery スケジューラデータ
```

**対応**: 本番では実行時に自動生成される

#### ❌ ローカル開発用設定ファイル
```
✗ /backend/.env           ← ローカル用環境変数
✗ /backend/env.example    ← テンプレート
✗ /backend/env.sample     ← サンプル
✗ /backend/env.prod.sample ← サンプル
```

**対応**: 本番では `/etc/toybox/toybox.env` を使用（既に存在）

---

### 2. **ローカルと本番での構造差分**

#### 📁 ローカル構造
```
/github/toybox/
├── backend/
│   ├── .env              ← ローカル開発用
│   ├── venv/             ← Python 仮想環境
│   ├── manage.py
│   └── ...
├── LP/                   ← ランディングページ（別プロジェクト？）
├── docs/                 ← ドキュメント
├── doc/                  ← 別ドキュメント
├── scripts/              ← 本番用スクリプト ✓
└── 20260930/             ← バックアップファイル（ローカル）
```

#### 📁 本番構造
```
/var/www/toybox/
├── backend/
│   ├── manage.py
│   ├── venv/             ← システム Python 仮想環境
│   ├── public/uploads/   ← メディアファイル
│   └── ...
├── scripts/              ← 本番用スクリプト ✓
├── deploy/               ← デプロイ情報・設定
├── static/               ← 静的ファイル（collectstatic 後）
├── .git/                 ← Git リポジトリ（初期化済み）
└── .env                  ← リンク？ または別管理
```

**差分**:
- `LP/` は本番に不要（別プロジェクト？）
- `docs/` と `doc/` は本番に不要
- `venv/` は本番で別途セットアップ
- `.env` は本番では `/etc/toybox/toybox.env` から管理

---

### 3. **本番環境の現在の状態**

#### ✅ 既存・実装済み
```
✓ /var/www/toybox/.git/           ← Git リポジトリ（初期化済み）
✓ /var/www/toybox/deploy/         ← デプロイ設定フォルダ
✓ /etc/toybox/toybox.env          ← 環境変数（本番用）
✓ /etc/systemd/system/toybox-gunicorn.service  ← Systemd ユニット
✓ cron: backup_nightly.sh         ← 自動バックアップ（21:00）
```

#### ❌ 未設定・エラー状態
```
✗ git remote: 未設定                ← リモート URL 無し
✗ git branch: master のみ（空）      ← コミット無し
✗ toybox-gunicorn.service: 起動失敗   ← status=203/EXEC
  原因: Gunicorn の venv パスが不正？
```

---

### 4. **セットアップ時に注意すべき点**

#### A. **ファイル転送時の除外リスト**

SCP で転送する際、以下を除外：

```bash
# 除外パターン
✗ *.bat
✗ *.ps1
✗ /venv/
✗ __pycache__/
✗ *.pyc
✗ /backend/.env          ← 本番では使わない
✗ /backend/data/         ← テストデータ
✗ /backend/tests/        ← テストコード
✗ /backend/celerybeat-schedule
✗ /backend/backup_*.sql  ← ローカルバックアップ
✗ .deployignore で管理   ← ローカルで定義
```

#### B. **本番環境変数の管理**

```
ローカル開発:  /backend/.env
本番環境:     /etc/toybox/toybox.env

注意: .env は git に追跡されない
     本番では既に /etc/toybox/toybox.env が存在
```

#### C. **Python 仮想環境の再構築**

```bash
# 本番でやるべき:
cd /var/www/toybox/backend
python3.12 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### D. **静的ファイルの収集**

```bash
# 本番でやるべき:
cd /var/www/toybox/backend
python manage.py collectstatic --noinput
```

#### E. **DB マイグレーション**

```bash
# 本番でやるべき:
cd /var/www/toybox/backend
python manage.py migrate
```

---

### 5. **Systemd サービスの起動エラー対策**

#### 現象
```
toybox-gunicorn.service: Main process exited, code=exited, status=203/EXEC
```

#### 原因
```
多くの場合:
1. Gunicorn バイナリのパスが不正
2. venv が存在しない
3. パーミッション不足
4. Python パスが変わった
```

#### 修正手順
```bash
# 1. 実際のパスを確認
which gunicorn
ls -la /var/www/toybox/backend/venv/bin/gunicorn

# 2. Systemd ユニットを確認・編集
systemctl cat toybox-gunicorn.service
sudo systemctl edit toybox-gunicorn.service

# 3. ExecStart が正しいパスを指しているか確認
# 例:
# ExecStart=/var/www/toybox/backend/venv/bin/gunicorn \
#   --bind unix:/run/toybox/gunicorn.sock \
#   toybox.wsgi:application

# 4. 再読み込みと再起動
sudo systemctl daemon-reload
sudo systemctl restart toybox-gunicorn.service
sudo journalctl -u toybox-gunicorn.service -n 50
```

---

### 6. **Git リモート設定の確認**

#### 現在の状態
```bash
root@vm-c2dd3545-73:/var/www/toybox# git remote -v
# 出力なし = リモート未設定
```

#### セットアップ時
```bash
cd /var/www/toybox

# リモートを追加（Cursor Origin または GitHub）
git remote add origin <YOUR_REPO_URL>

# 確認
git remote -v

# ブランチ追跡設定
git fetch origin
git checkout -b main origin/main
git checkout -b AyatoriControl origin/AyatoriControl
```

---

### 7. **重要なファイルの場所確認**

| ファイル | ローカル | 本番 |
|---------|---------|------|
| **環境変数** | `/backend/.env` | `/etc/toybox/toybox.env` |
| **バックアップ** | `/20260930/` | `/backup/` |
| **メディア** | ローカルコンテナ | `/var/www/toybox/backend/public/uploads` |
| **スクリプト** | `/scripts/` | `/var/www/toybox/scripts/` |
| **Django マネージ** | `./backend/manage.py` | `/var/www/toybox/backend/manage.py` |
| **Gunicorn** | `venv/bin/gunicorn` | `/var/www/toybox/backend/venv/bin/gunicorn` |

---

### 8. **LP（ランディングページ）について**

#### ❓ 不明な点
```
/LP/ ディレクトリが存在
  ├── index.html
  ├── privacy.html
  ├── assets/
  └── README.md
```

#### 質問
```
- これは本番で公開される？
- 別ドメインで運用？
- Git に含める必要ある？
- 本番に SCP で転送する？
```

**推奨**: 確認が必要

---

### 9. **docs/ と doc/ について**

#### 構成
```
/docs/
├── migration/
│   ├── api_examples.md
│   ├── api_inventory.md
│   ├── compat_plan.md
│   ├── data_inventory.md
│   ├── etl_mapping.md
│   └── feature_map.md

/doc/
├── legacy/
├── mail/
├── reference/
├── setup/
├── troubleshooting/
├── deployment/
└── 各種 MD ファイル
```

#### 本番での扱い
```
✓ 開発・参考用なので、本番に転送しても無害
✓ ただしサイズ削減のため除外可能
✓ Git で管理（歴史を保持）
```

---

## 📝 セットアップチェックリスト

### 初期セットアップ時
- [ ] ファイル転送時に Windows 用スクリプト除外
- [ ] `/etc/toybox/toybox.env` の内容確認
- [ ] Python venv を本番で新規作成
- [ ] `pip install -r requirements.txt` 実行
- [ ] `python manage.py migrate` 実行
- [ ] `python manage.py collectstatic --noinput` 実行
- [ ] Git リモート設定
- [ ] Systemd ユニットのパス確認
- [ ] Gunicorn サービス起動確認

### 定期メンテナンス
- [ ] `/etc/toybox/toybox.env` のバックアップ
- [ ] クーロンジョブ確認（crontab -l）
- [ ] バックアップスクリプト動作確認
- [ ] ログファイルの確認（journalctl）

---

## 🔗 関連ドキュメント

- `doc/PRODUCTION_DEPLOYMENT_PLAN_20261006.md` - デプロイメント全体計画
- `doc/SCRIPTS_ANALYSIS_20261006.md` - スクリプト分析
- `doc/PROJECT_STRUCTURE_ANALYSIS_20261006.md` - プロジェクト構成分析
- `/var/www/toybox/deploy/DEPLOY_CONOHA_UBUNTU_NGINX_SYSTEMD.md` - 本番デプロイ手順

---

**ステータス**: 📋 ドキュメント完成  
**用途**: セットアップ時の確認チェックリスト  
**更新**: 不定期（問題発生時に追記）

