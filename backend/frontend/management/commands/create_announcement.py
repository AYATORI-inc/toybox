"""
管理コマンド: Announcement を作成

使用例:
    python manage.py create_announcement --title "アップデート通知" --content "本番環境がアップデートされました"
    python manage.py create_announcement --title "お知らせ" --content "本文" --inactive
"""

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from frontend.models import Announcement

User = get_user_model()


class Command(BaseCommand):
    help = 'Create a new announcement'

    def add_arguments(self, parser):
        parser.add_argument(
            '--title',
            type=str,
            required=True,
            help='Announcement title',
        )
        parser.add_argument(
            '--content',
            type=str,
            required=True,
            help='Announcement content',
        )
        parser.add_argument(
            '--created-by',
            type=str,
            default=None,
            help='Creator username (default: first admin user)',
        )
        parser.add_argument(
            '--inactive',
            action='store_true',
            help='Create as inactive (not displayed)',
        )

    def handle(self, *args, **options):
        title = options['title']
        content = options['content']
        is_active = not options['inactive']
        
        # Get creator user
        created_by_username = options.get('created_by')
        if created_by_username:
            try:
                created_by = User.objects.get(username=created_by_username)
            except User.DoesNotExist:
                self.stdout.write(
                    self.style.ERROR(f'User "{created_by_username}" not found')
                )
                return
        else:
            # Use first admin user or superuser
            created_by = User.objects.filter(is_staff=True).first()
            if not created_by:
                created_by = User.objects.filter(is_superuser=True).first()
            if not created_by:
                self.stdout.write(
                    self.style.ERROR('No admin user found. Please specify --created-by')
                )
                return
        
        # Create announcement
        announcement = Announcement.objects.create(
            title=title,
            content=content,
            is_active=is_active,
            created_by=created_by,
        )
        
        status = '有効' if is_active else '無効'
        self.stdout.write(
            self.style.SUCCESS(
                f'✅ Announcement created successfully (ID: {announcement.id}, {status})'
            )
        )
        self.stdout.write(f'  Title: {announcement.title}')
        self.stdout.write(f'  Created by: {created_by.username}')
        self.stdout.write(f'  Created at: {announcement.created_at}')
