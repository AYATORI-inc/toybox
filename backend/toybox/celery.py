"""
Celery configuration for ToyBox project.
"""
import os
from celery import Celery

# Default to prod. Local CLI/tests can override via DJANGO_SETTINGS_MODULE.
# IMPORTANT: toybox/__init__.py imports this before wsgi.py runs, so a "dev"
# default here would force gunicorn onto settings.dev (DEBUG=True, empty CSRF).
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'toybox.settings.prod')

app = Celery('toybox')

# Load task modules from all registered Django apps
app.config_from_object('django.conf:settings', namespace='CELERY')

# Auto-discover tasks from all installed apps
app.autodiscover_tasks()


@app.task(bind=True)
def debug_task(self):
    print(f'Request: {self.request!r}')

