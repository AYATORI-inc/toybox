# 最新バックアップ SCP 転送コマンド（20261007 → 新規サーバー）
**作成日**: 2026/10/07  
**目的**: ローカル `20261007` を新規サーバーへ転送する（コマンドのみ）

---

## 📁 パス（ここを間違えない）

### ローカル（送信元）
```
C:\github\toybox\20261007\
├── toybox_20261007_162816.dump              ← DB（約 2MB）
└── media_volume_20261007_162850.tar.gz      ← メディア（約 5.6GB）
```

### リモート（送信先）
```
ayatori@toyboxssh.ayatori-inc.co.jp
/home/ayatori/backups/restore_20261007/
```

※ 既存本番（160.251.168.144）や `/backup/toybox/` ではない  
※ `@20260930` フォルダでもない

---

## 1. 転送先ディレクトリ作成

```bash
ssh toyboxssh.ayatori-inc.co.jp "mkdir -p /home/ayatori/backups/restore_20261007"
```

---

## 2. SCP（PowerShell から実行）

### DB（小さい・先に送る）

```powershell
scp -i C:\Users\ayato\.ssh\ayatori_vps1.pem `
  C:\github\toybox\20261007\toybox_20261007_162816.dump `
  ayatori@toyboxssh.ayatori-inc.co.jp:/home/ayatori/backups/restore_20261007/
```

### メディア（大きい・時間がかかる）

```powershell
scp -i C:\Users\ayato\.ssh\ayatori_vps1.pem `
  C:\github\toybox\20261007\media_volume_20261007_162850.tar.gz `
  ayatori@toyboxssh.ayatori-inc.co.jp:/home/ayatori/backups/restore_20261007/
```

---

## 3. 転送確認

```bash
ssh toyboxssh.ayatori-inc.co.jp "ls -lh /home/ayatori/backups/restore_20261007/"
```

期待される結果の目安:
```
toybox_20261007_162816.dump              ~2.0M
media_volume_20261007_162850.tar.gz      ~5.6G
```

---

## メモ
- DB はすでに転送済みの可能性あり（2026/10/07 実施）
- メディア未転送なら上のメディア用 `scp` だけ実行すればよい
