# TOYBOX 本番移行・稼働報告（サマリー）
**日付**: 2026/10/07  
**対象**: 新規本番サーバー（CloudFlare Tunnel / toyboxssh）  
**ステータス**: ✅ Go-Live 完了・初回バックアップ成功

---

## 本日の結論

既存 ConoHa 本番を停止し、`toybox.ayatori-inc.co.jp` を新規サーバーへ切替えた。  
最新バックアップ（@20261007）をリストア済みで、本番アクセス・ログイン・自動バックアップ通知まで確認できた。

---

## 実施内容（要点）

| # | 内容 | 結果 |
|---|------|------|
| 1 | SMTP 通知（Xserver / Google Workspace）整備 | ✅ 受信確認 |
| 2 | バックアップ cron（毎日 02:00）登録 | ✅ |
| 3 | @20261007 を新規サーバーへリストア | ✅ |
| 4 | アップデートお知らせ投稿 | ✅ |
| 5 | Tunnel に本番ホスト追加 + DNS 切替 | ✅ Go-Live |
| 6 | 手動バックアップ実行（ガイド準拠） | ✅ 成功メール受信 |

---

## Go-Live 後の構成

```
ユーザー
  └─ https://toybox.ayatori-inc.co.jp
       └─ CloudFlare Tunnel
            └─ localhost:8000 (Gunicorn / Docker)
                 ├─ PostgreSQL 15
                 ├─ Redis 7
                 └─ Celery worker / beat
```

- SSH: `toyboxssh.ayatori-inc.co.jp`（Tunnel）
- テスト用 `toybox-check` : **削除済み**（2026/10/07）
- Caddy なし（SSL は CloudFlare）

---

## 初回バックアップ実績（手動実行）

| 種別 | ファイル | サイズ | 時刻 (サーバー) |
|------|---------|--------|----------------|
| PostgreSQL | `toybox_20261007_090235.dump` | 2.0M | 09:02:38 |
| メディア | `media_volume_20261007_090235.tar.gz` | 5.7G | 09:05:11 |

- 保存先: `/home/ayatori/backups/toybox/{database,volumes}/`
- 投稿件数: 1,926 / テーブル数: 38 / 整合性: OK
- 通知先: `kobuchi1106@myou-kou.com`
- 以降: 毎日 **02:00** に自動実行予定

---

## リソース状況（Go-Live 後）

| 項目 | 値 | 所見 |
|------|-----|------|
| ディスク | 約 12% 使用（195G 中） | 余裕あり |
| メモリ | 約 1.9Gi | **ボトルネック**（監視継続） |

---

## ユーザー影響・対応

- 切替え直後、一部でプロフィール／フォローTLが古いキャッシュを参照するケースあり  
  → **再ログインで解消**（サーバー障害ではなかった）
- 案内方針: ログアウト → 強制再読み込み／サイトデータ削除 → 再ログイン

---

## 残作業・運用メモ

- [ ] 夜間 cron（02:00）の初回自動実行ログ確認（翌朝）
- [ ] メモリ逼迫時の再発監視（必要なら RAM 増設検討）
- [ ] 既存 ConoHa サーバーの最終廃棄／保管判断
- [x] テスト用ドメイン `toybox-check` を削除（Tunnel ingress / ALLOWED_HOSTS）

---

## 関連ドキュメント

- `33_FINAL_ARCHITECTURE_20261007.md`
- `34_DNS_SWITCHOVER_PLAN_20261007.md`
- `36_BACKUP_CRON_SETUP_20261007.md` / `37_SMTP_AND_CRON_FINAL_SETUP_20261007.md`
- `BACKUP_GUIDE.md`（本番手順・注意点更新済み）

---

**報告者メモ**: 本日の移行作業は完了。本番運用フェーズへ移行。
