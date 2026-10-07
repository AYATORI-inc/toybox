# Articles 見出し画像表示修正
日付: 2026/10/06 14:35 JST

## 🎯 修正内容

### 問題点
- Articles 機能の見出し画像が **固定された縦横比** により上下が切れていた
- 16:9 の画像が 1:1 にトリミングされる問題
- エディタでは見えるが、実際の表示では異なる

### 原因
CSS プロパティの設定が不適切
```css
/* 修正前 */
object-fit: cover;     /* 画像を枠に合わせるため上下がカット */
max-height: 360px;     /* 高さ固定により、縦長画像が制限される */
width: 100%;
```

---

## 📝 実施した修正

### 1. 記事詳細ページ (`article_detail.html`, 行12)

#### 修正内容
```css
/* 修正前 */
.article-hero-thumb { 
    width: 100%; 
    max-height: 360px; 
    object-fit: cover; 
    border-radius: 10px; 
    margin-bottom: 1.5rem; 
}

/* 修正後 */
.article-hero-thumb { 
    width: 100%; 
    height: auto;              /* ← 高さを自動に */
    object-fit: contain;       /* ← cover → contain に変更 */
    border-radius: 10px; 
    margin-bottom: 1.5rem; 
}
```

#### 効果
- ✅ 16:9 の画像が上下切れずに全表示
- ✅ 縦長 (9:16) の画像も全て見える
- ✅ 正方形画像もそのまま表示

---

### 2. 記事一覧ページ (`articles.html`, 行29-32)

#### 修正内容
```css
/* 修正前 */
.article-thumb {
    width: 120px; 
    height: 80px; 
    object-fit: cover;        /* サムネを枠いっぱいに */
    border-radius: 6px;
    background: var(--steam-iron-800);
}

/* 修正後 */
.article-thumb {
    width: 120px; 
    height: 80px; 
    object-fit: contain;       /* ← cover → contain に変更 */
    border-radius: 6px;
    background: var(--steam-iron-800);
}
```

#### 効果
- ✅ サムネが120x80の枠内に納まる（縦横比保持）
- ✅ 切り詰められない
- ✅ 一覧がきれいに整列

---

### 3. 記事エディタ (`article_editor.html`)

#### 3-1. サムネプレビュー (行36)

```css
/* 修正前 */
#thumb-preview { 
    width: 100%; 
    max-height: 200px; 
    object-fit: cover; 
    border-radius: 8px; 
    margin-bottom: 0.35rem; 
    display: none; 
}

/* 修正後 */
#thumb-preview { 
    width: 100%; 
    height: auto;              /* ← 高さを自動に */
    object-fit: contain;       /* ← cover → contain に変更 */
    border-radius: 8px; 
    margin-bottom: 0.35rem; 
    display: none; 
}
```

#### 3-2. ブロック内画像 (行69)

```css
/* 修正前 */
.block-image-preview { 
    max-width: 100%; 
    max-height: 200px; 
    object-fit: cover; 
    border-radius: 6px; 
    margin-top: 0.4rem; 
    display: block; 
}

/* 修正後 */
.block-image-preview { 
    max-width: 100%; 
    height: auto;              /* ← 高さを自動に */
    object-fit: contain;       /* ← cover → contain に変更 */
    border-radius: 6px; 
    margin-top: 0.4rem; 
    display: block; 
}
```

#### 効果
- ✅ エディタで「見たままに」表示
- ✅ 実際の投稿との齟齬がない
- ✅ ユーザーが確実に意図した画像を投稿可能

---

## 🔄 反映方法

### ローカル開発
```powershell
# Djangoサーバーは自動的にテンプレート変更を検知
# ブラウザをリロード

# キャッシュクリア（推奨）
Ctrl + Shift + R  # Hard Refresh
```

### 本番環境
```bash
# デプロイ後、CDNキャッシュをクリア
# または、テンプレートキャッシュをリセット

# Gunicorn / Nginx を再起動する場合
systemctl restart toybox_gunicorn
```

---

## ✅ 検証チェックリスト

### テスト対象
- [ ] 16:9 の画像（Youtube比）が上下切れずに表示
- [ ] 9:16 の縦長画像が全て見える
- [ ] 1:1 の正方形画像が正しく表示
- [ ] 記事一覧のサムネが整然と表示
- [ ] エディタプレビューが実際の表示と一致

### テスト手順
1. **記事詳細ページで確認**
   - 記事を開く
   - 見出し画像を確認
   - 複数の画像サイズでテスト

2. **一覧ページで確認**
   - /articles/ を開く
   - サムネイルが整然と表示されているか確認

3. **エディタで確認**
   - /articles/new/ で新規記事作成
   - サムネと画像ブロックをアップロード
   - プレビュー表示が正確か確認

---

## 📊 CSS変更の詳細

### object-fit の動作比較

| プロパティ | 動作 | 用途 |
|-----------|------|------|
| **cover** | 枠いっぱいに表示（上下・左右切れる） | バナー全体を埋める |
| **contain** | 縦横比保持して枠内に納める（隙間あり） | 全画像を見る（推奨） |
| **fill** | 枠に合わせるだけ（歪む） | 非推奨 |
| **scale-down** | contain か元のサイズ小さい方 | ロゴなど |

**今回の選択**: `contain` ← 全画像を見ることが最優先

---

## 🎨 ビジュアル変更

### 修正前 (cover の場合)
```
【16:9画像】         【9:16画像】        【1:1画像】
┌─────────────┐     ┌──────┐            ┌────┐
│ ▓▓▓▓▓▓▓▓▓▓  │     │      │            │    │
│ ▓▓▓▓▓▓▓▓▓▓  │     │      │            │    │
│ ▓▓▓▓▓▓▓▓▓▓  │     │      │ (切れる)    │    │
└─────────────┘     └──────┘            └────┘
  (上下切れる)       (横が切れる)
```

### 修正後 (contain の場合)
```
【16:9画像】         【9:16画像】        【1:1画像】
┌─────────────┐     ┌────────┐          ┌────────┐
│             │     │        │          │        │
│  ▓▓▓▓▓▓▓   │     │  ▓▓▓  │          │  ▓▓▓  │
│  ▓▓▓▓▓▓▓   │     │  ▓▓▓  │          │  ▓▓▓  │
│  ▓▓▓▓▓▓▓   │     │  ▓▓▓  │          │  ▓▓▓  │
│             │     │        │          │        │
└─────────────┘     └────────┘          └────────┘
  (全表示 ✓)       (全表示 ✓)         (全表示 ✓)
```

---

## 📋 関連ファイル

- ✅ `backend/frontend/templates/frontend/article_detail.html` - 修正済み
- ✅ `backend/frontend/templates/frontend/articles.html` - 修正済み
- ✅ `backend/frontend/templates/frontend/article_editor.html` - 修正済み

---

## 🔍 今後の検討事項

### オプション: アスペクト比を制限したい場合
背景を使う方法
```css
.article-hero-thumb {
    width: 100%;
    height: auto;
    object-fit: contain;
    background: var(--steam-iron-800);  /* ← 余白を目立たせない */
    border-radius: 10px;
}
```

### オプション: 最大高さを設定したい場合
```css
.article-hero-thumb {
    width: 100%;
    max-height: 600px;          /* ← 異常に長い画像を制限 */
    object-fit: contain;
    border-radius: 10px;
}
```

---

**ステータス**: ✅ 修正完了・反映待機
**テスト状況**: ローカル環境で動作確認（本番反映待ち）
**優先度**: 中（UX改善）

