# DNS 切替え計画
**作成日**: 2026/10/07  
**対象**: 本番ドメイン `toybox.ayatori-inc.co.jp` の DNS 切替え  
**方針**: CloudFlare Tunnel を活用した無停止切替え

---

## 📊 現在の構成（切替え前）

```
CloudFlare Nameserver (toyatori-inc.co.jp)
├─ toybox.ayatori-inc.co.jp
│  └─ A Record: 160.251.168.144 (既存本番サーバー @ ConoHa)
│
└─ toyboxssh.ayatori-inc.co.jp  
   └─ CloudFlare Tunnel → 新規サーバー ✅ (既に稼働)
```

### 既存本番サーバー（160.251.168.144）
- IP: 160.251.168.144 (ConoHa VPS)
- ステータス: 🛑 **停止済み**（2026/10/07）

### 新規本番サーバー（toyboxssh.ayatori-inc.co.jp）
- ホスト: SSH トンネルで接続
- OS: Ubuntu 24.04.4 LTS
- サービス: Django + PostgreSQL + Redis (Caddy なし)
- ステータス: ✅ 稼働中（@20261007 リストア済み）
- CloudFlare Tunnel: ✅ SSH + toybox-check + **toybox 本番 hostname 追加済み**
- バックアップ: ✅ @20261007 リストア完了

---

## 🎯 目標構成（切替え後）

```
CloudFlare Nameserver (toyatori-inc.co.jp)
├─ toybox.ayatori-inc.co.jp
│  └─ CloudFlare Tunnel → 新規サーバー ✅ (新規構成)
│
└─ toyboxssh.ayatori-inc.co.jp
   └─ CloudFlare Tunnel → 新規サーバー ✅ (既存)

【結果】
- Web (https://toybox.ayatori-inc.co.jp) → 新規サーバー
- SSH (ssh toyboxssh.ayatori-inc.co.jp) → 新規サーバー
- 既存本番サーバー → 停止・廃棄
```

---

## ⚙️ DNS 切替え手順（段階的実施）

### Phase 1: 事前準備（実施済みまたは実施予定）

#### ✅ 完了項目
- [x] 新規サーバーセットアップ完了
- [x] @20260930 バックアップリストア完了
- [x] テストドメイン（toybox-check.ayatori-inc.co.jp）で動作確認済み
- [x] CloudFlare Tunnel（SSH）既に設定済み
- [x] アーキテクチャドキュメント作成

#### ✅ Phase 1 追加完了（2026/10/07 実施）
- [x] @20261007 最新バックアップ リストア完了
- [x] お知らせ（announcement）作成完了
- [x] 既存本番サーバー停止済み

---

### Phase 2: CloudFlare Tunnel の再構築 ✅ 完了（2026/10/07 17:45 JST）

**対象**: `toybox.ayatori-inc.co.jp` → CloudFlare Tunnel 切替え

#### 2-1〜2-3 実施済み
- [x] `config.yml` に `toybox.ayatori-inc.co.jp → http://localhost:8000` 追加
- [x] バックアップ: `/home/ayatori/.cloudflared/config.yml.bak.20261007`
- [x] cloudflared 再起動（Registered tunnel connection / quic / kix）
- [x] `ALLOWED_HOSTS` に `toybox.ayatori-inc.co.jp` 済み
- [x] `toybox-check` 疎通確認 OK

**現在の config.yml：**
```yaml
tunnel: 3d431ab0-9cb3-4392-ae12-b108aaa0d91a
credentials-file: /home/ayatori/.cloudflared/3d431ab0-9cb3-4392-ae12-b108aaa0d91a.json

ingress:
  - hostname: toyboxssh.ayatori-inc.co.jp
    service: ssh://localhost:22
  - hostname: toybox-check.ayatori-inc.co.jp
    service: http://localhost:8000
  - hostname: toybox.ayatori-inc.co.jp
    service: http://localhost:8000
  - service: http_status:404
```

---

### Phase 3: CloudFlare DNS 設定の更新 ✅ 完了（2026/10/07 17:48 JST）

**対象**: CloudFlare ダッシュボード（https://dash.cloudflare.com）

> CLI `cloudflared tunnel route dns` は失敗済み  
> 理由: 既存 A レコード（160.251.168.144）が残っているため

#### 3-1. 既存 A レコードを削除

```
対象ゾーン: ayatori-inc.co.jp
レコード: toybox  (または toybox.ayatori-inc.co.jp)
Type: A
Content: 160.251.168.144
→ 削除する
```

#### 3-2. CNAME レコードを追加（Tunnel 向け）

CloudFlare UI → DNS → Records → Add record:

| 項目 | 値 |
|------|-----|
| Type | **CNAME** |
| Name | **toybox** |
| Target | **3d431ab0-9cb3-4392-ae12-b108aaa0d91a.cfargotunnel.com** |
| Proxy status | **Proxied**（オレンジ雲） |
| TTL | Auto |

**または Zero Trust UI:**
1. Zero Trust → Networks → Tunnels → `toybox-check`
2. Public Hostname → Add
3. Subdomain: `toybox` / Domain: `ayatori-inc.co.jp`
4. Service: `http://localhost:8000`（config 側と一致）

#### 3-3. CLI で再試行する場合（A削除後）

```bash
ssh toyboxssh.ayatori-inc.co.jp
cloudflared tunnel route dns toybox-check toybox.ayatori-inc.co.jp
```

---

### Phase 4: DNS 切替え後の確認

#### 4-1. 事前チェック（済）

- docker compose: web/db/redis 稼働中
- health: `{"status": "ok"}`
- Tunnel: Registered

#### 4-2. 切替え後の確認コマンド

```bash
# 1. health
curl https://toybox.ayatori-inc.co.jp/api/health/
# 期待：{"status": "ok"}

# 2. ブラウザ
# https://toybox.ayatori-inc.co.jp/
# https://toybox.ayatori-inc.co.jp/admin/

# 3. メディア表示（投稿画像）を目視確認
```

---

### Phase 5: 既存本番サーバーの停止（最終）

#### 5-1. 最終バックアップ（オプション）

```bash
# 念のため、既存サーバーから最後のバックアップを取得
scp root@160.251.168.144:/backup/toybox/database/toybox_*.dump \
  /home/ayatori/backups/toybox/database/final_backup/
```

#### 5-2. サービス停止

```bash
# 既存本番サーバーで実行
ssh root@160.251.168.144

# Docker を停止
docker compose down

# または個別に停止
systemctl stop toybox || true
```

#### 5-3. サーバーシャットダウン（オプション）

```bash
# VPS をシャットダウン（ConoHa コンソールから）
# または：
shutdown -h now
```

---

## ⚠️ リスク管理

### ロールバック計画

**もし新規サーバーが不安定な場合：**

1. CloudFlare DNS を 既存サーバーに戻す
   ```
   toybox.ayatori-inc.co.jp A 160.251.168.144
   ```

2. 既存サーバーを再起動
   ```bash
   ssh root@160.251.168.144
   docker compose up -d
   ```

3. 確認
   ```bash
   curl https://toybox.ayatori-inc.co.jp/api/health/
   ```

### バックアップ戦略

- **Go-Live 前**: 新規サーバーでバックアップ実行
- **最終バックアップ**: 既存サーバーから取得
- **保持世代**: 1世代（容量重視）

---

## 📋 チェックリスト

### 実行前チェック
- [ ] CloudFlare ダッシュボードにアクセス可能か
- [ ] SSH キー(`~/.ssh/ayatori_vps1.pem`)が動作しているか
- [ ] 新規サーバーで CloudFlare Tunnel が正常に稼働しているか
- [ ] テストドメイン(toybox-check)でアクセスできるか
- [ ] バックアップが完了しているか

### 実行中チェック
- [ ] cloudflared 再起動後、ログに "Registered tunnel" が表示されたか
- [ ] CloudFlare DNS 設定を変更した
- [ ] TTL 待機中（5-10分）
- [ ] nslookup で新しい DNS を確認した

### 実行後チェック
- [ ] https://toybox.ayatori-inc.co.jp/api/health/ で {"status": "ok"} が返ってくる
- [ ] https://toybox.ayatori-inc.co.jp/admin/ にログインできる
- [ ] ユーザー・投稿データが表示される
- [ ] メディアファイル（画像など）が表示される
- [ ] 既存サーバーへのアクセスが失敗する（期待動作）

### クリーンアップ
- [ ] 既存サーバーのサービスを停止した
- [ ] 既存サーバーのシャットダウンを依頼した
- [ ] 最終バックアップを確認した

---

## 🎯 推奨タイミング

### Go-Live の最適な時間帯
- **業務外時間** (例：夜間 22:00-翌8:00)
- **TTL 短縮後** (事前に TTL を 5分に変更)
- **テスト検証完了後**

### 所要時間
- 準備: 10分
- Tunnel 設定: 5分
- DNS 更新: 1分
- TTL 待機: 5-10分
- 検証: 10分
- **合計: 30-40分**

---

## 📞 問題発生時の連絡先

### If CloudFlare Tunnel が接続できない
1. `cloudflared` プロセスを確認
2. ログを確認：`docker logs ...`
3. ネットワーク接続を確認：`ping origin.cursor.com`

### If DNS が反映されない
1. CloudFlare ダッシュボードで設定を再確認
2. TTL を短縮（30秒）して再試行
3. ブラウザキャッシュをクリア

### If アクセスが 502 Bad Gateway
1. 新規サーバーで web コンテナが起動しているか確認
2. ALLOWED_HOSTS に toybox.ayatori-inc.co.jp が含まれているか確認
3. CloudFlare Tunnel の設定で localhost:8000 を指しているか確認

---

**作成日**: 2026/10/07  
**ステータス**: ✅ Go-Live 完了（本番は新規サーバー / CloudFlare Tunnel）  
**最終更新**: 2026/10/07 17:48 JST

### Go-Live 検証結果（2026/10/07 17:48）
- [x] `https://toybox.ayatori-inc.co.jp/api/health/` → `{"status": "ok"}` (HTTP 200)
- [x] `https://toybox.ayatori-inc.co.jp/` → TOYBOX トップ表示 (HTTP 200)
- [x] DNS → Cloudflare Anycast（例: 172.67.133.142 / 104.21.13.249）
- [x] Tunnel / Docker 稼働中
- [x] 既存本番は停止済み（Phase 5 先行完了）
