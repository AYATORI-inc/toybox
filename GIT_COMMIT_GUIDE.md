# Git コミット・マージガイド

## 現在の状態
- **現在のブランチ**: AyatoriControl
- **最新ドキュメント**: PRODUCTION_GOTCHAS_20261006.md（作成済み）
- **目標**: main ブランチにマージしてプッシュ

## 実行手順（ローカルで実行）

### ステップ 1: ドキュメントをコミット
```bash
cd C:\github\toybox
git add doc/PRODUCTION_GOTCHAS_20261006.md
git commit -m "docs: Add production gotchas document for setup reference"
git push origin AyatoriControl
```

### ステップ 2: main ブランチにマージ
```bash
git checkout main
git pull origin main
git merge AyatoriControl
git push origin main
```

### ステップ 3: 確認
```bash
git log --oneline -5
git branch -a
```

## 完了

その後、新本番サーバーへセットアップを開始してください。

