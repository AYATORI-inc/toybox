# 新規本番サーバーへの移行マスタープラン
日付: 2026/10/07 11:17 JST
**期限**: 今週中 (2026/10/11 までに完了)

## 📊 現在の状況

### 既存本番サーバー (160.251.168.144)

| 項目 | 値 | 状態 |
|------|-----|------|
| **IP** | 160.251.168.144 | 稼働中 |
| **OS** | Ubuntu 24.04.3 LTS | - |
| **ディスク** | 84.7% 使用 (98.24GB) | 🔴 逼迫 |
| **メモリ** | 84% 使用 | 🔴 逼迫 |
| **稼働時間** | 3ヶ月+ | ⚠️ システム再起動必要 |
| **Webサーバー** | Caddy (コンテナ) | ✅ 稼働中 |
| **アプリ** | Django + Gunicorn | ✅ 稼働中 |
| **DB** | PostgreSQL 15 | ✅ 稼働中 (3ヶ月) |
| **キャッシュ** | Redis 7 | ✅ 稼働中 (3ヶ月) |
| **Git** | ⚠️ コミットなし | ⚠️ 問題 |

### 新規本番サーバー (192.168.122.140)

| 項目 | 値 | 状態 |
|------|-----|------|
| **IP** | 192.168.122.140 | 準備中 |
| **OS** | Ubuntu 24.04.4 LTS | - |
| **ディスク** | 200GB (拡張済み) | ✅ 余裕あり |
| **構成** | Docker + git clone | ✅ セットアップ完了 |
| **Webサーバー** | Caddy | 構築予定 |
| **状態** | Phase 4: データリストア準備中 | 🔄 進行中 |

---

## 🎯 今週中の移行 5 ステップ実行計画

### 📌 前提条件（確認待ち）

```
[ ] Caddyfile の内容確認
[ ] docker-compose.prod.yml の確認
[ ] バックアップの取得 & 検証
[ ] 新規本番への最終テスト
[ ] DNS/Cloudflare 切替準備
```

---

### **ステップ 1: 既存本番の最終状態確認 (火曜朝)**

**実施時間**: 30分

```bash
# サーバーで実行
cd /var/www/toybox

# 1-1. 最新バックアップ取得
echo "=== バックアップ確認 ==="
ls -lh /var/www/toybox/backups/ 2>/dev/null || ls -lh ~/backups/

# 1-2. ログを確認（エラーなし確認）
docker logs toybox-web-1 2>&1 | grep -E "ERROR|CRITICAL" | tail -10

# 1-3. API ヘルスチェック
curl -s http://localhost:8000/api/health/ | python -m json.tool

# 1-4. ユーザー・データ数を確認
docker exec toybox-db-1 psql -U postgres -d toybox -c "SELECT COUNT(*) FROM auth_user;" 
docker exec toybox-db-1 psql -U postgres -d toybox -c "SELECT COUNT(*) FROM articles_article;"

# 1-5. ディスク/メモリ最終確認
df -h /var/www/toybox
free -h
```

**チェックリスト**:
- [ ] バックアップファイルが存在（.dump + media .tar.gz）
- [ ] API が 200 OK 応答
- [ ] ユーザー数 = ?? 件
- [ ] 記事数 = ?? 件

---

### **ステップ 2: 新規本番での事前テスト (火曜昼)**

**実施時間**: 45分

新規本番サーバーで：

```bash
ssh -i "キー" root@192.168.122.140

cd /var/www/toybox/backend

# 2-1. 全サービス起動確認
docker compose up -d
docker compose ps

# 2-2. データリストア実行（既存本番から取得したダンプ）
docker compose exec db pg_restore -U postgres -d toybox /tmp/toybox_backup.dump

# 2-3. API ヘルスチェック
curl -s http://localhost:8000/api/health/ | python -m json.tool

# 2-4. Caddy 設定テスト
# (Caddyfile コピー & 再起動)

# 2-5. 本番ドメインで HTTPS 確認
curl -s https://toybox-check.ayatori-inc.co.jp/api/health/
```

**チェックリスト**:
- [ ] 全コンテナ running
- [ ] DB データ復元成功
- [ ] API 応答 200 OK
- [ ] HTTPS 動作
- [ ] Caddy ログにエラーなし

---

### **ステップ 3: バックアップ最新取得 & 検証 (水曜朝)**

**実施時間**: 60分

既存本番から最新バックアップ取得：

```bash
ssh root@160.251.168.144

cd /var/www/toybox/scripts

# 3-1. DB ダンプ取得（最新）
bash backup_database.sh

# 3-2. メディアボリューム バックアップ
bash backup_media_from_prod.sh

# 3-3. 検証
ls -lh ~/backups/toybox_*.dump
ls -lh ~/backups/media_*.tar.gz

# ファイルサイズ記録
du -sh /var/www/toybox/backend/public/uploads
```

**重要**: 取得したバイナリファイルをローカル保管

**チェックリスト**:
- [ ] DB ダンプ生成完了 & ファイルサイズ ≥ 50MB（推定）
- [ ] メディア tar.gz 生成完了 & ファイルサイズ ≈ 5.8GB
- [ ] ローカル PC に両ファイル保存

---

### **ステップ 4: DNS/Cloudflare 準備 & テスト (水曜昼)**

**実施時間**: 30分

```bash
# 4-1. Cloudflare DNS 確認
# 現在: 160.251.168.144 -> toybox.ayatori-inc.co.jp
# 予定: 192.168.122.140 -> toybox.ayatori-inc.co.jp

# 4-2. 新規本番で最終テスト
ssh -i "キー" root@192.168.122.140
curl -s https://toybox-check.ayatori-inc.co.jp/api/health/

# 4-3. Caddy HTTPS 設定確認
docker exec toybox-caddy-1 caddy version

# 4-4. ドメイン切替準備
# Cloudflare で DNS A レコード切替準備
```

**チェックリスト**:
- [ ] 新規本番で HTTPS 動作確認
- [ ] Caddy ログ確認（エラーなし）
- [ ] DNS TTL を短く（300秒程度に）

---

### **ステップ 5: 本番切替 & 検証 (木曜夜 or 金曜朝)**

**実施時間**: 90分（ダウンタイム含む 5-10 分）

#### フェーズ A: ダウンタイム前準備

```bash
# 5-1. 既存本番で最後のバックアップ
ssh root@160.251.168.144
cd /var/www/toybox && docker compose exec db pg_dump -U postgres toybox > /tmp/toybox_final.dump

# 5-2. 新規本番へ最新データ復元
scp /tmp/toybox_final.dump root@192.168.122.140:/tmp/
ssh root@192.168.122.140
docker compose exec -T db pg_restore -U postgres -d toybox /tmp/toybox_final.dump

# 5-3. 新規本番で検証
curl -s http://localhost:8000/api/health/
```

#### フェーズ B: DNS 切替（ダウンタイム）

```
【手作業】Cloudflare で以下を実行:
1. A レコード切替: 160.251.168.144 → 192.168.122.140
2. 待機時間: 5 分（TTL 更新待ち）
```

#### フェーズ C: ダウンタイム後検証

```bash
# 5-4. 外部ネットワークから検証
curl -s https://toybox.ayatori-inc.co.jp/api/health/

# 5-5. 管理画面ログイン確認
# ブラウザ: https://toybox.ayatori-inc.co.jp/admin/

# 5-6. ユーザーデータ確認
ssh root@192.168.122.140
docker exec toybox-db-1 psql -U postgres -d toybox -c "SELECT COUNT(*) FROM auth_user;"

# 5-7. Caddy ログ確認
docker logs toybox-caddy-1 2>&1 | tail -30
```

**チェックリスト**:
- [ ] DNS レコード切替完了
- [ ] API 応答 200 OK
- [ ] 管理画面ログイン OK
- [ ] ユーザー数 = ?? 件（既存と同じ）
- [ ] Caddy ログにエラーなし

---

### **ステップ 6: 既存本番の後処理 (金曜午後)**

**実施時間**: 30分

```bash
ssh root@160.251.168.144

# 6-1. 既存本番を停止（万が一のロールバック用に保持）
cd /var/www/toybox
docker compose down

# 6-2. データを保存（90日間保管）
tar -czf /backup/toybox-old-prod-20261007.tar.gz /var/www/toybox/

# 6-3. 確認
echo "既存本番を停止しました。新規本番が正常に稼働していることを確認後、1週間後に削除予定。"
```

---

## 📋 時系列スケジュール

| 日時 | ステップ | 内容 | 時間 |
|------|---------|------|------|
| **火 朝** | 1 | 既存本番の最終確認 | 30分 |
| **火 昼** | 2 | 新規本番の事前テスト | 45分 |
| **水 朝** | 3 | 最新バックアップ取得 & 検証 | 60分 |
| **水 昼** | 4 | DNS/Cloudflare 準備 | 30分 |
| **木夜/金朝** | 5 | **本番切替** ⚡ | 90分 |
| **金 午後** | 6 | 既存本番停止 & 保管 | 30分 |

**合計時間**: 4時間 45分（スプレッド可能）  
**ダウンタイム**: 5-10 分（DNS 切替時）

---

## ⚠️ リスク管理

### リスク 1: ディスク容量不足（既存本番）

**状況**: 84.7% 使用中 → バックアップ取得でさらに逼迫

**対策**:
- [ ] バックアップをローカルに即座に転送
- [ ] 既存本番で不要な古いコンテナイメージ削除
- [ ] `docker system prune -a` 実行

### リスク 2: DNS 切替後に新規本番が起動しない

**対策**:
- [ ] ロールバック計画: 既存本番の Docker を即座に restart できる状態に
- [ ] 新規本番で本番切替前に 1 時間フル稼働テスト

### リスク 3: メディアボリューム (5.8GB) 復元失敗

**対策**:
- [ ] 新規本番で `tar -xzf` テスト実施済みか確認
- [ ] 権限設定: `sudo chown -R app:app /var/www/toybox/backend/public/uploads`

### リスク 4: Celery (worker/beat) 失敗

**対策**:
- [ ] 既存本番の Celery ログ確認
- [ ] 新規本番で Celery 起動前に DB マイグレーション完了確認

---

## 📞 連絡先・確認事項

### 即座に確認が必要な項目

1. **Caddyfile の内容**: HTTPS 設定、ドメイン名
2. **docker-compose.prod.yml**: イメージ定義、ボリューム設定
3. **バックアップスクリプト**: 実行可能か確認
4. **Cloudflare 管理者アカウント**: DNS 切替が可能か
5. **新規本番の Caddy 設定**: copyして使えるか、もしくは構築予定か

### 想定問題と回避策

| 問題 | 回避策 |
|------|--------|
| Caddy HTTPS 証明書更新失敗 | 事前に Let's Encrypt 更新テスト |
| メディア 復元時間が長い | 事前に tar 展開速度テスト |
| ユーザーがアクセスできない | DNS TTL 短縮 & 監視 |

---

## ✅ 実行前チェックリスト（今週中実行前）

**月曜夜 or 火曜朝に確認**:

- [ ] Caddyfile 内容確認
- [ ] docker-compose.prod.yml 確認
- [ ] ディスク容量確保（既存本番で 20GB 以上削除）
- [ ] バックアップスクリプト動作確認
- [ ] 新規本番へ最新データリストア完了
- [ ] Caddy + SSL 動作確認
- [ ] ロールバック計画確認
- [ ] チーム内通知（ユーザーへの事前告知なし推奨）

---

**ステータス**: 📋 移行計画確定  
**開始**: 火曜朝  
**完了**: 金曜午後  
**ダウンタイム**: 5-10 分（木曜夜 or 金曜朝）  

**推奨**: 金曜朝 9:00 に本番切替を実施（業務時間内で監視可能）

