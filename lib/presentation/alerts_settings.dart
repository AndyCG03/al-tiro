import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_text.dart';
import 'theme.dart';
import 'widgets.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c), a = controller;
    final result = a.evaluate();
    final expiring = a.vehicles
        .where(
          (v) =>
              v.validUntil != null &&
              v.validUntil!.difference(civilDate(a.now)).inDays <= 30,
        )
        .toList();
    final nextDays = List.generate(
      7,
      (i) => civilDate(a.now).add(Duration(days: i)),
    ).where((d) => a.evaluate(d)?.ordinary == Decision.restricted).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(t('yourAlerts'), t('alertBody')),
        if (a.extraordinary) ...[
          Surface(
            color: Brand.pink.withValues(alpha: .09),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: Brand.pink,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  t(
                    result?.noticesConfirmed == true
                        ? 'complete'
                        : 'noticePending',
                  ),
                  style: Theme.of(c).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    result?.noticesConfirmed == true
                        ? 'noticeCoverageReady'
                        : 'noLiveNotice',
                  ),
                ),
                TextButton.icon(
                  onPressed: () => openOfficial(
                    c,
                    a.region == Region.cdmx
                        ? 'https://www.gob.mx/comisionambiental'
                        : 'https://sma.edomex.gob.mx/',
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(t('officialLink')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (result != null)
            ...result.notices.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Surface(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.campaign_outlined),
                    title: Text(n.title),
                    onTap: () => openOfficial(c, n.url),
                  ),
                ),
              ),
            ),
        ],
        if (a.reminders) ...[
          if (nextDays.isNotEmpty)
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('dayBefore'),
                    style: Theme.of(c).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  ...nextDays.map(
                    (d) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_busy, color: Brand.pink),
                      title: Text(prettyDate(c, d, 'EEEE d MMM')),
                      subtitle: Text('${a.active?.name} · 05:00–22:00'),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ...expiring.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Surface(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.assignment_late_outlined,
                    color: Brand.pink,
                  ),
                  title: Text(
                    t(
                      v.validUntil!.isBefore(civilDate(a.now))
                          ? 'verificationExpired'
                          : 'verificationSoon',
                    ),
                  ),
                  subtitle: Text('${v.name} · ${dateKey(v.validUntil!)}'),
                ),
              ),
            ),
          ),
          if (expiring.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(t('noPending')),
            ),
        ],
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('preferences'), style: Theme.of(c).textTheme.titleLarge),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(t('localReminders')),
                value: a.reminders,
                onChanged: a.setReminders,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(t('extraNotices')),
                value: a.extraordinary,
                onChanged: a.setExtraordinary,
              ),
              Text(
                t('noNotifications'),
                style: Theme.of(c).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c), a = controller;
    return Scaffold(
      appBar: AppBar(title: Text(t('settings'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Center(child: BrandMark(size: 84, wordmark: false)),
                const SizedBox(height: 24),
                Surface(
                  child: Column(
                    children: [
                      DropdownButtonFormField<ThemeMode>(
                        key: ValueKey(a.themeMode),
                        initialValue: a.themeMode,
                        decoration: InputDecoration(
                          labelText: t('appearance'),
                          prefixIcon: const Icon(Icons.contrast),
                        ),
                        items: ThemeMode.values
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(t(m.name)),
                              ),
                            )
                            .toList(),
                        onChanged: (m) {
                          if (m != null) {
                            a.setTheme(m);
                          }
                        },
                      ),
                      const SizedBox(height: 22),
                      DropdownButtonFormField<String>(
                        key: ValueKey(a.language),
                        initialValue: a.language,
                        decoration: InputDecoration(
                          labelText: t('language'),
                          prefixIcon: const Icon(Icons.language),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'es',
                            child: Text(t('spanish')),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(t('english')),
                          ),
                        ],
                        onChanged: (s) {
                          if (s != null) {
                            a.setLanguage(s);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('dataMode'),
                        style: Theme.of(c).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t(a.snapshot?.remote == true ? 'apiData' : 'localData'),
                      ),
                      const SizedBox(height: 10),
                      Text(t('privacy')),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () => showSources(c, a),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text(t('legal')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(child: Text(t('about'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
