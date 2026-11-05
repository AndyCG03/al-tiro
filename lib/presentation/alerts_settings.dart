import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../application/app_controller.dart';
import '../application/circulation_notifications.dart';
import '../domain/models.dart';
import '../l10n/app_text.dart';
import 'theme.dart';
import 'widgets.dart';
import 'hologram_guide.dart';
import 'brand_components.dart';
import 'documents_page.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key, required this.controller});
  final AppController controller;

  Future<void> _openCalendar(
    BuildContext context,
    String title,
    DateTime date,
  ) async {
    final start = DateTime.utc(date.year, date.month, date.day);
    try {
      final opened = await const MethodChannel('mx.sidarta.al_tiro/calendar')
          .invokeMethod<bool>('addEvent', {
            'title': title,
            'start': start.millisecondsSinceEpoch,
            'end': start.add(const Duration(days: 1)).millisecondsSinceEpoch,
          });
      if (opened == true) return;
    } on PlatformException {
      // Present the same fallback as when no calendar app is installed.
    } on MissingPluginException {
      // A preview or an older native build may lack the calendar channel.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.of(context)('calendarUnavailable'))),
      );
    }
  }

  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c), a = controller;
    final hasCalendar =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final result = a.evaluate();
    final expiring = a.vehicles
        .where(
          (v) =>
              v.validUntil != null &&
              v.validUntil!.difference(civilDate(a.now)).inDays <= 30,
        )
        .toList();
    final today = civilDate(a.now);
    final nextDays =
        [
              for (var offset = 0; offset < 7; offset++)
                today.add(Duration(days: offset)),
            ]
            .map((date) => (date: date, result: a.evaluate(date)))
            .where((day) => day.result?.ordinary == Decision.restricted);
    final through = civilDate(a.now).add(const Duration(days: 30));
    final deadlines = [
      for (final vehicle in a.vehicles) ...[
        for (final doc in vehicle.documents)
          if (doc.expiresOn case final date? when !date.isAfter(through))
            (
              name: vehicle.name,
              label: doc.title.isEmpty
                  ? t(documentKindKey(doc.kind))
                  : doc.title,
              date: date,
            ),
        for (final service in vehicle.maintenance)
          if (service.nextServiceOn case final date?
              when !date.isAfter(through))
            (
              name: vehicle.name,
              label: '${t('nextService')} · ${service.title}',
              date: date,
            ),
      ],
    ]..sort((a, b) => a.date.compareTo(b.date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandSectionHeader(t('yourAlerts'), t('alertBody')),
        if (a.region == Region.cdmx) OfficialSmsButton(vehicle: a.active),
        if (a.extraordinary) ...[
          Surface(
            color: Brand.accent(c).withValues(alpha: .09),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: Brand.accent(c),
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
                      leading: Icon(Icons.event_busy, color: Brand.accent(c)),
                      title: Text(prettyDate(c, d.date, 'EEEE d MMM')),
                      subtitle: Text(
                        '${a.active?.name} · ${d.result!.windows.map((w) => w.label).toSet().join(', ')}',
                      ),
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
                  leading: Icon(
                    Icons.assignment_late_outlined,
                    color: Brand.accent(c),
                  ),
                  title: Text(
                    t(
                      v.validUntil!.isBefore(civilDate(a.now))
                          ? 'verificationExpired'
                          : 'verificationSoon',
                    ),
                  ),
                  subtitle: Text('${v.name} · ${dateKey(v.validUntil!)}'),
                  trailing: hasCalendar
                      ? IconButton(
                          tooltip: t('addToPhoneCalendar'),
                          icon: const Icon(Icons.event_available_outlined),
                          onPressed: () => _openCalendar(
                            c,
                            t('verificationSoon'),
                            v.validUntil!,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          for (final deadline in deadlines)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Surface(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.event_outlined, color: Brand.accent(c)),
                  title: Text(deadline.label),
                  subtitle: Text(
                    '${deadline.name} · ${prettyDate(c, deadline.date, 'd MMM y')}',
                  ),
                  trailing: hasCalendar
                      ? IconButton(
                          tooltip: t('addToPhoneCalendar'),
                          icon: const Icon(Icons.event_available_outlined),
                          onPressed: () =>
                              _openCalendar(c, deadline.label, deadline.date),
                        )
                      : null,
                ),
              ),
            ),
          if (expiring.isEmpty && deadlines.isEmpty)
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
              if (CirculationNotifications.supported && !a.preview)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t('circulationNotifications')),
                  subtitle: Text(t('circulationNotificationsHelp')),
                  value: a.circulationNotifications,
                  onChanged: (enabled) async {
                    if (enabled &&
                        !await CirculationNotifications.requestPermission()) {
                      if (c.mounted) {
                        ScaffoldMessenger.of(c).showSnackBar(
                          SnackBar(
                            content: Text(t('circulationNotificationsDenied')),
                          ),
                        );
                      }
                      return;
                    }
                    await a.setCirculationNotifications(enabled);
                    if (!enabled) await CirculationNotifications.clear();
                  },
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
  const SettingsPage({super.key, required this.controller, this.onTutorial});
  final VoidCallback? onTutorial;
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
                const Center(child: BrandMark(size: 126, wordmark: false)),
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
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Icon(
                      Icons.auto_stories_outlined,
                      color: Theme.of(c).colorScheme.primary,
                    ),
                    title: Text(
                      t('guideTitle'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(t('guideSubtitle')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openHologramGuide(c),
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
                const SizedBox(height: 16),
                if (onTutorial != null)
                  OutlinedButton.icon(
                    onPressed: onTutorial,
                    icon: const Icon(Icons.explore_outlined),
                    label: Text(t('repeatTutorial')),
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
