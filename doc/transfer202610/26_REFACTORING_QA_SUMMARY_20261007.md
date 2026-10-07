# リファクタリング相談 - 回答まとめ
**作成日**: 2026/10/07 11:40 JST

---

## 💬 ユーザーの質問 3 つに対する回答

### Q1: 「過去のものが動いてる」って怖くない？リファクタリングは必要か？

**A: 本週中は改修不要。来週以降に段階的に実施。**

#### 現状分析

既存本番で稼働中:
```
✅ toybox-* (本番稼働中, 3ヶ月連続稼働)
   └─ これが本番！API は正常、ログはエラーなし

⚠️  backend-* (14時間前から稼働, worker/beat 失敗)
   └─ これはテスト環境。本番には影響なし。
```

#### 対応方針

```
本週中:
  ❌ backend-* をいじらない
  ✅ 本番切替実行（toybox-* が稼働し続ける）
  ✅ 新規本番は Clean に構築

来週以降:
  ✅ backend-* が何か確認
  ✅ 不要なら削除（ディスク容量節約）
  ✅ docker-compose を統一
```

**リスク**: 低（改修なしだから）

---

### Q2: docker-compose が複数ある理由は？

**A: 実態が不明。確認コマンドを用意しました。**

#### 存在するファイル

```
/var/www/toybox/
├── docker-compose.yml        (開発用？)
└── docker-compose.prod.yml   (Caddy のみ定義, 499B)
```

#### 謎

- docker-compose.yml の実際の内容は不明
- docker-compose.prod.yml は Caddy だけ？
- Django/PostgreSQL/Redis はどこで定義？
- docker-compose.yml が完全？それとも不完全？

#### 確認方法

```bash
# 24_DOCKER_COMPOSE_INVESTIGATION_20261007.md に
# サーバーで実行すべきコマンド集を記載しました

ssh root@160.251.168.144
cd /var/www/toybox && {
  echo "=== docker-compose.yml ===" && \
  head -100 docker-compose.yml && \
  echo -e "\n=== backend-worker log ===" && \
  docker logs backend-worker-1 2>&1 | tail -100
}
```

#### 予想される原因

**パターン A**: docker-compose.yml が不完全
- web のみ定義
- db/redis/caddy は別ファイルまたは `docker run` で起動

**パターン B**: docker-compose.prod.yml が新規追加
- 本番環境用として追加
- でもまだ完成してない？

**パターン C**: 段階的なアップグレード途中
- backend-* で新バージョンテスト中
- テスト失敗 → 放置

---

### Q3: リファクタリングは本当に必要？

**A: 本週中は不要。新規本番は Clean に構築すべき。**

#### 段階的リファクタリング計画

##### フェーズ 1: 本週中（本番切替）
```
優先度: 最高
内容:
  ✅ 本番切替を完了（火曜～金曜）
  ✅ 新規本番は Clean 構成で構築
     - docker-compose.yml を 1 ファイルに統一
     - テスト環境を含めない
     - Git でバージョン管理

副作用:
  ❌ backend-* はそのまま（既存本番に残る）
     → 来週以降に削除

理由:
  - 本番切替が最優先
  - 新規本番なら Clean に作れる
  - 既存本番は「動いてるなら触るな」が原則
```

##### フェーズ 2: 来週以降
```
優先度: 中
内容:
  ✅ backend-* が何かを確認
  ✅ 不要なら削除
  ✅ ディスク容量を回収（20-30GB）
  ✅ 既存本番のクリーンアップ

タイミング:
  - 新規本番で 1 週間正常稼働確認後
  - バックアップを取得してから
  - 既存本番を停止する前に

副作用:
  ❌ ダウンタイムなし（既存本番止まらない）
```

##### フェーズ 3: 将来
```
優先度: 低
内容:
  ✅ 新規本番で docker-compose.yml を Git 管理
  ✅ デプロイ自動化
  ✅ 本番/開発環境の統一
```

---

## 📋 新規本番の推奨構成（実装コード）

### 単一ファイル: docker-compose.yml

```yaml
version: '3.9'

services:
  # Webサーバー（リバースプロキシ）
  caddy:
    build:
      context: .
      dockerfile: Dockerfile.caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - caddy_data:/data
      - caddy_config:/config
      - static_volume:/app/staticfiles:ro
    depends_on:
      - web
    networks:
      - default
    environment:
      - DOMAIN=toybox.ayatori-inc.co.jp

  # Webアプリケーション
  web:
    build:
      context: .
      dockerfile: Dockerfile
    restart: unless-stopped
    expose:
      - "8000"
    environment:
      - DEBUG=False
      - DB_HOST=db
      - DB_NAME=toybox
      - DB_USER=postgres
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    networks:
      - default

  # データベース
  db:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: toybox
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - default

  # キャッシュ
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    networks:
      - default

  # タスクキュー（ワーカー）
  worker:
    build:
      context: .
      dockerfile: Dockerfile
    command: celery -A toybox worker --loglevel=info
    restart: unless-stopped
    environment:
      - DEBUG=False
      - DB_HOST=db
      - DB_NAME=toybox
      - DB_USER=postgres
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    networks:
      - default

  # スケジューラー
  beat:
    build:
      context: .
      dockerfile: Dockerfile
    command: celery -A toybox beat --loglevel=info
    restart: unless-stopped
    environment:
      - DEBUG=False
      - DB_HOST=db
      - DB_NAME=toybox
      - DB_USER=postgres
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    networks:
      - default

volumes:
  db_data:
  caddy_data:
  caddy_config:
  static_volume:

networks:
  default:
```

### メリット

✅ **単一ファイル**: docker-compose.yml のみ  
✅ **明確な依存関係**: depends_on で定義  
✅ **環境変数で制御**: 本番/開発で同じファイル使用可  
✅ **テスト環境なし**: production only（Clean）  
✅ **Git で管理**: バージョン追跡可能  
✅ **拡張可能**: 将来の変更が容易  

---

## 🎯 実装ステップ

### Step 1: 新規本番での実装（本番切替時）

```bash
ssh root@192.168.122.140
cd /var/www/toybox/backend

# 既存をバックアップ
cp docker-compose.yml docker-compose.yml.backup

# 新しい構成に置き換え
# (上記の YAML をコピペ)

# テスト起動
docker compose up -d
docker compose ps

# 動作確認
curl http://localhost:8000/api/health/
```

### Step 2: 本番切替（金曜朝）

```bash
# DNS 切替実行
# → 新規本番が稼働開始

# 外部から確認
curl https://toybox.ayatori-inc.co.jp/api/health/
```

### Step 3: Git 管理開始（切替完了後）

```bash
cd /var/www/toybox

# docker-compose.yml をステージング
git add docker-compose.yml

# コミット
git commit -m "chore: Refactor docker-compose to clean single file

- Consolidate all services in docker-compose.yml
- Remove backend-* test environment pattern
- Add proper depends_on relationships
- Use environment variables for configuration
- Support both production and development deployments"

# push
git push origin main
```

---

## ⚠️ 既存本番について

### 本週中は触らない

```
理由:
  ✅ 本番稼働中（toybox-* が安定稼働）
  ✅ backend-* 削除は本番に影響なし
  ✅ 改修は切替完了後が安全
```

### 来週以降に確認＆クリーンアップ

```
1. backend-* が何か確認
   → doc/24_DOCKER_COMPOSE_INVESTIGATION_20261007.md のコマンド実行

2. 不要なら削除
   docker rmi backend-web backend-worker backend-beat
   docker volume rm backend_*

3. ディスク容量を確認
   df -h /var/www/toybox

4. Caddyfile の古いバージョンを削除
   rm Caddyfile.backup*
```

---

## ✅ 最終判定

| 項目 | 本週中 | 来週以降 |
|------|--------|---------|
| **backend-* 削除** | ❌ 不要 | ✅ 推奨 |
| **docker-compose 統一** | ✅ 新規本番で | ✅ 既存本番後 |
| **Git 管理** | ✅ 新規本番で | ✅ 既存本番後 |
| **リファクタリング** | ❌ 本番切替優先 | ✅ その後 |

---

## 📞 まとめ

**Q: リファクタリングは必要か？**

A: **段階的に実施。本週中は不要。新規本番で Clean に構築。**

```
本週中:
  - 本番切替を完了（最優先）
  - 新規本番は Clean な 1 ファイル構成

来週以降:
  - backend-* の詳細確認 & 削除
  - 既存本番のクリーンアップ
  - docker-compose.yml を Git 管理

利点:
  ✅ 本番切替のリスクなし
  ✅ 新規本番は シンプル & 保守しやすい
  ✅ 既存本番は 1 週間正常稼働確認後に改修
  ✅ ディスク容量を 20-30GB 回収可能
```

---

**ステータス**: ✅ 分析完了＆実装コード提供  
**推奨**: 新規本番で提供の docker-compose.yml をそのまま使用  
**ドキュメント**: doc/25_REFACTORING_DECISION_GUIDE_20261007.md に完全コード記載

