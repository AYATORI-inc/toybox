"""
コレクションページの紹介動画（MP4）を WebM に変換する。
ffmpeg が必要です。
"""
import shutil
import subprocess
from pathlib import Path

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

VIDEO_DIR = Path('frontend') / 'static' / 'frontend' / 'videos'
TARGET_MP4 = 'card-game-preview.mp4'
TARGET_WEBM = 'card-game-preview.webm'


class Command(BaseCommand):
    help = 'Convert collection preview video (card-game-preview.mp4) to WebM'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='変換せず対象のみ表示',
        )
        parser.add_argument(
            '--remove-original',
            action='store_true',
            help='変換成功後に MP4 を削除',
        )
        parser.add_argument(
            '--crf',
            type=int,
            default=32,
            help='VP9 品質（数値が大きいほど軽量、デフォルト 32）',
        )

    def handle(self, *args, **options):
        if not shutil.which('ffmpeg'):
            raise CommandError('ffmpeg が見つかりません。インストール後に再実行してください。')

        video_dir = settings.BASE_DIR / VIDEO_DIR
        mp4_path = video_dir / TARGET_MP4
        webm_path = video_dir / TARGET_WEBM

        if not mp4_path.exists():
            self.stdout.write(self.style.WARNING(f'入力動画がありません: {mp4_path}'))
            return

        self.stdout.write(f'Source: {mp4_path}')
        self.stdout.write(f'Output: {webm_path}')

        if options['dry_run']:
            self.stdout.write(self.style.WARNING('Dry run: conversion skipped'))
            return

        cmd = [
            'ffmpeg', '-y', '-i', str(mp4_path),
            '-c:v', 'libvpx-vp9',
            '-crf', str(options['crf']),
            '-b:v', '0',
            '-row-mt', '1',
            '-an',
            str(webm_path),
        ]
        try:
            subprocess.run(cmd, check=True, capture_output=True, text=True)
        except subprocess.CalledProcessError as exc:
            raise CommandError(f'ffmpeg failed: {exc.stderr or exc}') from exc

        self.stdout.write(self.style.SUCCESS(f'Created: {webm_path}'))

        if options['remove_original']:
            mp4_path.unlink()
            self.stdout.write(f'Removed: {mp4_path}')
