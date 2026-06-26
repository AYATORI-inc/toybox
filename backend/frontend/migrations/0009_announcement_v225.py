# TOYBOX Ver 2.25 リリースお知らせ
from django.db import migrations

ANNOUNCEMENT_TITLE = 'TOYBOX! Ver 2.25 アップデートのお知らせ'

ANNOUNCEMENT_CONTENT = """TOYBOX! を Ver 2.25 にアップデートしました。
いつもご利用ありがとうございます。主な変更点は以下のとおりです。

■ カード画像の軽量化（WebP）
・コレクションのカード画像を WebP 形式に統一し、表示の読み込みを軽くしました。

■ コレクション動画の軽量化（WebM）
・コレクションページの紹介動画を WebM 形式に変更し、再生時のデータ量を抑えました。

■ ファビコンの更新
・サイトのファビコンを新しいデザインに差し替えました。

■ プロフィール投稿のピン留め
・自分のプロフィールの投稿一覧で、先頭に固定表示できるピン留め機能を追加しました。
・ピン留めは最大3件まで設定できます。

今後とも TOYBOX! をよろしくお願いいたします。"""


def create_v225_announcement(apps, schema_editor):
    Announcement = apps.get_model('frontend', 'Announcement')
    if Announcement.objects.filter(title=ANNOUNCEMENT_TITLE).exists():
        return
    Announcement.objects.create(
        title=ANNOUNCEMENT_TITLE,
        content=ANNOUNCEMENT_CONTENT,
        is_active=True,
    )


def remove_v225_announcement(apps, schema_editor):
    Announcement = apps.get_model('frontend', 'Announcement')
    Announcement.objects.filter(title=ANNOUNCEMENT_TITLE).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('frontend', '0008_announcement_v224'),
    ]

    operations = [
        migrations.RunPython(create_v225_announcement, remove_v225_announcement),
    ]
