# リポジトリリファクタリング - Phase 2
**作成日**: 2026/10/07 11:52 JST

---

## 🎯 タイミング

### Phase 1: ローカルで docker-compose テスト（本日）
```
✅ scripts/local-setup.ps1 実行
✅ docker-compose で全サービス起動確認
✅ 20260930 バックアップ インポート確認
✅ API ヘルスチェック OK
```

### Phase 2: リファクタリング（本日～明日）
```
⏳ 不要ファイル削除
⏳ git commit で Clean な状態に
⏳ 新規サーバーで実行
```

---

## 🗑️ 削除対象ファイル一覧

### ルートディレクトリの不要ファイル

```
C:\github\toybox\
├── docker-compose.prod.yml        ❌ 削除対象
│                                   理由: Caddy のみで未完成
│
├── Dockerfile.caddy                ❌ 削除対象
│                                   理由: Caddy なし構成のため
│
├── Caddyfile                       ❌ 削除対象
│                                   理由: 本番用（新規サーバー後に再構築）
│
├── Caddyfile.backup*               ❌ 削除対象（複数）
│                                   理由: 古いバージョン
│
├── restore_caddyfile.sh            ❌ 削除対象
│                                   理由: Caddy 関連スクリプト
│
└── （その他の古い .sh ファイル）  ❌ 削除対象
```

### backend/ ディレクトリの不要ファイル

```
C:\github\toybox\backend\
├── RESTORE_DATA_GUIDE.md           ⚠️  判断待ち
│                                   理由: データ復元ガイド（参考資料か削除か）
│
├── REFACTORING_SUMMARY.md          ⚠️  判断待ち
│                                   理由: 古いリファクタリング記録
│
└── Dockerfile.prod                 ⚠️  判断待ち
                                   理由: 本番用 Dockerfile（保持する？）
```

### ゴミファイル

```
C:\github\toybox\
├── =
├── [beat
├── CACHED
├── CANCELED
├── ERROR
├── [internal]
├── reading
├── transferring
├── [web
└── [worker

理由: 空のキャッシュ/ステータスファイル
```

---

## ✅ リファクタリング実行手順

### ステップ 1: Docker テスト確認（前提条件）

```bash
# これらが全て成功していることを確認
curl http://localhost:8000/api/health/    # ← {"status":"ok"}
docker-compose ps                          # ← 全て Up or healthy
docker exec toybox-db-1 psql -U toybox_user -d toybox -c "SELECT COUNT(*) FROM auth_user;"  # ← 60
```

**テストが OK なら次に進む**

### ステップ 2: 不要ファイルを確認 & 削除

```powershell
cd C:\github\toybox

# リスト: 削除予定ファイル
@(
    'docker-compose.prod.yml',
    'Dockerfile.caddy',
    'Caddyfile',
    'Caddyfile.backup',
    'Caddyfile.backup.20260119_152430',
    'Caddyfile.backup.20260119_152650',
    'restore_caddyfile.sh',
    'deploy',        # 古いデプロイフォルダ？
    '=',
    '[beat',
    'CACHED',
    'CANCELED',
    'ERROR',
    '[internal]',
    'reading',
    'transferring',
    '[web',
    '[worker'
) | ForEach-Object {
    if (Test-Path $_) {
        Write-Host "❌ 削除: $_" -ForegroundColor Red
        Remove-Item $_ -Force -ErrorAction SilentlyContinue
    }
}

# 確認
Write-Host "`n✅ 削除完了。現在のファイル:" -ForegroundColor Green
Get-ChildItem -Path . -File | Where-Object {$_.Name -NotMatch "^\."} | Select-Object Name
```

### ステップ 3: Backend ディレクトリの判断

```bash
# 確認: 本当に削除していいか？
ls -la backend/ | grep -E "Dockerfile|\.md"

# 以下について判断:
# - RESTORE_DATA_GUIDE.md: 保持？削除？
# - REFACTORING_SUMMARY.md: 保持？削除？
# - Dockerfile.prod: 保持？削除？
```

### ステップ 4: .gitignore を確認 & 更新

```bash
cat .gitignore

# 確認: 以下が含まれているか
# .env          ← 機密情報
# .env.local    ← テンプレート（commit 対象）
# 20260930/     ← バックアップ（commit しない）
```

### ステップ 5: Git で確認

```bash
# 削除されたファイルを確認
git status

# 出力例:
# deleted: docker-compose.prod.yml
# deleted: Caddyfile
# ...
```

### ステップ 6: Git にコミット

```bash
# ステージング
git add -A

# 削除と新規ファイルを確認
git status

# コミット（分割推奨）

# 1. Caddy 関連を削除
git commit -m "chore: Remove Caddy-related files

- Remove docker-compose.prod.yml (incomplete)
- Remove Caddyfile and backups
- Remove restore_caddyfile.sh
- Caddy will be added later as reverse proxy"

# 2. 不要な古いファイルを削除
git commit -m "chore: Clean up old deployment files

- Remove deploy folder (old scripts)
- Remove cache/status files
- Keep only essential files"

# 3. 新規 docker-compose.yml とセットアップスクリプトを追加
git commit -m "chore: Add complete docker-compose and setup scripts

- Add docker-compose.yml (Caddy-less)
- Add local-setup.ps1 and local-setup.sh
- Add .env.local template
- Tested with 20260930 backup"
```

### ステップ 7: Push

```bash
git push origin main
```

---

## 📋 削除判断マトリックス

| ファイル | 必要か | 判定 | 理由 |
|---------|--------|------|------|
| **docker-compose.yml** | ✅ | 保持 | 本番用（新規作成） |
| docker-compose.prod.yml | ❌ | 削除 | Caddy のみで不完全 |
| Dockerfile | ✅ | 保持 | Django イメージ用 |
| Dockerfile.caddy | ❌ | 削除 | Caddy なし構成 |
| Caddyfile | ❌ | 削除 | Caddy なし構成 |
| Caddyfile.backup* | ❌ | 削除 | 古いバージョン |
| .env.local | ✅ | 保持 | テンプレート用 |
| .env | ⚠️ | 無視 | .gitignore で除外 |
| 20260930/ | ⚠️ | 無視 | .gitignore で除外 |
| scripts/local-setup.* | ✅ | 保持 | 新規作成 |
| scripts/backup_*.sh | ❓ | 検討 | 古い？新しい？ |
| scripts/deploy.sh | ❓ | 検討 | 古い？新しい？ |
| backend/RESTORE_* | ❓ | 検討 | 参考資料？ |
| deploy/ | ❌ | 削除 | 古いフォルダ |
| ゴミファイル (* =, [beat等) | ❌ | 削除 | キャッシュ |

---

## 🎯 削除結果イメージ

### Before（現在）

```
C:\github\toybox\
├── docker-compose.yml              ✅
├── docker-compose.prod.yml         ❌
├── Dockerfile                       ✅
├── Dockerfile.caddy                ❌
├── Caddyfile                       ❌
├── Caddyfile.backup*               ❌
├── restore_caddyfile.sh            ❌
├── =                               ❌
├── [beat, CACHED, CANCELED, etc.   ❌
├── .env.local                       ✅
├── .env                             (無視)
├── 20260930/                        (無視)
├── scripts/
│   ├── local-setup.ps1              ✅
│   ├── local-setup.sh               ✅
│   └── backup_*.sh                  (要確認)
└── doc/transfer202610/              ✅
```

### After（リファクタリング後）

```
C:\github\toybox/
├── docker-compose.yml              ✅
├── Dockerfile                       ✅
├── .env.local                       ✅
├── backend/
│   ├── Dockerfile
│   ├── manage.py
│   ├── requirements.txt
│   └── ...
├── scripts/
│   ├── local-setup.ps1
│   ├── local-setup.sh
│   └── ...
└── doc/transfer202610/
```

---

## ✅ チェックリスト

### ローカルテスト（前提）

- [ ] `local-setup.ps1` で完全セットアップ完了
- [ ] `docker-compose ps` で全サービス running/healthy
- [ ] `curl http://localhost:8000/api/health/` → OK
- [ ] DB ユーザー数 60 確認
- [ ] メディア 5.45 GB 展開確認

### リファクタリング実行

- [ ] 削除対象ファイルリスト確認
- [ ] 不要ファイル削除実施
- [ ] `git status` で変更確認
- [ ] `git commit` で段階的にコミット
- [ ] `git push origin main`

### 新規サーバー準備

- [ ] 新規サーバーで `git pull origin main`
- [ ] `docker-compose.yml` が正しく取得されたか確認
- [ ] `docker-compose up -d --build` で起動
- [ ] API ヘルスチェック確認

---

## 📞 判断が必要なファイル

### scripts/backup_*.sh

```bash
# 質問: 古いスクリプト？それとも本番で使用？

# 確認方法
grep -r "backup_database.sh" doc/

# 結果: RESTORE_DATA_GUIDE.md などに記載されていたら保持
# 結果: 使用されていなかったら削除
```

### backend/RESTORE_DATA_GUIDE.md

```bash
# 質問: ドキュメント参考資料？それとも削除？

# 判定:
# - ローカルテストで不要 → 削除
# - 新規サーバーでリストア手順として必要 → 保持
```

---

**ステータス**: 📋 リファクタリング計画完成  
**実行タイミング**: ローカルテスト完了後  
**推奨**: 本日中に実施 → 明日の本番切替に向けて clean な状態に

