# 📋 本週中の移行 - 実行ガイド＆チェックシート
**作成日**: 2026/10/07 11:22 JST  
**期限**: 2026/10/11 (今週金曜)

---

## 🎯 事前準備完了項目

### ✅ 既存本番の完全把握
- Caddyfile 設定
- docker-compose.prod.yml
- ディスク/メモリ状況
- ログ確認（エラーなし）
- Git リモート確認

### ✅ 新規本番の準備
- Docker セットアップ完了
- Python/PostgreSQL/Redis 稼働中
- Django マイグレーション完了
- テストデータ (60ユーザー、277記事) リストア完了

### ✅ ドキュメント作成完了
- 7 つの実行ガイドドキュメント
- 構成図・ビジュアルマップ
- チェックリスト

---

## 📅 本週中の実行スケジュール

### 【火曜日】

#### 朝 09:00-10:00
```
タスク: 既存本番の最終確認

☐ SSH 接続確認
  ssh -i "キー" root@160.251.168.144

☐ ユーザー/記事数を記録（重要）
  docker exec toybox-db-1 psql -U postgres -d toybox \
    -c "SELECT 'users', COUNT(*) FROM auth_user 
        UNION SELECT 'articles', COUNT(*) FROM articles_article 
        UNION SELECT 'reactions', COUNT(*) FROM reactions_reaction;"

☐ API ヘルスチェック
  curl -s http://localhost:8000/api/health/

☐ ログ確認（エラーなし確認）
  docker logs toybox-web-1 | grep -i "error\|critical"
```

#### 昼 10:00-12:00
```
タスク: バックアップ取得

☐ DB ダンプ作成
  cd /var/www/toybox/scripts
  bash backup_database.sh

☐ メディアボリューム バックアップ
  bash backup_media_from_prod.sh

☐ バックアップファイル確認
  ls -lh ~/backups/toybox_*.dump
  ls -lh ~/backups/media_*.tar.gz

☐ ファイルサイズ記録
  - DB ダンプ: ??? MB
  - メディア tar.gz: ??? GB
```

#### 午後 13:00-15:00
```
タスク: ローカル PC へ転送

☐ バックアップをローカルに SCP
  scp root@160.251.168.144:~/backups/toybox_*.dump ~/Downloads/
  scp root@160.251.168.144:~/backups/media_*.tar.gz ~/Downloads/

☐ ダウンロード完了確認
  ls -lh ~/Downloads/toybox_*.dump
  ls -lh ~/Downloads/media_*.tar.gz
```

#### 夜 16:00-17:30
```
タスク: 新規本番でのテスト＆リストア

☐ 新規本番へ SSH 接続
  ssh -i "キー" root@192.168.122.140

☐ バックアップをサーバーへ転送
  scp ~/Downloads/toybox_*.dump root@192.168.122.140:/tmp/

☐ Docker Compose 起動
  cd /var/www/toybox/backend
  docker compose up -d
  docker compose ps

☐ DB リストア実行
  docker compose exec -T db pg_restore -U postgres -d toybox /tmp/toybox_*.dump

☐ API テスト
  curl -s http://localhost:8000/api/health/ | python -m json.tool

☐ ユーザー/記事数確認（既存本番と比較）
  docker exec toybox-db-1 psql -U postgres -d toybox \
    -c "SELECT 'users', COUNT(*) FROM auth_user 
        UNION SELECT 'articles', COUNT(*) FROM articles_article 
        UNION SELECT 'reactions', COUNT(*) FROM reactions_reaction;"

  📝 チェック: 既存本番と同じ数か？
```

---

### 【水曜日】

#### 朝 09:00-10:00
```
タスク: Cloudflare DNS 準備

☐ Cloudflare ダッシュボードにアクセス
  https://dash.cloudflare.com/

☐ toybox.ayatori-inc.co.jp DNS レコード確認
  - A レコード: 160.251.168.144 (現在)
  - 予定: 192.168.122.140 (移行後)

☐ TTL を 300秒に短縮
  (DNS 切替を素早く反映させるため)

☐ 設定保存
```

#### 昼 10:00-11:00
```
タスク: 新規本番の最終検証

☐ 新規本番で Caddy テスト
  ssh root@192.168.122.140
  cd /var/www/toybox/backend
  docker compose exec caddy caddy version

☐ HTTPS 接続テスト
  curl -s https://toybox-check.ayatori-inc.co.jp/api/health/
  (または https://192.168.122.140/)

☐ ログ確認
  docker compose logs caddy | tail -20
  docker compose logs web | tail -20

☐ メディア復元テスト（事前）
  cd /var/www/toybox/backend/public
  tar -tzf ~/backups/media_*.tar.gz | head -20
```

---

### 【木曜夜 or 金曜朝】 ⚡ **本番切替実行**

#### Step 1: 最終バックアップ取得（分散可能）
```bash
ssh root@160.251.168.144
cd /var/www/toybox/scripts && bash backup_database.sh
ls -lh ~/backups/toybox_*.dump
```

**所要時間**: 3-5 分

#### Step 2: 新規本番へリストア
```bash
ssh root@192.168.122.140

# バックアップをコピー
scp root@160.251.168.144:~/backups/toybox_*.dump /tmp/

# リストア実行
cd /var/www/toybox/backend
docker compose exec -T db pg_restore -U postgres -d toybox /tmp/toybox_*.dump

# 検証
docker compose exec toybox-db-1 psql -U postgres -d toybox -c "SELECT COUNT(*) FROM auth_user;"
```

**所要時間**: 3-5 分

#### Step 3: DNS 切替（ダウンタイム開始！ ⚠️）
```
【Cloudflare 管理画面で手作業実行】

1. A レコード編集
2. 160.251.168.144 → 192.168.122.140 に変更
3. 保存

【ダウンタイム期間】
- TTL 反映: 5分程度
- ユーザーがアクセスできない: 5-10分
```

**所要時間**: 5-10 分（ダウンタイム）

#### Step 4: 検証＆完了
```bash
# 外部ネットワークから確認
curl -s https://toybox.ayatori-inc.co.jp/api/health/ | python -m json.tool

# ブラウザで確認
# https://toybox.ayatori-inc.co.jp/admin/
# https://toybox.ayatori-inc.co.jp/

# ログ確認
docker logs toybox-caddy-1 2>&1 | tail -50
docker logs toybox-web-1 2>&1 | tail -50

# ユーザー/記事数確認
docker exec toybox-db-1 psql -U postgres -d toybox \
  -c "SELECT COUNT(*) FROM auth_user;"
```

**所要時間**: 5-10 分

---

### 【金曜午後】

#### 15:00-16:00
```
タスク: 既存本番の安全な停止＆保管

☐ 既存本番が完全に停止しても大丈夫か最終確認
  curl -s https://toybox.ayatori-inc.co.jp/api/health/
  (新規本番で応答を確認)

☐ 既存本番を停止
  ssh root@160.251.168.144
  cd /var/www/toybox && docker compose down

☐ 確認
  docker ps
  (toybox-* が全て消えたことを確認)

☐ データをアーカイブ（90日保管）
  tar -czf /backup/toybox-old-prod-20261007.tar.gz /var/www/toybox/
  ls -lh /backup/toybox-old-prod-20261007.tar.gz

☐ 記録
  既存本番サーバーの停止時刻: 2026/10/11 15:30 JST
```

#### 16:00-17:00
```
タスク: ドキュメント最終更新＆報告

☐ 移行レポート作成
  - 本番切替完了日時
  - ダウンタイム実績
  - 検証結果

☐ チーム内に報告

☐ 完了!
```

---

## 🔴 重要な注意点

### 優先度 1: ディスク容量
```
既存本番ディスク使用率: 84.7%

対策:
- バックアップ取得後、即座にローカル転送
- 既存本番からも削除
```

### 優先度 2: ロールバック計画
```
もし何か問題が起きたら:
1. DNS A レコード: 192.168.122.140 → 160.251.168.144 に戻す
2. 既存本番を再起動: docker compose up -d
3. 5分待機
```

### 優先度 3: データ検証
```
各ステップで必ず確認:
- ユーザー数が一致
- 記事数が一致
- API が 200 OK 応答
```

---

## ✅ チェックリスト（印刷推奨）

### 【火曜】
- [ ] 既存本番: ユーザー数記録 = ??
- [ ] 既存本番: 記事数記録 = ??
- [ ] 既存本番: リアクション数記録 = ??
- [ ] バックアップ取得完了
- [ ] ローカル PC に転送完了
- [ ] 新規本番でリストア成功
- [ ] 新規本番でテスト成功

### 【水曜】
- [ ] Cloudflare TTL 300秒に短縮
- [ ] 新規本番 HTTPS テスト成功
- [ ] 新規本番 API テスト成功

### 【木曜夜/金曜朝】
- [ ] 最終バックアップ取得
- [ ] DNS A レコード切替実行
- [ ] 外部から HTTPS 接続確認
- [ ] API 200 OK 確認
- [ ] ユーザー/記事数が一致
- [ ] ログにエラーなし

### 【金曜午後】
- [ ] 既存本番停止完了
- [ ] データをアーカイブ
- [ ] ドキュメント更新
- [ ] チーム内報告

---

## 📞 トラブルシューティング

### Q. バックアップ取得に時間がかかる？
**A**: 5.8GB のメディアボリュームのため、20-30分見積もり

### Q. DNS が切り替わらない？
**A**: TTL が反映するまで 5-10分待つ。キャッシュクリア: `ipconfig /flushdns` (Windows)

### Q. 新規本番でリストア失敗？
**A**: DB ユーザー/パスワード確認、ディスク容量確認

### Q. ロールバックしたい？
**A**: DNS A レコード: 192.168.122.140 → 160.251.168.144 に戻す

---

**ステータス**: 🚀 **本週中完了可能！**  
**開始時期**: 明日（火曜日）朝 09:00  
**ダウンタイム**: 5-10 分のみ（木曜夜/金曜朝）

**Next Steps**:
1. 火曜朝にバックアップ開始
2. 水曜朝に DNS 準備
3. 金曜朝に本番切替実行

