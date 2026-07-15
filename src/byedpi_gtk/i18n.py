import gettext
import locale
import os

DOMAIN = 'byedpi-gtk'

LANGUAGES = {
    'system': None,
    'en': 'en',
    'tr': 'tr',
}

LANGUAGE_LABELS = {
    'system': None,
    'en': 'English',
    'tr': 'Türkçe',
}


def available_languages(localedir):
    found = ['system', 'en']
    if os.path.isdir(localedir):
        for entry in sorted(os.listdir(localedir)):
            mo = os.path.join(localedir, entry, 'LC_MESSAGES', DOMAIN + '.mo')
            if entry not in found and os.path.exists(mo):
                found.append(entry)
    return found


def setup(localedir, override):
    languages = None
    if override and override != 'system':
        languages = [override]
    try:
        locale.setlocale(locale.LC_ALL, '')
    except locale.Error:
        pass
    try:
        locale.bindtextdomain(DOMAIN, localedir)
        locale.textdomain(DOMAIN)
    except (AttributeError, ValueError):
        pass
    translation = gettext.translation(
        DOMAIN, localedir, languages=languages, fallback=True
    )
    translation.install(names=['ngettext'])
    return translation
