import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import '../l10n/app_text.dart';
import 'alerts_settings.dart';
import 'calendar_page.dart';
import 'circula_navigation.dart';
import 'garage_page.dart';
import 'home_page.dart';
import 'theme.dart';
import 'widgets.dart';

class NameOnboarding extends StatefulWidget {
  const NameOnboarding({super.key, required this.controller});
  final AppController controller;
  @override
  State<NameOnboarding> createState() => _NameOnboardingState();
}

class _NameOnboardingState extends State<NameOnboarding> {
  final name = TextEditingController();
  final form = GlobalKey<FormState>();
  bool saving = false;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate() || saving) {
      return;
    }
    setState(() => saving = true);
    await widget.controller.saveProfile(name.text);
    if (mounted) {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c), scheme = Theme.of(c).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandMark(size: 60),
                    const SizedBox(height: 32),
                    Center(
                      child: Container(
                        width: 176,
                        height: 176,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(44),
                        ),
                        child: Image.asset(Brand.logo),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      t('nameWelcome'),
                      style: Theme.of(c).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('nameWelcomeBody'),
                      style: Theme.of(c).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      key: const Key('profile-name'),
                      controller: name,
                      maxLength: 30,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => submit(),
                      decoration: InputDecoration(
                        labelText: t('yourName'),
                        hintText: t('nameHint'),
                        counterText: '',
                      ),
                      validator: (s) => (s?.trim().runes.length ?? 0) < 2
                          ? t('nameRequired')
                          : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: saving ? null : submit,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(t('continue')),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t('namePrivacy'),
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TutorialExperience extends StatefulWidget {
  const TutorialExperience({
    super.key,
    required this.controller,
    required this.onComplete,
  });
  final AppController controller;
  final VoidCallback onComplete;
  @override
  State<TutorialExperience> createState() => _TutorialExperienceState();
}

class _TutorialExperienceState extends State<TutorialExperience> {
  late final demo = AppController(BundledRepository(), preview: true)
    ..displayName = widget.controller.displayName
    ..region = widget.controller.region
    ..snapshot = widget.controller.snapshot
    ..vehicles = [
      Vehicle(
        id: 'tutorial-only',
        name: 'Demo',
        plate: 'ABC-125',
        modelYear: 2016,
        origin: 'CDMX',
        issuer: 'CDMX',
        hologram: Hologram.one,
        kind: VehicleKind.car,
        appearance: VehicleAppearance.sedan,
        validUntil: DateTime(widget.controller.now.year, 12, 31),
      ),
    ]
    ..selectedId = 'tutorial-only';
  int index = 0;
  @override
  void dispose() {
    demo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c), scheme = Theme.of(c).colorScheme;
    final names = ['home', 'calendar', 'cars', 'alerts'];
    final titles = ['tourHome', 'tourCalendar', 'tourCars', 'tourAlerts'];
    void select(int i) {
      if (i <= index + 1) {
        setState(() => index = i);
      }
    }

    Widget page() => switch (index) {
      0 => HomePage(controller: demo, add: () {}, calendar: () => select(1)),
      1 => CalendarPage(controller: demo, add: () {}),
      2 => GaragePage(controller: demo),
      _ => AlertsPage(controller: demo),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('tutorial'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(onPressed: widget.onComplete, child: Text(t('tourSkip'))),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset(Brand.logo),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${t('step')} ${index + 1} ${t('of')} ${names.length}',
                                style: TextStyle(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            ...List.generate(
                              names.length,
                              (i) => Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Container(
                                  width: i == index ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i == index
                                        ? scheme.primary
                                        : scheme.onPrimaryContainer.withValues(
                                            alpha: .2,
                                          ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t('${titles[index]}Title'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t('${titles[index]}Body'),
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t('demoMode'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        if (index < names.length - 1) ...[
                          const SizedBox(height: 12),
                          Text(
                            t('tourTapSection')
                                .replaceAll('{section}', t(names[index + 1])),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (index > 0) ...[
                              TextButton.icon(
                                onPressed: () => select(index - 1),
                                icon: const Icon(Icons.chevron_left, size: 18),
                                label: Text(t('tourBack')),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: index == names.length - 1
                                    ? widget.onComplete
                                    : () => select(index + 1),
                                icon: Icon(
                                  index == names.length - 1
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  index == names.length - 1
                                      ? t('tourFinish')
                                      : '${t('tourGoTo')} ${t(names[index + 1])}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: demo,
                    builder: (c, _) => SingleChildScrollView(
                      key: ValueKey(index),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      child: IgnorePointer(ignoring: index != 1, child: page()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: CirculaNavigation(
            selectedIndex: index,
            guidedNextIndex: index < names.length - 1 ? index + 1 : null,
            destinations: names
                .map((n) => (t(n), Icons.circle_outlined, Icons.circle))
                .toList(),
            onSelected: select,
          ),
        ),
      ),
    );
  }
}
