#!/usr/bin/env python
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'toybox.settings.prod')
django.setup()

from django.contrib.auth import get_user_model
from users.models import UserMeta

User = get_user_model()

# Create superuser
if not User.objects.filter(email='admin@test.local').exists():
    admin = User.objects.create_superuser(
        email='admin@test.local',
        password='admin123',
        display_id='admin'
    )
    # Create UserMeta if it doesn't exist
    UserMeta.objects.get_or_create(user=admin)
    print(f"✅ スーパーユーザー作成完了: {admin.display_id} ({admin.email})")
else:
    print(f"✅ 管理者ユーザーは既に存在します")

# Create test user
if not User.objects.filter(email='testuser@test.local').exists():
    testuser = User.objects.create_user(
        email='testuser@test.local',
        password='testpass123',
        display_id='testuser'
    )
    UserMeta.objects.get_or_create(user=testuser)
    print(f"✅ テストユーザー作成完了: {testuser.display_id} ({testuser.email})")
else:
    print(f"✅ テストユーザーは既に存在します")

print(f"\n現在のユーザー数: {User.objects.count()}")
