from gi.repository import Adw, GLib, Gtk

from . import i18n


class SettingsDialog(Adw.PreferencesDialog):
    def __init__(self, config, localedir):
        super().__init__()
        self.config = config
        self.localedir = localedir
        self.set_search_enabled(False)
        self._page = None
        self._build()

    def _build(self):
        self.set_title(_('Settings'))
        if self._page is not None:
            self.remove(self._page)
        self._page = Adw.PreferencesPage()
        self._page.add(self._build_appearance_group())
        self._page.add(self._build_proxy_group())
        self._page.add(self._build_behavior_group())
        self._page.add(self._build_updates_group())
        self.add(self._page)

    def retranslate(self):
        self._build()

    def _build_appearance_group(self):
        group = Adw.PreferencesGroup(title=_('Appearance'))

        theme_row = Adw.ComboRow(title=_('Theme'))
        theme_ids = ('system', 'light', 'dark')
        theme_names = Gtk.StringList.new(
            [_('Follow system'), _('Light'), _('Dark')]
        )
        theme_row.set_model(theme_names)
        theme_row.set_selected(
            theme_ids.index(self.config.get('theme'))
            if self.config.get('theme') in theme_ids
            else 0
        )
        theme_row.connect(
            'notify::selected',
            lambda row, _p: self.config.set(
                'theme', theme_ids[row.get_selected()]
            ),
        )
        group.add(theme_row)

        languages = i18n.available_languages(self.localedir)
        lang_row = Adw.ComboRow(title=_('Language'))
        labels = []
        for code in languages:
            if code == 'system':
                labels.append(_('Follow system'))
            else:
                labels.append(i18n.language_label(code))
        lang_row.set_model(Gtk.StringList.new(labels))
        current = self.config.get('language')
        lang_row.set_selected(
            languages.index(current) if current in languages else 0
        )
        lang_row.connect(
            'notify::selected',
            lambda row, _p: self.config.set(
                'language', languages[row.get_selected()]
            ),
        )
        group.add(lang_row)
        return group

    def _build_proxy_group(self):
        group = Adw.PreferencesGroup(
            title=_('Proxy'),
            description=_('Local SOCKS5 endpoint exposed by byedpi.'),
        )

        host_row = Adw.EntryRow(title=_('Listen address'))
        host_row.set_text(self.config.get('listen_host'))
        host_row.connect(
            'changed',
            lambda row: self.config.set('listen_host', row.get_text().strip()),
        )
        group.add(host_row)

        port_row = Adw.SpinRow.new_with_range(1, 65535, 1)
        port_row.set_title(_('Port'))
        port_row.set_value(self.config.get('listen_port'))
        port_row.connect(
            'notify::value',
            lambda row, _p: self.config.set(
                'listen_port', int(row.get_value())
            ),
        )
        group.add(port_row)

        args_row = Adw.EntryRow(title=_('byedpi arguments'))
        args_row.set_text(self.config.get('extra_args'))
        args_row.connect(
            'changed',
            lambda row: self.config.set('extra_args', row.get_text()),
        )
        group.add(args_row)
        return group

    def _build_behavior_group(self):
        group = Adw.PreferencesGroup(title=_('Behavior'))

        autostart_row = Adw.SwitchRow(
            title=_('Connect on launch'),
            subtitle=_('Start the proxy automatically when the app opens.'),
        )
        autostart_row.set_active(self.config.get('autostart_proxy'))
        autostart_row.connect(
            'notify::active',
            lambda row, _p: self.config.set(
                'autostart_proxy', row.get_active()
            ),
        )
        group.add(autostart_row)

        tray_row = Adw.SwitchRow(
            title=_('Show tray icon'),
            subtitle=_('Requires a restart to take effect.'),
        )
        tray_row.set_active(self.config.get('show_tray'))
        tray_row.connect(
            'notify::active',
            lambda row, _p: self.config.set('show_tray', row.get_active()),
        )
        group.add(tray_row)

        close_row = Adw.SwitchRow(
            title=_('Close to tray'),
            subtitle=_('Keep running in the tray when the window is closed.'),
        )
        close_row.set_active(self.config.get('close_to_tray'))
        close_row.connect(
            'notify::active',
            lambda row, _p: self.config.set('close_to_tray', row.get_active()),
        )
        group.add(close_row)
        return group

    def _build_updates_group(self):
        group = Adw.PreferencesGroup(
            title=_('Updates'),
            description=_(
                'Checks run at startup over HTTPS. Nothing else is sent.'
            ),
        )

        app_row = Adw.SwitchRow(title=_('Check for application updates'))
        app_row.set_active(self.config.get('check_app_updates'))
        app_row.connect(
            'notify::active',
            lambda row, _p: self.config.set(
                'check_app_updates', row.get_active()
            ),
        )
        group.add(app_row)

        core_row = Adw.SwitchRow(
            title=_('Keep byedpi core up to date'),
            subtitle=_('Downloads the matching build from the byedpi project.'),
        )
        core_row.set_active(self.config.get('check_ciadpi_updates'))
        core_row.connect(
            'notify::active',
            lambda row, _p: self.config.set(
                'check_ciadpi_updates', row.get_active()
            ),
        )
        group.add(core_row)
        return group
