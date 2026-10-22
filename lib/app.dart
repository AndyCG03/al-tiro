import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'application/app_controller.dart';
import 'l10n/app_text.dart';
import 'presentation/alerts_settings.dart';
import 'presentation/calendar_page.dart';
import 'presentation/garage_page.dart';
import 'presentation/home_page.dart';
import 'presentation/theme.dart';
import 'presentation/vehicle_form.dart';
import 'presentation/widgets.dart';
import 'presentation/onboarding.dart';
import 'presentation/brand_components.dart';
import 'presentation/circula_navigation.dart';

class AlTiroApp extends StatelessWidget {
  const AlTiroApp({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext c) => AnimatedBuilder(
    animation: controller,
    builder: (c, _) => MaterialApp(
      title: 'Al Tiro',
      debugShowCheckedModeBanner: false,
      theme: Brand.theme(Brightness.light),
      darkTheme: Brand.theme(Brightness.dark),
      themeMode: controller.themeMode,
      locale: Locale(controller.language),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AppShell(controller: controller),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int index = 0;
  bool explored = false;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        widget.controller.refresh();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.refresh();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final a = widget.controller, t = AppText.of(c);
    void settings() => Navigator.of(c).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          controller: a,
          onTutorial: () => Navigator.of(c).push(
            MaterialPageRoute<void>(
              builder: (_) => TutorialExperience(
                controller: a,
                onComplete: () => Navigator.of(c).pop(),
              ),
            ),
          ),
        ),
      ),
    );
    if (a.displayName.isEmpty) {
      return NameOnboarding(controller: a);
    }
    if (!a.tutorialComplete) {
      return TutorialExperience(
        controller: a,
        onComplete: () {
          a.finishTutorial();
        },
      );
    }
    if (!explored && a.vehicles.isEmpty) {
      return WelcomePage(
        add: () => openVehicleForm(c, a),
        explore: () => setState(() => explored = true),
        settings: settings,
      );
    }
    final wide = MediaQuery.sizeOf(c).width >= 950;
    final destinations = [
      ('home', Icons.home_outlined, Icons.home_rounded),
      ('calendar', Icons.calendar_month_outlined, Icons.calendar_month),
      ('cars', Icons.directions_car_outlined, Icons.directions_car),
      ('alerts', Icons.notifications_none_rounded, Icons.notifications_rounded),
    ];
    final page = switch (index) {
      0 => HomePage(
        controller: a,
        add: () => openVehicleForm(c, a),
        calendar: () => setState(() => index = 1),
      ),
      1 => CalendarPage(controller: a, add: () => openVehicleForm(c, a)),
      2 => GaragePage(controller: a),
      _ => AlertsPage(controller: a),
    };
    return Scaffold(
      appBar: AppBar(
        title: const BrandMark(size: 63),
        toolbarHeight: 84,
        actions: [
          IconButton(
            onPressed: () {
              a.setDate(a.now);
            },
            icon: const Icon(Icons.today_outlined),
            tooltip: t('today'),
          ),
          IconButton(
            onPressed: a.loading ? null : a.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: t('refresh'),
          ),
          IconButton(
            onPressed: settings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: t('settings'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (a.loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: Row(
                children: [
                  if (wide)
                    NavigationRail(
                      extended: true,
                      minExtendedWidth: 210,
                      backgroundColor: Theme.of(c).scaffoldBackgroundColor,
                      selectedIndex: index,
                      onDestinationSelected: (i) => setState(() => index = i),
                      leading: const SizedBox(height: 24),
                      destinations: destinations
                          .map(
                            (d) => NavigationRailDestination(
                              icon: BrandNavGlyph(
                                destinations.indexOf(d),
                                color: Theme.of(c).colorScheme.onSurfaceVariant,
                              ),
                              selectedIcon: BrandNavGlyph(
                                destinations.indexOf(d),
                                color: Theme.of(c).colorScheme.primary,
                              ),
                              label: Text(t(d.$1)),
                            ),
                          )
                          .toList(),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: a.refresh,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: wide ? 820 : 650,
                          ),
                          child: SingleChildScrollView(
                            key: PageStorageKey(index),
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              wide ? 32 : 20,
                              20,
                              wide ? 32 : 20,
                              32,
                            ),
                            child: page,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : CirculaNavigation(
              selectedIndex: index,
              onSelected: (i) => setState(() => index = i),
              destinations: destinations
                  .map((d) => (t(d.$1), d.$2, d.$3))
                  .toList(),
            ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.add,
    required this.explore,
    required this.settings,
  });
  final VoidCallback add, explore, settings;
  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Al Tiro',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: settings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: t('settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (c, constraints) {
            final large = constraints.maxWidth > 850;
            final mascot = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(44),
                  ),
                  child: Image.asset(
                    Brand.logo,
                    width: large ? 270 : 195,
                    height: large ? 250 : 185,
                    semanticLabel: 'Al Tiro',
                  ),
                ),
                const SizedBox(height: 16),
                Text(t('tagline'), style: Theme.of(c).textTheme.titleMedium),
              ],
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('welcomeTitle'),
                  style: Theme.of(c).textTheme.headlineLarge
                      ?.copyWith(fontSize: large ? 46 : 34),
                ),
                const SizedBox(height: 16),
                Text(t('welcomeBody'), style: Theme.of(c).textTheme.bodyLarge),
                const SizedBox(height: 25),
                for (final pair in [
                  (Icons.calendar_month_outlined, 'onboardingBenefit1'),
                  (Icons.directions_car_outlined, 'onboardingBenefit2'),
                  (Icons.verified_outlined, 'onboardingBenefit3'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 17),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Brand.accent(c).withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            pair.$1,
                            color: Theme.of(c).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            t(pair.$2),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: add,
                    label: Text(t('start')),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: explore,
                    child: Text(t('explore')),
                  ),
                ),
              ],
            );
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: large
                      ? Row(
                          children: [
                            Expanded(child: mascot),
                            const SizedBox(width: 80),
                            Expanded(child: details),
                          ],
                        )
                      : Column(
                          children: [
                            mascot,
                            const SizedBox(height: 34),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: details,
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
