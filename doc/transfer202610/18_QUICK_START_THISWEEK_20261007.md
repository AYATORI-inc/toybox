# Toybox 本番移行プロジェクト - 実行サマリー
**作成日**: 2026/10/07 11:20 JST  
**期限**: 今週中 (2026/10/11 まで)

---

## 🎯 プロジェクト概要

| 項目 | 詳細 |
|------|------|
| **目的** | 既存本番サーバー (160.251.168.144) → 新規本番サーバー (192.168.122.140) へ移行 |
| **期限** | 本週中（火曜〜金曜） |
| **ダウンタイム** | 5-10 分（DNS 切替時） |
| **準備状況** | 70% 完了 |
| **リスク** | ディスク容量逼迫 (84.7%), メモリ高負荷 (84%) |

---

## 📊 現状把握（2026/10/07 確認）

### 既存本番サーバー (160.251.168.144)

```
✅ 稼働中（3ヶ月以上）
├─ Caddy (80/443) ← HTTPS リバースプロキシ
├─ Django + Gunicorn (8000)
├─ PostgreSQL 15
├─ Redis 7
├─ Celery worker
└─ Celery beat

⚠️ 問題: ディスク 84.7%, メモリ 84%
⚠️ 問題: Git にコミットなし
⚠️ 問題: テスト環境 (backend-*) が失敗
```

### 新規本番サーバー (192.168.122.140)

```
🔄 準備中
├─ Docker ✅
├─ Python 3.11 ✅
├─ PostgreSQL ✅
├─ Redis ✅
├─ Django ✅
├─ Caddy [ 構築予定 ]
└─ メディア復元 [ 予定 ]

✅ ディスク: 200GB (余裕)
```

---

## 📋 本週中の実行計画

```
【火曜朝】
  1. 既存本番の設定ファイル確認（Caddyfile, docker-compose.prod.yml）
  2. 最新バックアップ取得（DB + メディア）
  
【火曜昼】
  3. 新規本番へリストア & テスト実施
  
【水曜朝】
  4. DNS TTL 短縮（Cloudflare）
  
【金曜朝】
  ⚡ 本番切替実行（DNS A レコード変更）
     ダウンタイム: 5-10 分
  5. 検証 & 完了
```

**合計所要時間**: 3-4 時間（分散可）

---

## 🔴 直ちに必要な情報取得

**以下をサーバーで実行して、出力を保存してください：**

```bash
cd /var/www/toybox && {
  echo "=== CADDYFILE ===" && cat Caddyfile && \
  echo -e "\n=== DOCKER-COMPOSE.PROD ===" && cat docker-compose.prod.yml && \
  echo -e "\n=== DISK ===" && du -sh /var/www/toybox/* | sort -h && \
  echo -e "\n=== GIT REMOTE ===" && git remote -v && \
  echo -e "\n=== UPLOADS SIZE ===" && du -sh /var/www/toybox/backend/public/uploads && \
  echo -e "\n=== DATA COUNT ===" && \
  docker exec toybox-db-1 psql -U postgres -d toybox -c \
  "SELECT 'users', COUNT(*) FROM auth_user 
   UNION SELECT 'articles', COUNT(*) FROM articles_article 
   UNION SELECT 'reactions', COUNT(*) FROM reactions_reaction;"
}
```

---

## 📁 完成したドキュメント（本週中の移行用）

### 必読 (5+15 分)
1. **STATUS_SUMMARY_20261007.md** ← 現在地（5分）
2. **MIGRATION_MASTERPLAN_THISWEEK_20261007.md** ← 完全ガイド（15分）
3. **PRE_MIGRATION_CHECKLIST_THISWEEK_20261007.md** ← チェックリスト（参照用）

### 参考資料
4. **EXISTING_PRODUCTION_SURVEY_20261007.md** ← 既存本番の構成
5. **PRODUCTION_DOCKER_SETUP_20261006.md** ← 新規本番セットアップ
6. **DATA_RESTORE_REPORT_20261006.md** ← リストア手順
7. **その他** ← 機能別ドキュメント

---

## ✅ 移行成功の絶対条件

### ✓ 条件 1: 既存本番を完全に把握
- [ ] Caddyfile の内容確認
- [ ] docker-compose.prod.yml の確認
- [ ] ドメイン・SSL 設定確認
- [ ] ユーザー/記事数を記録

### ✓ 条件 2: 新規本番が本番並みにテスト済み
- [ ] 既存本番と同じデータでテスト
- [ ] API が 200 OK
- [ ] HTTPS が動作
- [ ] ユーザー/記事数が一致

### ✓ 条件 3: バックアップが確保
- [ ] DB ダンプをローカルに保存
- [ ] メディアボリューム (5.8GB) 復元テスト完了
- [ ] ロールバック計画が明確

### ✓ 条件 4: DNS 切替の準備完了
- [ ] Cloudflare へのアクセス権確認
- [ ] TTL を短縮済み
- [ ] 実施日時（金曜朝）で決定

---

## 🚨 重要な注意

### リスク 1: ディスク容量不足
```
既存本番: 84.7% 使用中
対策: バックアップ取得後、即座にローカル転送
```

### リスク 2: DNS 切替失敗
```
回避策: 事前に TTL を 300秒に短縮
       ロールバック計画を確認
```

### リスク 3: メディア復元失敗
```
対策: tar -xzf の展開速度テスト実施
     権限設定確認
```

---

## 📞 最後の確認

| 項目 | 確認 |
|------|------|
| **Cloudflare へのアクセス権** | ✅ / ❌ |
| **バックアップスクリプト実行可能** | ✅ / ❌ |
| **新規本番 Caddy 構築予定** | ✅ / ❌ |
| **5-10 分のダウンタイム許容** | ✅ / ❌ |
| **既存本番データ削除 OK** | ✅ / ❌ |

---

## 🎬 今すぐやること

### 優先度 🔴 今日中
1. ✅ サーバーから設定ファイル取得（上記コマンド実行）
2. ✅ MIGRATION_MASTERPLAN_THISWEEK_20261007.md を読む（15分）
3. ✅ PRE_MIGRATION_CHECKLIST_THISWEEK_20261007.md でチェック項目確認

### 優先度 🟠 明日（火曜朝）
4. バックアップ取得開始
5. 新規本番でテスト実施

### 優先度 🟡 水曜
6. DNS TTL 短縮

### 優先度 🔵 金曜朝
7. 本番切替実行

---

**ステータス**: 🚀 本週中完了可能な態勢整備完了  
**次のステップ**: サーバーから設定ファイル取得  
**サポート**: ドキュメント参照、または質問ください

