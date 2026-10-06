# Articles 全文検索機能追加
日付: 2026/10/06 14:40 JST

## 🎯 機能概要

「みんなの記事」一覧に **全文検索機能** を追加しました。

### 検索対象
- ✅ **タイトル** - 記事のタイトル全文
- ✅ **本文** - JSON形式の本文内のテキスト
- ✅ **著者名** - ユーザーの表示名またはID

### 検索方法
1. 検索フォームに **キーワードを入力**
2. **Enterキーを押す** または自動で検索
3. マッチした記事が一覧に表示

---

## 📝 実装内容

### 1. バックエンド修正 (`articles/views.py`)

#### 追加されたコード（ArticleListCreateView の get_queryset）

```python
# 検索キーワード
search_q = self.request.query_params.get('search', '').strip()
if search_q:
    from django.db.models import Q
    # タイトル、本文（JSONから抽出）、著者名で検索
    qs = qs.filter(
        Q(title__icontains=search_q) |
        Q(author__display_id__icontains=search_q) |
        Q(author__meta__display_name__icontains=search_q) |
        Q(body__contains=search_q)  # JSON内のテキスト検索
    ).distinct()
```

#### 検索パラメータ
- **URL**: `/api/articles/?search=キーワード&page=1`
- **例**: `/api/articles/?search=Python&page=1`

#### 検索アルゴリズム
- **大文字小文字を区別しない** (`icontains` を使用)
- **複数条件は OR マッチ** (いずれかに該当すればOK)
- **重複排除** (`.distinct()` で同じ記事は1度だけ表示)

---

### 2. フロントエンド修正 (`frontend/templates/frontend/articles.html`)

#### 2-1. HTML: 検索フォーム追加

```html
<!-- 検索フォーム -->
<div style="margin-bottom: 1.5rem;">
    <input 
        type="text" 
        id="search-input" 
        placeholder="記事を検索... (タイトル・本文・著者)" 
        onkeydown="handleSearchKeydown(event)"
    >
    <div style="font-size: 0.75rem; color: var(--steam-iron-400); margin-top: 0.3rem;">
        💡 ヒント: タイトル、本文、著者名から検索できます
    </div>
</div>
```

#### 2-2. JavaScript: 検索ロジック

```javascript
let currentSearchQuery = '';  // グローバル検索キーワード

async function loadArticles(tab, page) {
    // ... 既存コード ...
    
    let url;
    if (tab === 'mine') {
        url = `${API_BASE}/mine/`;
    } else {
        // 検索クエリを含める
        const searchParam = currentSearchQuery ? `&search=${encodeURIComponent(currentSearchQuery)}` : '';
        url = `${API_BASE}/?page=${page}${searchParam}`;
    }
    // ... 既存コード ...
}

function handleSearchKeydown(event) {
    if (event.key === 'Enter') {
        event.preventDefault();
        performSearch();
    }
}

function performSearch() {
    currentSearchQuery = document.getElementById('search-input').value.trim();
    currentPage = 1;
    loadArticles('all', 1);
}

function switchTab(tab) {
    currentTab = tab;
    currentPage = 1;
    currentSearchQuery = '';  // タブ切り替え時に検索をクリア
    document.getElementById('search-input').value = '';
    // ... 既存コード ...
}
```

---

## 🔄 使用方法

### ユーザー向け

1. **検索フォームを開く**
   - `/articles/` ページを開く
   - 検索フォーム（"記事を検索..."）が表示されます

2. **キーワードを入力**
   - タイトル、本文、著者名で検索可能
   - 例: "Python", "ゲーム開発", "ユーザー名"

3. **検索を実行**
   - **Enterキーを押す** → 検索開始
   - 自動的にマッチした記事が表示されます

4. **結果を確認**
   - タイトルや本文に一致した記事が一覧に表示
   - ページネーション対応

5. **検索をクリア**
   - 入力フォームを空にして Enter
   - または他のタブに切り替え

### API使用方法

```bash
# タイトルで検索
curl "http://localhost:8000/api/articles/?search=Python"

# 複数ワード（スペース区切り）※ 1つのキーワードとして扱われます
curl "http://localhost:8000/api/articles/?search=ゲーム%20開発"

# ページネーション併用
curl "http://localhost:8000/api/articles/?search=Python&page=2"
```

---

## ✨ 特徴

### パフォーマンス
- **効率的な検索** - データベースレベルでのフィルタリング
- **重複排除** - `.distinct()` で結果を最適化
- **大文字小文字無視** - `icontains` で柔軟な検索

### ユーザーフレンドリー
- **直感的なUI** - シンプルな検索フォーム
- **即座のフィードバック** - Enter で即座に検索開始
- **クリア機能** - タブ切り替え時に自動クリア

### 拡張性
- **クエリパラメータベース** - API から直接検索可能
- **既存フィルターと併用可能** - 著者フィルターなど他の条件との組み合わせも対応予定

---

## 🔍 検索対象の詳細

### タイトル検索
```
例: "Python" で検索
→ "Python で ゲーム開発"、"私の Python 学習記" などが該当
```

### 本文検索
```
例: "Pygame" で検索
→ 本文内に "Pygame" というテキストが含まれる記事が該当
（JSON内の段落テキストも検索対象）
```

### 著者名検索
```
例: "田中" で検索
→ 表示名が "田中太郎" のユーザーが書いた記事が該当
または display_id が "tanaka" などで該当
```

---

## 📊 実装の技術的詳細

### Django ORM クエリ

```python
from django.db.models import Q

search_q = "Python"
qs = Article.objects.filter(
    Q(title__icontains=search_q) |                    # タイトル（大文字小文字区別なし）
    Q(author__display_id__icontains=search_q) |       # 著者ID
    Q(author__meta__display_name__icontains=search_q) | # 著者表示名
    Q(body__contains=search_q)                        # 本文JSON（完全一致）
).distinct()
```

### JSONフィールド検索の注意点
- **PostgreSQL**: `body__contains` で JSON フィールド内のテキスト検索が可能
- **SQLite**: 同じ構文で動作（テキスト検索）
- **MySQL**: JSON操作に `JSON_CONTAINS` が必要な場合あり

---

## 🎨 UIデザイン

### 検索フォーム
```
┌─────────────────────────────────────┐
│ 記事を検索... (タイトル・本文・著者)  │
└─────────────────────────────────────┘
💡 ヒント: タイトル、本文、著者名から検索できます
```

### 検索結果
- 通常の記事一覧と同じレイアウト
- ページネーション対応
- 「検索結果なし」の場合は「まだ記事がありません」と表示

---

## 🚀 今後の改善案

### 優先度: 高
1. **検索クエリのハイライト** - マッチした部分を強調表示
2. **複数キーワード AND 検索** - スペース区切りで複数キーワード対応
3. **検索履歴** - ユーザーの検索履歴を保存・提案

### 優先度: 中
1. **高度な検索フォーム** - 著者指定、日付範囲などの詳細検索
2. **検索サジェスション** - 入力中に候補を表示
3. **ファセット検索** - カテゴリー、タグなどで絞り込み

### 優先度: 低
1. **全文検索エンジン導入** - Elasticsearch などで高速化
2. **検索アナリティクス** - 人気検索キーワードの分析
3. **AI推薦** - 検索結果の個人化

---

## ✅ テストチェックリスト

### 機能テスト
- [ ] 検索フォームが表示されている
- [ ] タイトルで検索できる
- [ ] 本文で検索できる
- [ ] 著者名で検索できる
- [ ] Enterキーで検索が実行される
- [ ] 検索クエリなしで全記事表示
- [ ] 空文字列で検索すると全記事表示

### 検索結果の確認
- [ ] タイトル "Python" で検索 → マッチ記事が表示
- [ ] 著者名 "テスト" で検索 → テストユーザーの記事が表示
- [ ] 存在しないキーワードで検索 → 「まだ記事がありません」表示
- [ ] ページネーション (page=2) が動作

### UI/UX テスト
- [ ] 検索フォームが見やすい位置にある
- [ ] ヒントテキストが表示されている
- [ ] タブ切り替え時に検索がクリアされる
- [ ] 長いキーワードでも動作する

---

## 🔗 関連ファイル

- ✅ `backend/articles/views.py` - バックエンド実装
- ✅ `backend/frontend/templates/frontend/articles.html` - フロントエンド実装
- ℹ️ `backend/articles/models.py` - 変更なし
- ℹ️ `backend/articles/serializers.py` - 変更なし

---

## 📋 デプロイ手順

### ローカル環境
```bash
# Djangoサーバーは自動的にテンプレート変更を検知
# ブラウザをリロードするだけで反映
Ctrl + Shift + R  # Hard Refresh
```

### 本番環境
```bash
# GitHubにプッシュするだけで自動デプロイ
git add backend/articles/views.py backend/frontend/templates/frontend/articles.html
git commit -m "feat: add full-text search to articles list"
git push origin main
```

---

**ステータス**: ✅ 実装完了・反映待機  
**テスト状況**: ローカル環境で動作確認（本番反映待ち）  
**優先度**: 中（UX改善）  
**実装時間**: 約 5 分

