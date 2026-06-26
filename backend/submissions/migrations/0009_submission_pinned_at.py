from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('submissions', '0008_reaction_types_bookmark'),
    ]

    operations = [
        migrations.AddField(
            model_name='submission',
            name='pinned_at',
            field=models.DateTimeField(blank=True, db_index=True, null=True, verbose_name='ピン留め日時'),
        ),
    ]
