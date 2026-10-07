# リポジトリ整理 & リファクタリング分析
**作成日**: 2026/10/07 11:32 JST

## 🚨 発見された問題

### 問題 1: コンテナの重複（本番環境での不安定性）

**既存本番で稼働中**:

```
✅ 本番稼働（toybox-* セット）
   ├─ toybox-web-1          (ポート 8000 公開)
   ├─ toybox-worker-1       (Celery)
   ├─ toybox-beat-1         (Celery Beat)
   ├─ toybox-caddy-1        (ポート 80/443 公開)
   ├─ toybox-db-1           (PostgreSQL)
   └─ toybox-redis-1        (Redis)

⚠️ テスト環境（backend-* セット）
   ├─ backend-web-1         (上部 14時間から稼働）
   ├─ backend-db-1          (稼働中）
   ├─ backend-redis-1       (稼働中）
   ├─ backend-worker-1      ❌ Exited (1) 13h ago → 失敗
   └─ backend-beat-1        ❌ Exited (1) 13h ago → 失敗
```

**リスク**:
- ポートバインディングの競合がない（toybox は 8000/80/443, backend は内部）
- ただし、**DB/Redis が 2 セット存在** → データ一貫性の懸念
- ディスク容量に影響（ボリュームが倍）
- 保守性の低下（どっちを使ってるのか不明）

---

### 問題 2: docker-compose の複数ファイル

**存在するファイル**:

```
/var/www/toybox/
├── docker-compose.yml        (開発用？ - 実態不明)
└── docker-compose.prod.yml   (本番用？ - 499B のみ)
```

**取得した docker-compose.prod.yml の内容**:

```yaml
services:
  caddy:
    build:
      context: .
      dockerfile: Dockerfile.caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - caddy-data:/data
      - caddy-config:/config
      - backend_static_volume:/app/staticfiles:ro
    networks:
      - toybox_default

networks:
  toybox_default:
    external: true

volumes:
  caddy-data:
  caddy-config:
  backend_static_volume:
    external: true
    name: backend_static_volume
```

**問題点**:
- **Caddy のみ定義**している
- Django/Gunicorn, PostgreSQL, Redis, Celery が定義されていない
- ← つまり、実際には使われていない？
- または、手作業で `docker run` してる？

---

### 問題 3: Dockerfile の複数

**存在するファイル**:

```
/var/www/toybox/
├── Dockerfile           (Django アプリケーション)
├── Dockerfile.caddy     (Caddy イメージ)
```

**質問**:
- `docker-compose.yml` は Dockerfile を参照しているのか？
- それとも イメージが既にビルド済み？

---

## 🔍 根本原因の仮説

### 仮説 1: 段階的なアップグレード試験

```
段階1: 本番稼働中 (toybox-* セット)
   ↓
段階2: backend-* で新しいバージョンをテスト
   ↓
段階3: backend-* の Celery が失敗 → 放置？
   ↓
段階4: テスト中断？ 本番は toybox-* で継続
```

**実態**: 失敗したテストが放置されている

### 仮説 2: docker-compose.prod.yml は使われていない

```
実際の起動方法:
  docker compose -f docker-compose.yml up -d
  
または

  各コンテナを手作業で docker run
```

**結果**: docker-compose.prod.yml は無用の長物

### 仮説 3: Git に記録されていない

```
既存本番: Git にコミットなし
   ↓
構成が不明確 → backend-* も含めて全て実際の状態
   ↓
テストに失敗した backend-* が放置
```

---

## 📋 必要な確認事項（サーバーで実行）

### 確認 1: 実際に使われている docker-compose

```bash
ssh root@160.251.168.144
cd /var/www/toybox

# 実際に使われているコマンドを確認
history | grep docker-compose

# または、ps で確認
ps aux | grep docker-compose

# または、docker ps の詳細から確認
docker inspect toybox-web-1 | grep -E "Image|Volumes"
```

### 確認 2: docker-compose.yml の内容確認

```bash
# docker-compose.yml の先頭を確認
head -50 docker-compose.yml

# version と services を確認
grep -E "^version:|^services:" docker-compose.yml
```

### 確認 3: backend-* が何か確認

```bash
# backend-web-1 の詳細
docker inspect backend-web-1 | grep -E "Image|Created|Command" | head -20

# backend-worker-1 の エラーログ
docker logs backend-worker-1 2>&1 | tail -50
```

---

## ✅ リファクタリングの必要性

### 既存本番（160.251.168.144）

| 項目 | 必要性 | 優先度 | 理由 |
|------|--------|--------|------|
| **backend-* 削除** | ⭐⭐⭐⭐⭐ | 🔴 高 | ディスク節約 + 混乱排除 |
| **docker-compose 統一** | ⭐⭐⭐ | 🟡 中 | 保守性向上 |
| **Git でバージョン管理** | ⭐⭐ | 🟡 中 | 構成の可視化 |
| **Caddyfile のバージョン削除** | ⭐ | 🟢 低 | クリーンアップ |

### 新規本番（192.168.122.140）

| 項目 | 必要性 | 優先度 | 理由 |
|------|--------|--------|------|
| **Clean な構成で構築** | ⭐⭐⭐⭐⭐ | 🔴 高 | **テスト環境を含めない** |
| **docker-compose を 1 ファイルに統一** | ⭐⭐⭐⭐ | 🔴 高 | 明確な構成 |
| **Git でバージョン管理** | ⭐⭐⭐ | 🟡 中 | 可視化 |

---

## 🎯 推奨アクション

### フェーズ 1: 本番切替後（既存本番のクリーンアップ）

```bash
# 不要な backend-* を削除
docker compose -f docker-compose.prod.yml down
# または
docker rm backend-web-1 backend-db-1 backend-redis-1
docker rmi backend-web backend-worker backend-beat
```

**ただし**: backend-* が何なのか確認してから実行してください

### フェーズ 2: 新規本番の構成（Clean に構築）

#### 推奨構成:

```yaml
# docker-compose.yml （1 ファイルのみ）

version: '3.9'

services:
  caddy:
    build:
      context: .
      dockerfile: Dockerfile.caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - caddy-data:/data
      - caddy-config:/config
      - static_volume:/app/staticfiles:ro
    depends_on:
      - web
    networks:
      - default

  web:
    build:
      context: .
      dockerfile: Dockerfile
    restart: unless-stopped
    environment:
      - DEBUG=False
      - ALLOWED_HOSTS=toybox.ayatori-inc.co.jp
    depends_on:
      - db
      - redis
    networks:
      - default

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

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    networks:
      - default

  worker:
    build:
      context: .
      dockerfile: Dockerfile
    command: celery -A toybox worker --loglevel=info
    restart: unless-stopped
    depends_on:
      - db
      - redis
    networks:
      - default

  beat:
    build:
      context: .
      dockerfile: Dockerfile
    command: celery -A toybox beat --loglevel=info
    restart: unless-stopped
    depends_on:
      - db
      - redis
    networks:
      - default

volumes:
  db_data:
  caddy-data:
  caddy-config:
  static_volume:

networks:
  default:
```

**メリット**:
- 1 ファイルで全サービス定義
- clear な依存関係
- 本番と開発で同じファイル使用可能
- テスト環境の混在なし

---

## 📊 既存本番 vs 新規本番 の docker-compose 比較

| 項目 | 既存本番 | 新規本番（推奨） |
|------|---------|-----------------|
| **ファイル数** | 複数 | 1 つ |
| **内容の明確さ** | ⚠️ 不明確 | ✅ 明確 |
| **テスト環境** | ⚠️ backend-* 混在 | ✅ なし |
| **構成の可視化** | ⚠️ Git コミットなし | ✅ Git 管理 |
| **保守性** | ⚠️ 低 | ✅ 高 |

---

## ⚠️ 注意事項

### backend-* を削除する前に確認すべきこと

```bash
# 1. 実際に使われているか？
docker ps | grep backend

# 2. 失敗している理由は？
docker logs backend-worker-1 | tail -100

# 3. 削除して本番に影響なし？
# toybox-* が正常に稼働していることを確認
curl http://localhost:8000/api/health/
```

### 既存本番のクリーンアップは緊急ではない

```
優先度順:
1. 本番切替完了 (金曜)
2. 新規本番で正常稼働確認 (1週間)
3. backend-* 削除 (2週間後)
```

---

## ✅ 本週中の行動（推奨）

### 今週中にすること

- ❌ 既存本番を修正/クリーンアップ
- ✅ 本番切替実行
- ✅ 新規本番は Clean な構成で構築

### 来週以降にすること

- [ ] backend-* が何か詳しく確認
- [ ] 不要なら削除
- [ ] docker-compose を統一
- [ ] Git でバージョン管理

---

## 📋 リポジトリ整理チェックリスト

### 本週中 (現在)

- [x] 既存本番の把握 (docker-compose, Dockerfile)
- [x] 新規本番は clean に構築（予定）
- [ ] docker-compose.yml を確認（サーバーで実行待ち）
- [ ] backend-* の目的を確認（サーバーで実行待ち）

### 来週以降

- [ ] backend-* が不要なら削除
- [ ] docker-compose を統一（1 ファイル化）
- [ ] Dockerfile を整理
- [ ] Git でバージョン管理
- [ ] Caddyfile のバージョンを削除

---

## 📞 次のステップ

**サーバーで以下を実行して、詳細を確認してください**:

```bash
ssh root@160.251.168.144
cd /var/www/toybox

# 1. docker-compose.yml の内容確認
echo "=== docker-compose.yml ===" && head -100 docker-compose.yml

# 2. backend-worker-1 の失敗理由
echo -e "\n=== backend-worker-1 log ===" && docker logs backend-worker-1 2>&1 | tail -100

# 3. 実際に使っているコマンドを history から確認
echo -e "\n=== history ===" && history | grep docker | tail -20
```

**その結果をベースに、リファクタリング計画を立てましょう。**

---

**ステータス**: 📋 リファクタリング検討中  
**優先度**: 本番切替 > リファクタリング  
**推奨**: 切替完了後の来週以降に実行

