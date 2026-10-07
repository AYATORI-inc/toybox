# docker-compose 構成の詳細確認プラン
**作成日**: 2026/10/07 11:35 JST

## 🔍 サーバーで実行すべき確認コマンド

### コマンド 1: docker-compose.yml の内容確認

```bash
ssh -i "キー" root@160.251.168.144
cd /var/www/toybox

# ファイル全体を確認
cat docker-compose.yml | head -100

# または、version と services を抽出
grep -E "^version:|^services:|^  [a-z].*:" docker-compose.yml | head -20
```

**何を確認するか**:
- Django/Gunicorn の定義はあるか？
- PostgreSQL/Redis の定義はあるか？
- Celery の定義はあるか？
- Caddy の定義はあるか？

### コマンド 2: backend-worker-1 の失敗理由

```bash
# 失敗ログを確認
docker logs backend-worker-1 2>&1 | tail -200

# または、エラーメッセージのみ抽出
docker logs backend-worker-1 2>&1 | grep -i "error\|exception\|traceback"
```

**何を確認するか**:
- Celery が起動時に何で失敗したのか
- DB 接続？Redis 接続？設定エラー？

### コマンド 3: 実際に使用中の docker-compose コマンド

```bash
# bash history から確認
history | grep "docker-compose"

# または、docker ps の詳細から確認
docker inspect toybox-web-1 | grep -E "Image|Created|Command|Labels" | head -20

# または、docker compose の現在の状態確認
cd /var/www/toybox
docker compose ps  # これで「どの docker-compose.yml が使われているか」が分かる
```

**何を確認するか**:
- `docker compose` コマンドでどのファイルが参照されているのか
- toybox-* と backend-* は別の docker-compose.yml で起動したのか？

### コマンド 4: ボリューム確認

```bash
# 全ボリュームを確認
docker volume ls

# 各ボリュームの詳細
docker volume inspect toybox_db_data 2>/dev/null || docker volume ls | grep -E "toybox|backend"

# または、backend_static_volume がどのサービスで使われているか
docker inspect backend-web-1 | grep -A 5 "Mounts"
```

**何を確認するか**:
- toybox_* と backend_* のボリュームが分かれているのか
- 同じ DB を使ってるのか、別々なのか

### コマンド 5: ネットワーク確認

```bash
# 全ネットワークを確認
docker network ls

# 各コンテナがどのネットワークに接続しているか
docker inspect toybox-web-1 | grep -A 10 "Networks"
docker inspect backend-web-1 | grep -A 10 "Networks"
```

**何を確認するか**:
- toybox-* と backend-* が別のネットワークにいるのか
- 通信が分離されているのか

---

## 📋 実行手順

### すべてをまとめたコマンド（コピペで一度に実行）

```bash
ssh -i "C:\Users\ayato\.ssh\toybox-2025-11-06-11-40.pem" root@160.251.168.144

cd /var/www/toybox && {
  echo "=== 1. docker-compose.yml ===" && \
  grep -E "^version:|^services:|^  [a-z]" docker-compose.yml | head -30 && \
  echo -e "\n=== 2. backend-worker-1 ログ ===" && \
  docker logs backend-worker-1 2>&1 | grep -i "error\|exception" | head -20 && \
  echo -e "\n=== 3. docker compose ps ===" && \
  docker compose ps && \
  echo -e "\n=== 4. ボリューム一覧 ===" && \
  docker volume ls | grep -E "toybox|backend" && \
  echo -e "\n=== 5. toybox-web-1 ネットワーク ===" && \
  docker inspect toybox-web-1 | grep -A 5 "Networks" && \
  echo -e "\n=== 6. backend-web-1 ネットワーク ===" && \
  docker inspect backend-web-1 | grep -A 5 "Networks"
}
```

---

## 🎯 予想される結果パターン

### パターン A: docker-compose.yml が不完全

**予想される内容**:
```yaml
services:
  web:
    image: toybox-web  # イメージ指定のみ
    ...

  (db, redis, caddy は定義されていない)
```

**解釈**:
- イメージは事前ビルド済み
- docker-compose.yml は web のみ定義
- db/redis/caddy は docker-compose.prod.yml または別コマンドで起動

### パターン B: backend-* の Celery 失敗

**予想される内容**:
```
Traceback (most recent call last):
  ...
ConnectionRefusedError: [Errno 111] Connection refused
```

**解釈**:
- backend-* の PostgreSQL/Redis が接続できない
- または、環境変数が不正
- テスト時に接続先を誤った可能性

### パターン C: 別々のネットワーク

**予想される内容**:
```
toybox-web-1 Networks: "toybox_default"
backend-web-1 Networks: "backend_default"
```

**解釈**:
- toybox-* と backend-* は完全に分離されている
- ポート競合がない理由はここ
- 意図的なテスト分離？

---

## 💡 想定される新規本番構成（推奨）

### 単一の docker-compose.yml

```yaml
version: '3.9'

services:
  web:
    image: toybox-web:latest
    ports:
      - "8000:8000"
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
    networks:
      - default

  worker:
    image: toybox-web:latest
    command: celery -A toybox worker
    environment:
      - DB_HOST=db
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    networks:
      - default

  beat:
    image: toybox-web:latest
    command: celery -A toybox beat
    environment:
      - DB_HOST=db
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    networks:
      - default

  caddy:
    image: toybox-caddy:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - web
    networks:
      - default

volumes:
  db_data:
  caddy_data:
  caddy_config:
```

**利点**:
- すべてが 1 ファイルで定義
- 依存関係が明確
- 本番/開発で同じファイル使用可能
- テスト環境の混在なし

---

## ✅ 次のアクション

### 本週中

1. **サーバーで確認コマンド実行** (15分)
2. **結果をスクリーンショット保存**
3. 本番切替実行

### 来週以降

1. **結果から「backend-* が何なのか」を判定**
2. **不要なら削除** (ディスク容量節約)
3. **新規本番で clean な docker-compose.yml 構築**
4. **Git でバージョン管理**

---

**ステータス**: 📋 確認待ち  
**優先度**: 本番切替 > リファクタリング  
**推奨**: 本週末までに確認コマンド実行

