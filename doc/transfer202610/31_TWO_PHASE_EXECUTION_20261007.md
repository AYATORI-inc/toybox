# 実行フロー - 2段階リファクタリング
**作成日**: 2026/10/07 11:55 JST

---

## 🎯 全体フロー

```
【本日】
Step 1: local-setup.ps1 実行
  → docker-compose で完全に動作確認
  → 20260930 バックアップ インポート確認

Step 2: cleanup-refactoring.ps1 実行
  → 不要ファイル削除
  → リポジトリを primitive な状態に

Step 3: Git コミット
  → docker-compose.yml を commit
  → 新規サーバーへ持っていく準備完了

【本週火曜～金曜】
Step 4: 本番切替
  → 新規サーバーで docker-compose を実行
  → 20260930 バックアップをリストア
```

---

## 📌 実行スケジュール

### 【本日 11:55】

#### Step 1: ローカルテスト（5 分）

```powershell
cd C:\github\toybox

# 自動セットアップ実行
powershell -File scripts/local-setup.ps1

# 動作確認
curl http://localhost:8000/api/health/
# 期待: {"status":"ok"}
```

#### Step 2: リファクタリング（3 分）

```powershell
# 不要ファイル削除
powershell -File scripts/cleanup-refactoring.ps1

# 確認
git status
# 削除されたファイルが表示される
```

#### Step 3: Git コミット（5 分）

```powershell
# ステージング
git add -A

# コミット（分割推奨）
git commit -m "chore: Remove Caddy-related files

- Remove docker-compose.prod.yml (incomplete)
- Remove Caddyfile and backups
- Remove restore_caddyfile.sh"

git commit -m "chore: Clean up old files

- Remove old deployment scripts
- Remove cache/status files
- Clean repository state"

git commit -m "chore: Add docker-compose and setup scripts

- Add docker-compose.yml (Caddy-less, complete)
- Add local-setup.ps1 and setup.sh
- Add .env.local template
- Tested with 20260930 backup"

# プッシュ
git push origin main
```

---

## ✅ 確認ポイント

### After local-setup.ps1

```
✅ docker-compose ps で全サービス running/healthy
✅ curl http://localhost:8000/api/health/ → {"status":"ok"}
✅ DB ユーザー数 60 確認
✅ メディアファイル展開確認 (5.45 GB)
```

### After cleanup-refactoring.ps1

```
✅ 古い Caddyfile 削除
✅ docker-compose.prod.yml 削除
✅ ゴミファイル (=, [beat など) 削除
✅ git status で削除ファイルが表示される
```

### After git push

```
✅ GitHub/Origin で削除が反映
✅ docker-compose.yml のみが残る（Caddy なし）
✅ 新規サーバーで git pull で取得可能
```

---

## 🔄 新規サーバーでの実行

### 火曜～水曜（本番前準備）

```bash
ssh root@192.168.122.140

cd /var/www/toybox

# git pull で Clean な docker-compose.yml を取得
git pull origin main

# .env を本番用に設定
cat > .env << 'EOF'
DEBUG=False
DB_HOST=db
DB_NAME=toybox
DB_USER=toybox_user
DB_PASSWORD=strong-password
REDIS_URL=redis://redis:6379/0
ALLOWED_HOSTS=toybox.ayatori-inc.co.jp
SECRET_KEY=secure-key
EOF

# コンテナ起動
docker-compose up -d --build

# 確認
curl http://localhost:8000/api/health/
```

### 金曜朝（本番切替）

```bash
# バックアップをリストア（ローカル PC から送付）
scp ~/20260930/toybox_20260929_210014.dump root@192.168.122.140:/tmp/
docker exec toybox-db-1 pg_restore -U toybox_user -d toybox /tmp/toybox.dump

# マイグレーション
docker-compose exec web python manage.py migrate

# 最終確認
docker exec toybox-db-1 psql -U toybox_user -d toybox -c "SELECT COUNT(*) FROM auth_user;"
# 期待: 60

# DNS 切替
# (Cloudflare で 160.251.168.144 → 192.168.122.140)
```

---

## 📊 ファイル数削減

### Before リファクタリング

```
ファイル数: 15+ (ゴミ含む)
主要な不要ファイル:
  - docker-compose.prod.yml
  - Dockerfile.caddy
  - Caddyfile*
  - restore_caddyfile.sh
  - ゴミファイル 10+ 個
```

### After リファクタリング

```
ファイル数: 5~7 (clean)
保持ファイル:
  - docker-compose.yml ✅
  - Dockerfile ✅
  - .env.local ✅
  - scripts/*.ps1, *.sh ✅
```

---

## 🎯 最終確認チェックリスト

### 【本日実行】

- [ ] local-setup.ps1 実行完了
- [ ] docker-compose ps で全 running/healthy 確認
- [ ] API ヘルスチェック OK
- [ ] DB データ確認 (60 ユーザー)
- [ ] メディア展開確認
- [ ] cleanup-refactoring.ps1 実行完了
- [ ] 不要ファイル削除確認
- [ ] git add -A
- [ ] git commit (複数回に分割)
- [ ] git push origin main
- [ ] GitHub で docker-compose.yml が残っていることを確認

### 【火曜～金曜実行】

- [ ] 新規サーバーで git pull
- [ ] docker-compose up -d --build
- [ ] ヘルスチェック OK
- [ ] バックアップリストア
- [ ] DB データ確認
- [ ] DNS 切替
- [ ] 本番で API 動作確認

---

## 📝 コマンドクイックリファレンス

```bash
# ローカルテスト
powershell -File scripts/local-setup.ps1

# リファクタリング
powershell -File scripts/cleanup-refactoring.ps1

# Git コミット
git add -A
git commit -m "description"
git push origin main

# 新規サーバー
ssh root@192.168.122.140
cd /var/www/toybox
git pull origin main
docker-compose up -d --build
```

---

**ステータス**: ✅ 2段階実行ガイド完成  
**推奨**: 本日中に両ステップを実施  
**結果**: Clean で primitive な docker-compose 環境が新規サーバーで動作

