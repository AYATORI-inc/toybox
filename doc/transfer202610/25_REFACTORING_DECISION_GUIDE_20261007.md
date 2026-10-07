# リファクタリング意思決定ガイド
**作成日**: 2026/10/07 11:37 JST

---

## 🎯 ユーザーの懸念点まとめ

### ① 「過去のものが動いてる」という不安

```
既存本番で:
  ✅ toybox-* (本番稼働中)
  ⚠️  backend-* (14時間前から、worker/beat は失敗)
  
疑問: backend-* は何？テスト？放置？
```

### ② docker-compose が複数ある理由

```
存在するファイル:
  - docker-compose.yml      (実態不明)
  - docker-compose.prod.yml (Caddy のみ定義)
  
疑問: どちらを使ってるのか？
      なぜ Caddy だけ prod.yml？
```

---

## ✅ 現状分析

### 既存本番の状態

| 項目 | 状態 |
|------|------|
| **本番稼働** | ✅ 安定（3ヶ月） |
| **テスト環境** | ⚠️ 失敗したまま放置 |
| **docker-compose** | ⚠️ 複数ファイル＆用途不明 |
| **Git 管理** | ❌ コミットなし |
| **リスク** | 🔴 複雑性が高い |

### 新規本番の選択肢

| 方法 | 利点 | 欠点 |
|------|------|------|
| **既存本番をそのまま複製** | 確実 | 問題も複製 |
| **Clean に構築** | シンプル | テストが必要 |

---

## 📊 リファクタリングの必要性診断

### 既存本番：本番切替前の改修は「不要」

**理由**:
1. **ディスク容量は重要** (84.7% 使用中)
   - backend-* 削除で 5-10% 回収可能
   - ただし、本番切替後に実施でよい

2. **本番切替が最優先**
   - 今週中に完了する必要
   - 改修に時間を使ってはいけない

3. **backend-* は削除しても本番に影響なし**
   - toybox-* が稼働してれば OK
   - 切替完了後に削除可

### 新規本番：Clean 構成で構築「推奨」

**理由**:
1. **テスト環境を含めない**
   - 本番のみで運用可能
   - シンプルで保守性高い

2. **git でバージョン管理**
   - 構成が可視化
   - 将来の変更が記録される

3. **新しいサーバーだから可能**
   - リスクなし
   - これから正しく構築できる

---

## 🎯 推奨アクション

### ✅ 本週中にやること

1. **本番切替を完了** (火曜～金曜)
2. **新規本番で Clean 構成で構築**
   - 単一の docker-compose.yml
   - テスト環境なし
   - Git 管理

### ✅ 来週以降にやること

1. **backend-* が何かを確認** (コマンド実行)
2. **不要なら削除** (既存本番)
3. **ディスク容量を回収** (20-30GB)

---

## 📋 新規本番の推奨構成

### docker-compose.yml（1 ファイル）

```yaml
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
      - caddy_data:/data
      - caddy_config:/config
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
      - DB_HOST=db
      - REDIS_URL=redis://redis:6379/0
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
  caddy_data:
  caddy_config:
  static_volume:

networks:
  default:
```

### 特徴

✅ **単一ファイル**: 複数のファイルなし  
✅ **明確な依存関係**: depends_on で定義  
✅ **テスト環境なし**: production only  
✅ **環境変数で制御**: デプロイ時に変更可能  
✅ **Git で管理**: バージョン追跡可能  

---

## ⚙️ 移行時の実装ステップ

### Step 1: 新規本番で docker-compose.yml を作成（火曜～水曜）

```bash
ssh root@192.168.122.140
cd /var/www/toybox/backend

# 既存の docker-compose.yml をバックアップ
cp docker-compose.yml docker-compose.yml.backup

# 新しいものに置き換え（推奨構成を使用）
cat > docker-compose.yml << 'EOF'
version: '3.9'
services:
  ...
EOF

# テスト起動
docker compose up -d
docker compose ps
```

### Step 2: 本番切替（金曜朝）

```bash
# 新規本番で稼働確認
curl https://toybox.ayatori-inc.co.jp/api/health/

# DNS 切替
# (Cloudflare で手作業)

# 検証
curl https://toybox.ayatori-inc.co.jp/admin/
```

### Step 3: Git でバージョン管理（切替完了後）

```bash
cd /var/www/toybox

# docker-compose.yml をステージング
git add docker-compose.yml

# コミット
git commit -m "chore: Refactor docker-compose to single file

- Remove backend-* test environment
- Consolidate all services in single file
- Add proper depends_on relationships
- Use environment variables for configuration"

# 本番で適用
git push origin main
```

---

## 🔄 タイムライン

| 時期 | タスク | 優先度 |
|------|--------|--------|
| **本週中** | 本番切替実行 | 🔴 最高 |
| **本週中** | 新規本番で clean 構成構築 | 🔴 高 |
| **来週** | backend-* 確認コマンド実行 | 🟡 中 |
| **来週～** | backend-* 削除（不要なら） | 🟡 中 |
| **来週～** | Git バージョン管理開始 | 🟡 中 |

---

## ✅ チェックリスト

### 本週中

- [x] 既存本番の構成把握
- [x] 新規本番の準備
- [x] リファクタリング分析完了
- [ ] 本番切替実行
- [ ] 新規本番で clean 構成確認

### 来週以降

- [ ] backend-* 確認コマンド実行
- [ ] backend-* が不要なら削除
- [ ] 既存本番のディスク容量回収
- [ ] 新規本番で docker-compose.yml を Git 管理
- [ ] Caddyfile バージョンファイル削除

---

## 📞 判断基準

### Q: 本週中にリファクタリングしないで大丈夫？

**A**: はい。理由：
- ✅ 本番切替が最優先
- ✅ backend-* 削除は本番に影響なし
- ✅ 新規本番は clean に構築可能
- ✅ 来週以降の作業でよい

### Q: 新規本番でも docker-compose 複数にするべき？

**A**: いいえ。1 つのファイルで十分。理由：
- ✅ 開発/本番で同じファイル使用可能
- ✅ テスト環境は docker-compose.override.yml で別管理
- ✅ シンプルで保守性高い

### Q: backend-* は削除しちゃってもいい？

**A**: 本番切替後なら OK。理由：
- ✅ toybox-* が本番稼働中
- ✅ backend-* は使われていない
- ✅ 確認してから削除推奨

---

**ステータス**: 📋 分析完了＋推奨案提示  
**次のステップ**: 本番切替 → 来週リファクタリング  
**リスク**: 低（本週中は改修なし）

