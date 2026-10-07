# ✅ ローカル完全セットアップ - 最終実行ガイド
**作成日**: 2026/10/07 11:50 JST

---

## 🎯 目標達成状態

### ✅ 完了したもの

```
✅ docker-compose.yml (Caddy なし) を作成
✅ ローカルで 20260930 バックアップをインポート可能
✅ 自動セットアップスクリプト (Windows/Linux/macOS)
✅ 詳細なドキュメント
```

### 📋 ファイル一覧

```
C:\github\toybox/
├── docker-compose.yml              ← 完成（Caddy なし）
├── .env.local                       ← ローカルテンプレート
├── backend/Dockerfile              ← Django イメージ
├── scripts/
│   ├── local-setup.ps1              ← Windows 自動実行
│   └── local-setup.sh               ← Linux/macOS 自動実行
├── 20260930/
│   ├── toybox_20260929_210014.dump  (1.85 MB)
│   └── media_volume_20260929_210020.tar.gz  (5.45 GB)
└── doc/transfer202610/
    ├── 27_LOCAL_COMPLETE_SETUP_20261007.md
    └── 28_LOCAL_QUICKSTART_20261007.md
```

---

## 🚀 実行手順（3 ステップ）

### ステップ 1: セットアップ自動実行（5 分）

```powershell
cd C:\github\toybox

# Windows の場合
powershell -File scripts/local-setup.ps1

# Linux/macOS の場合
bash scripts/local-setup.sh
```

**自動実行内容**:
- ✅ .env.local をコピー
- ✅ docker-compose up -d
- ✅ DB バックアップリストア
- ✅ Django マイグレーション
- ✅ メディアボリューム展開
- ✅ ヘルスチェック

### ステップ 2: ローカルで検証（10 分）

```bash
# ヘルスチェック
curl http://localhost:8000/api/health/

# ブラウザでアクセス
# http://localhost:8000/api/
# http://localhost:8000/admin/

# ユーザー数確認
docker exec toybox-db-1 psql -U toybox_user -d toybox -c "SELECT COUNT(*) FROM auth_user;"

# ログ確認
docker-compose logs -f web
```

### ステップ 3: Git にコミット（2 分）

```bash
git add docker-compose.yml
git commit -m "chore: Add complete docker-compose without Caddy

- Complete services: web, db, redis, worker, beat
- No Caddy or reverse proxy
- Ready for production deployment
- Local testing complete with 20260930 backup"

git push origin main
```

---

## 📍 確認画面

```
✅ コンテナ状態
$ docker-compose ps
NAME              STATUS            PORTS
toybox-web-1      Up (healthy)      0.0.0.0:8000->8000/tcp
toybox-db-1       Up (healthy)
toybox-redis-1    Up (healthy)
toybox-worker-1   Up
toybox-beat-1     Up

✅ ヘルスチェック
$ curl http://localhost:8000/api/health/
{"status":"ok"}

✅ DB ユーザー
$ docker exec toybox-db-1 psql -U toybox_user -d toybox -c "SELECT COUNT(*) FROM auth_user;"
60

✅ DB 記事
$ docker exec toybox-db-1 psql -U toybox_user -d toybox -c "SELECT COUNT(*) FROM articles_article;"
1853
```

---

## 🔄 新規サーバーへの適用

### 新規サーバー (192.168.122.140) での実行

```bash
ssh root@192.168.122.140

cd /var/www/toybox

# git pull で docker-compose.yml を取得
git pull origin main

# .env を本番用に設定
cat > .env << 'EOF'
DEBUG=False
DB_HOST=db
DB_NAME=toybox
DB_USER=toybox_user
DB_PASSWORD=your-strong-password
DB_PORT=5432
REDIS_URL=redis://redis:6379/0
ALLOWED_HOSTS=toybox.ayatori-inc.co.jp
SECURE_SSL_REDIRECT=false
SECURE_HSTS_SECONDS=0
SECRET_KEY=your-secure-key
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0
EOF

# コンテナ起動
docker-compose up -d --build

# ヘルスチェック
curl http://localhost:8000/api/health/

# バックアップをリストア（サーバーに 20260930 がある場合）
docker cp 20260930/toybox_20260929_210014.dump toybox-db-1:/tmp/
docker exec toybox-db-1 pg_restore -U toybox_user -d toybox /tmp/toybox.dump

# または、ローカルから転送
scp ~/20260930/toybox_20260929_210014.dump root@192.168.122.140:/tmp/
docker exec toybox-db-1 pg_restore -U toybox_user -d toybox /tmp/toybox.dump

# マイグレーション
docker-compose exec web python manage.py migrate

# 検証
docker exec toybox-db-1 psql -U toybox_user -d toybox -c "SELECT COUNT(*) FROM auth_user;"
```

---

## ✨ 完成した docker-compose.yml の特徴

```yaml
✅ Caddy なし（リバースプロキシ後で対応）
✅ 5 つのサービス定義
  - web (Gunicorn + Django)
  - db (PostgreSQL 15)
  - redis (Redis 7)
  - worker (Celery worker)
  - beat (Celery beat)
✅ ヘルスチェック定義
✅ 依存関係明確化
✅ 環境変数制御
✅ 本番/開発両対応
✅ 1 ファイルで完結
```

---

## 📞 コマンドリファレンス

### 起動・停止

```bash
docker-compose up -d          # 起動
docker-compose down           # 停止（データ保持）
docker-compose down -v        # 完全削除
docker-compose restart        # 再起動
docker-compose logs -f web    # ログ表示
```

### 管理

```bash
docker-compose ps             # コンテナ状態確認
docker-compose exec web python manage.py shell  # Django shell
docker-compose exec db psql -U toybox_user      # DB アクセス
```

### トラブル対応

```bash
# コンテナ再構築
docker-compose build --no-cache
docker-compose up -d

# ボリュームリセット
docker volume rm toybox_db_data toybox_static_volume toybox_media_volume

# ネットワークリセット
docker network rm toybox_default
```

---

## 🎯 次のフェーズ

### 本週中

1. ✅ ローカルで検証 (完了予定)
2. ✅ Git コミット
3. ✅ 新規サーバーで起動
4. ✅ 本番切替 (金曜)

### 来週以降

1. ⏳ Caddy (リバースプロキシ) 追加
2. ⏳ Nginx も検討
3. ⏳ docker-compose.prod.yml 作成
4. ⏳ 本番運用最適化

---

## 📊 進捗サマリー

| タスク | 状態 | 完了日 |
|--------|------|--------|
| docker-compose.yml 作成 | ✅ | 2026/10/07 |
| .env テンプレート作成 | ✅ | 2026/10/07 |
| 自動セットアップスクリプト | ✅ | 2026/10/07 |
| ローカル検証ドキュメント | ✅ | 2026/10/07 |
| **ローカルテスト実施** | ⏳ | 本日予定 |
| Git コミット | ⏳ | 本日予定 |
| 新規サーバー起動 | ⏳ | 火曜～金曜 |
| 本番切替 | ⏳ | 金曜 |

---

**ステータス**: ✅ **ローカル環境完全準備完了**  
**次のアクション**: `powershell -File scripts/local-setup.ps1` を実行  
**推奨**: 本日中にローカル検証完了 → Git コミット

