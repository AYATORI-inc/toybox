# 今週中の移行実行チェックシート
日付: 2026/10/07 11:20 JST

## 🚨 即座に確認すべき重要項目

### 1. 既存本番サーバーの状態（確認済み）

✅ **OK** の項目:
- Docker 全コンテナ稼働中（toybox-* セット）
- PostgreSQL/Redis 稼働中（3ヶ月以上）
- Caddy がポート 80/443 でリッスン

⚠️ **要確認** の項目:
- [ ] Caddyfile の内容（HTTPS 設定、Let's Encrypt など）
- [ ] docker-compose.prod.yml の内容（どっちを使ってるのか）
- [ ] Git リモート（GitHub? Cursor Origin?）
- [ ] backend-web-1 の目的（なぜ起動されたのか）
- [ ] backend-worker/beat が Exited している理由

🔴 **問題** の項目:
- Git に **コミットなし** → これは何を意味するのか？
- ディスク 84.7% 使用中 → 容量逼迫
- メモリ 84% + Swap 54% → リソース不足

---

## 📋 本番切替前に必ず実施すべきこと

### Phase A: 情報収集（今すぐ）

```bash
# ===== 最重要：残り設定ファイル取得 =====
cd /var/www/toybox

# 1. Caddyfile
cat Caddyfile

# 2. docker-compose.prod.yml
cat docker-compose.prod.yml

# 3. Git リモート確認
git remote -v
git status

# 4. ディスク内訳（uploads のサイズ確認）
du -sh /var/www/toybox/backend/public/uploads
du -sh /var/www/toybox/static
du -sh /var/www/toybox/staticfiles

# 5. ロールバック用：本番環境の完全スナップショット
docker compose config > /tmp/toybox-prod-docker-compose.yml

# 6. Caddy 設定バックアップ
cp Caddyfile /tmp/Caddyfile.backup.20261007

# 7. .env バックアップ（機密情報注意）
cp .env /tmp/.env.backup.20261007

# 8. 本番 DB ユーザー確認
docker exec toybox-db-1 psql -U postgres -c "\du"

# 9. 本番ユーザー/記事数確認
docker exec toybox-db-1 psql -U postgres -d toybox -c "SELECT COUNT(*) as users FROM auth_user;"
docker exec toybox-db-1 psql -U postgres -d toybox -c "SELECT COUNT(*) as articles FROM articles_article;"
docker exec toybox-db-1 psql -U postgres -d toybox -c "SELECT COUNT(*) as reactions FROM reactions_reaction;"
```

### Phase B: バックアップ取得（火曜朝）

```bash
# 既存本番で最新バックアップ作成
cd /var/www/toybox/scripts

# DB ダンプ取得
bash backup_database.sh
ls -lh ~/backups/toybox_*.dump

# メディア バックアップ
bash backup_media_from_prod.sh
ls -lh ~/backups/media_*.tar.gz

# ローカル PC に SCP で転送
# scp root@160.251.168.144:~/backups/toybox_*.dump C:\Users\ayato\Downloads\
# scp root@160.251.168.144:~/backups/media_*.tar.gz C:\Users\ayato\Downloads\
```

### Phase C: 新規本番へのリストア & テスト（水曜朝）

```bash
# 新規本番で
ssh root@192.168.122.140

cd /var/www/toybox/backend

# 全サービス起動
docker compose up -d

# ダンプをコピー
# scp root@160.251.168.144:~/backups/toybox_*.dump /tmp/

# DB リストア
docker compose exec -T db pg_restore -U postgres -d toybox /tmp/toybox_*.dump

# メディア復元
tar -xzf ~/backups/media_*.tar.gz -C /var/www/toybox/backend/public/

# 権限修正
docker compose exec -T web python manage.py collectstatic --noinput

# API テスト
curl -s http://localhost:8000/api/health/ | python -m json.tool
```

### Phase D: DNS 切替（木曜夜 or 金曜朝）

```
【Cloudflare で実行】
1. A レコード: 160.251.168.144 → 192.168.122.140 に変更
2. TTL を短く設定（事前に 300秒程度）
3. DNS 更新待機（5分程度）

【切替後の検証】
curl -s https://toybox.ayatori-inc.co.jp/api/health/
ブラウザで https://toybox.ayatori-inc.co.jp にアクセス
```

---

## 🔧 重要な設定・ファイル位置

| 項目 | 位置 | 用途 |
|------|------|------|
| **環境変数** | `/var/www/toybox/.env` | Django 設定 |
| **Caddy 設定** | `/var/www/toybox/Caddyfile` | リバースプロキシ & SSL |
| **Docker 定義** | `/var/www/toybox/docker-compose.yml` | 開発用 |
| **Docker 本番** | `/var/www/toybox/docker-compose.prod.yml` | 本番用 |
| **メディア** | `/var/www/toybox/backend/public/uploads/` | ユーザーアップロード |
| **スタティック** | `/var/www/toybox/staticfiles/` | Django static files |
| **Git** | `/var/www/toybox/.git/` | バージョン管理 |
| **バックアップ** | `/backups/` or `~/backups/` | DB & メディア |

---

## 📞 情報取得の優先順序

### 🔴 超重要（今すぐ）

1. **Caddyfile** の内容確認
   - ドメイン: `toybox.ayatori-inc.co.jp`?
   - SSL 設定: Let's Encrypt? 自己署名?
   - ターゲット: `localhost:8000`?

2. **docker-compose.prod.yml** の確認
   - 本番環境は何を参照しているのか
   - ボリューム設定
   - ネットワーク設定

3. **Git リモート** の確認
   - GitHub? Cursor Origin?
   - なぜコミットがないのか

4. **uploads フォルダサイズ** の確認
   - 5.8GB は本当か？
   - 実際のサイズは？

### 🟠 重要（火曜朝）

5. 本番ユーザー/記事/リアクション数
6. バックアップスクリプトの動作確認
7. ディスク容量の空き状態

### 🟡 確認事項（水曜朝）

8. 新規本番での Caddy 構築状況
9. Celery (worker/beat) の状態

---

## ⏰ 最短スケジュール（ダウンタイム最小化）

| 時間 | 作業 |
|------|------|
| **火 09:00** | ✅ 既存本番のログ & 設定確認 |
| **火 10:00** | ✅ 最新バックアップ開始 |
| **火 11:00** | ✅ 新規本番へリストア & テスト |
| **水 09:00** | ✅ DNS TTL 短縮 |
| **金 13:00** | ⚡ **DNS 切替実行**（ダウンタイム 5分） |
| **金 14:00** | ✅ 検証 & 完了 |

**合計ダウンタイム**: 5-10 分
**総作業時間**: 3-4 時間（分散可）

---

## 🆘 トラブルシューティング（事前対応）

### Q1. backend-web-1 が Exited している理由は？

**推測**:
- テスト環境として起動されたが、Celery が失敗して停止
- Celery が起動時に DB 接続に失敗

**対応**:
- ログ確認: `docker logs backend-web-1`
- **これは本番切替には影響しない**（toybox-web-1 が稼働していれば OK）

### Q2. Git にコミットがないのはなぜ？

**推測**:
- ブランチが `master` だが、まだコミットされていない
- または、本番サーバーは git clone されてない

**対応**:
- 新規本番は git clone をしたはずなので、そちらを使用

### Q3. ディスクが 84.7% 使用中。バックアップ取得時に溢れるのでは？

**対策**:
- バックアップ取得後、即座にローカルに転送
- 不要な古い Docker イメージ削除: `docker system prune -a`
- 既存本番で停止後に削除可能

### Q4. メディアボリュームが 5.8GB。新規本番に復元できるか？

**確認**:
- 新規本番のディスク: 200GB（余裕あり）
- tar -xzf で展開テスト実施予定

---

## ✅ 最終チェックリスト

### 本番切替前にすべて ✅ にすること

```
【火曜朝に確認】
- [ ] 既存本番の全ログ確認（エラーなし）
- [ ] Caddyfile 内容確認
- [ ] docker-compose.prod.yml 確認
- [ ] Git リモート確認
- [ ] uploads 実際のサイズ確認

【火曜昼に実施】
- [ ] 最新バックアップ取得
- [ ] バックアップ検証
- [ ] ローカル PC に保存

【水曜朝に実施】
- [ ] 新規本番へリストア
- [ ] API テスト成功
- [ ] Caddy HTTPS テスト成功

【金曜朝に実施】
- [ ] 最終バックアップ取得
- [ ] DNS TTL 短縮
- [ ] ロールバック計画確認

【本番切替】
- [ ] DNS A レコード切替
- [ ] 5分待機（TTL 反映待ち）
- [ ] 外部から https://toybox.ayatori-inc.co.jp にアクセス確認
- [ ] ログ確認（エラーなし）
```

---

**ステータス**: 📋 チェックシート完成  
**次のアクション**: サーバーから設定ファイル取得  
**タイムライン**: 本週中完了可能

