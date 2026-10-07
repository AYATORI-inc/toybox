# Toybox 移行プロジェクト - 状況統括（2026/10/07 11:20 JST）

## 🎯 目標

既存本番サーバー (160.251.168.144) から新規本番サーバー (192.168.122.140) へ移行  
**期限**: 今週中 (2026/10/11 までに完了)

---

## 📊 現在の進捗

| フェーズ | 状態 | 完了率 |
|---------|------|--------|
| **Phase 1** | ローカル環境セットアップ | ✅ 100% |
| **Phase 2** | ローカルテスト・検証 | ✅ 100% |
| **Phase 3** | データリストア | ✅ 100% |
| **Phase 4** | 新規本番セットアップ | ✅ 95% |
| **Phase 5** | 既存本番の構成把握 | 🔄 70% |
| **Phase 6** | 本番切替 | ⏳ 0% |

---

## 🔍 既存本番サーバーの状態（2026/10/07 確認）

### サーバー基本情報
```
ホスト: vm-c2dd3545-73
IP: 160.251.168.144
OS: Ubuntu 24.04.3 LTS
ディスク: 84.7% 使用中 (98.24GB) ⚠️ 逼迫
メモリ: 84% 使用、Swap 54% ⚠️ 高負荷
システム再起動: 必要 ⚠️
```

### 稼働中のサービス

✅ **本番稼働中（3ヶ月以上）**
```
toybox-caddy-1     → ポート 80/443 リッスン（HTTPS対応）
toybox-web-1       → ポート 8000 (Gunicorn + Django)
toybox-worker-1    → Celery ワーカー
toybox-beat-1      → Celery Beat スケジューラー
toybox-db-1        → PostgreSQL 15 (データ 3ヶ月蓄積)
toybox-redis-1     → Redis 7
```

⚠️ **テスト環境（14時間前から稼働→失敗）**
```
backend-web-1      → 稼働中（用途不明）
backend-db-1       → 稼働中（用途不明）
backend-redis-1    → 稼働中（用途不明）
backend-worker-1   → ❌ Exited (失敗)
backend-beat-1     → ❌ Exited (失敗)
```

### 重要な発見

🔴 **問題点**:
1. Git に **コミットなし** → 本番サーバーで何も記録されていない
2. ディスク 84.7% 使用 → バックアップ時に容量不足の可能性
3. 2つの Docker セット が共存 → 古い backend-* は削除予定か？
4. backend-worker/beat が失敗 → 原因不明（本番には影響なし）

✅ **安定な部分**:
- 本番サービス（toybox-*）が 3ヶ月間連続稼働
- Caddy で HTTPS 対応（ドメイン: toybox.ayatori-inc.co.jp 推定）
- PostgreSQL/Redis 健全稼働

---

## 📁 ドキュメント完成状況

### 作成済みドキュメント（計 15 個）

| ドキュメント | 目的 | 状態 |
|-------------|------|------|
| **EXISTING_PRODUCTION_SURVEY_20261007.md** | 既存本番の構成把握 | ✅ 基本完成（詳細追加待ち） |
| **MIGRATION_MASTERPLAN_THISWEEK_20261007.md** | 本週中の移行計画 | ✅ 完成 |
| **PRE_MIGRATION_CHECKLIST_THISWEEK_20261007.md** | 移行前チェックリスト | ✅ 完成 |
| LOCAL_SETUP_SUMMARY_20261006.md | ローカル環境セットアップ | ✅ |
| DATA_RESTORE_REPORT_20261006.md | データリストア手順 | ✅ |
| PRODUCTION_DOCKER_SETUP_20261006.md | 新規本番 Docker セットアップ | ✅ |
| PRODUCTION_DEPLOYMENT_PLAN_20261006.md | デプロイメント計画 | ✅ |
| その他 | 機能別ドキュメント | ✅ |

---

## 🚀 今すぐ実行すべきステップ

### ⏱️ 直近 1-2 時間内

**優先度 🔴 超高**：以下をサーバーで実行してログ取得

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
   UNION SELECT 'reactions', COUNT(*) FROM reactions_reaction;" && \
  echo -e "\n=== 7. BACKEND-WEB LOG ===" && docker logs backend-web-1 2>&1 | tail -40
}
```

**出力内容をコピーして貼り付けてください。**

---

### 📋 火曜日 (明日) に実施

#### 朝 09:00-10:00
```
☐ Caddyfile と docker-compose.prod.yml をローカルに保存
☐ 既存本番の全ログ確認（エラー/警告なし確認）
☐ ユーザー/記事数を記録
```

#### 10:00-11:00
```
☐ 最新バックアップ取得
  ssh root@160.251.168.144
  cd /var/www/toybox/scripts && bash backup_database.sh
  
☐ メディアボリュームバックアップ
  bash backup_media_from_prod.sh
```

#### 11:00-12:00
```
☐ バックアップをローカル PC にダウンロード
  scp root@160.251.168.144:~/backups/toybox_*.dump ~/Downloads/
  scp root@160.251.168.144:~/backups/media_*.tar.gz ~/Downloads/
```

#### 13:00-14:00
```
☐ 新規本番へのリストア & テスト
  ssh root@192.168.122.140
  # バックアップコピー
  scp /tmp/toybox_*.dump root@192.168.122.140:/tmp/
  
  # リストア実行
  docker compose exec -T db pg_restore -U postgres -d toybox /tmp/toybox_*.dump
  
  # テスト
  curl -s http://localhost:8000/api/health/
```

---

## ✅ 移行成功の必須条件

### 条件 1: 既存本番の設定を完全に把握
- [ ] Caddyfile の SSL 設定確認
- [ ] docker-compose.prod.yml の確認
- [ ] ドメイン設定: toybox.ayatori-inc.co.jp
- [ ] ユーザー/記事数を記録

### 条件 2: 新規本番が本番並みにテスト済み
- [ ] 既存本番と同じデータでテスト
- [ ] API が 200 OK 応答
- [ ] Caddy HTTPS が動作
- [ ] ユーザー/記事数が一致

### 条件 3: バックアップ戦略が確立
- [ ] 最新バックアップをローカル保管
- [ ] メディアボリューム復元テスト実施
- [ ] ロールバック計画が明確

### 条件 4: DNS 切替のタイミング確定
- [ ] Cloudflare へのアクセス権確認
- [ ] TTL を短縮済み
- [ ] 夜間/早朝実施で決定

---

## 🎯 本週中の完了目標

```
【火曜日（明日）】
✅ バックアップ取得 & 新規本番テスト

【水曜日】
✅ DNS TTL 短縮
✅ 最終検証

【木曜日夜 or 金曜日朝】
✅ 本番切替実行（ダウンタイム 5-10 分）
✅ 検証 & 完了

【完了時】
✅ 既存本番を安全に停止
✅ ドキュメント最終更新
```

---

## 📞 最後に確認すること

| 項目 | 質問 | 回答 |
|------|------|------|
| **Cloudflare** | DNS レコード編集権はあるか？ | [ ] はい / [ ] いいえ |
| **バックアップ** | スクリプトは実行可能か？ | [ ] はい / [ ] いいえ |
| **新規本番** | Caddy 構築は完了か？ | [ ] はい / [ ] いいえ |
| **テスト環境** | backend-* の削除は OK か？ | [ ] はい / [ ] いいえ |
| **ダウンタイム** | 5-10 分の停止は許容か？ | [ ] はい / [ ] いいえ |

---

## 📌 重要なリンク・ドキュメント

- **MIGRATION_MASTERPLAN_THISWEEK_20261007.md** ← 本週中の完全な実行ガイド
- **PRE_MIGRATION_CHECKLIST_THISWEEK_20261007.md** ← チェックリスト
- **EXISTING_PRODUCTION_SURVEY_20261007.md** ← 既存本番の構成（更新予定）
- **PRODUCTION_DOCKER_SETUP_20261006.md** ← 新規本番セットアップ完了
- **DATA_RESTORE_REPORT_20261006.md** ← データリストア手順

---

**次のアクション**: 

1️⃣ サーバーから設定ファイル取得（上記コマンド実行）  
2️⃣ 火曜日朝にバックアップ開始  
3️⃣ 木曜夜/金曜朝に本番切替  

---

**ステータス**: 🚀 移行準備 70% 完了  
**タイムライン**: 本週中完了可能  
**リスク**: ディスク容量逼迫（既存本番）

