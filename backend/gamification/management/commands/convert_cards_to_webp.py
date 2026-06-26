"""
カード画像（PNG/JPG）を WebP に一括変換し、DB の image_url も更新する。
"""
from pathlib import Path

from django.conf import settings
from django.core.management.base import BaseCommand
from PIL import Image

from gamification.models import Card

SOURCE_EXTENSIONS = {'.png', '.jpg', '.jpeg'}


class Command(BaseCommand):
    help = 'Convert card images under MEDIA_ROOT/cards/ to WebP and update Card.image_url'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='変換せず対象ファイルのみ表示',
        )
        parser.add_argument(
            '--remove-original',
            action='store_true',
            help='変換成功後に元ファイルを削除',
        )
        parser.add_argument(
            '--quality',
            type=int,
            default=85,
            help='WebP 品質（1-100、デフォルト 85）',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        remove_original = options['remove_original']
        quality = max(1, min(100, options['quality']))
        cards_dir = Path(settings.MEDIA_ROOT) / 'cards'

        if not cards_dir.exists():
            self.stdout.write(self.style.WARNING(f'カードディレクトリがありません: {cards_dir}'))
            self._update_db_urls(dry_run)
            return

        converted = 0
        skipped = 0
        errors = 0

        for file_path in sorted(cards_dir.iterdir()):
            if not file_path.is_file():
                continue
            if file_path.suffix.lower() not in SOURCE_EXTENSIONS:
                continue

            webp_path = file_path.with_suffix('.webp')
            self.stdout.write(f'Processing: {file_path.name}')

            if dry_run:
                self.stdout.write(f'  → Would convert to: {webp_path.name}')
                converted += 1
                continue

            try:
                with Image.open(file_path) as img:
                    if img.mode in ('RGBA', 'LA', 'P'):
                        img = img.convert('RGBA')
                    else:
                        img = img.convert('RGB')
                    img.save(webp_path, 'WEBP', quality=quality, method=6)
                self.stdout.write(self.style.SUCCESS(f'  → Saved: {webp_path.name}'))
                converted += 1
                if remove_original:
                    file_path.unlink()
                    self.stdout.write(f'  → Removed original: {file_path.name}')
            except Exception as exc:
                self.stdout.write(self.style.ERROR(f'  → Failed: {exc}'))
                errors += 1

        for file_path in sorted(cards_dir.glob('*.webp')):
            if file_path.with_suffix('.png').exists() or file_path.with_suffix('.jpg').exists():
                skipped += 1

        self._update_db_urls(dry_run)

        if dry_run:
            self.stdout.write(self.style.WARNING(f'\nDry run: {converted} files would be converted'))
        else:
            self.stdout.write(self.style.SUCCESS(f'\nConverted {converted} card images to WebP'))
            if errors:
                self.stdout.write(self.style.ERROR(f'Failed: {errors}'))

    def _update_db_urls(self, dry_run: bool):
        updated = 0
        for card in Card.objects.exclude(image_url__isnull=True).exclude(image_url=''):
            if card.image_url and card.image_url.endswith('.png'):
                new_url = card.image_url[:-4] + '.webp'
                if dry_run:
                    self.stdout.write(f'Would update DB: {card.code} → {new_url}')
                else:
                    card.image_url = new_url
                    card.save(update_fields=['image_url'])
                updated += 1
        if updated:
            label = 'Would update' if dry_run else 'Updated'
            self.stdout.write(self.style.SUCCESS(f'{label} {updated} Card.image_url records'))
