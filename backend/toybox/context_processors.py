"""Template context processors."""
from django.conf import settings


def app_version(request):
    version = getattr(settings, 'APP_VERSION', '2.25')
    return {
        'APP_VERSION': version,
        'APP_VERSION_DISPLAY': f'Ver {version}',
    }
