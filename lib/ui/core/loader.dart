import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/services/ecourse_maintenance.dart';
import '../../data/services/moodle_client.dart';

import 'maintenance_capsule.dart';
import 'shapes.dart';
import 'status_capsule.dart';
import 'theme.dart';
import '../../l10n/l10n.dart';

/// Loads data and renders [builder]; handles loading, error with retry and
/// pull-to-refresh so every screen behaves the same way.
///
/// [Loader.watch] takes a stream instead, such as
/// [EcourseRepository.watch]'s saved result followed by the fresh one: the
/// screen shows the first value at once and updates when the next arrives.
/// If refreshing fails after something is shown, it stays and a snack bar
/// says so.
class Loader<T> extends StatefulWidget {
  Loader({
    super.key,
    required Future<T> Function() load,
    required this.builder,
    this.bar,
  }) : watch = (() => Stream.fromFuture(load()));

  const Loader.watch({
    super.key,
    required this.watch,
    required this.builder,
    this.bar,
  });

  final Stream<T> Function() watch;
  final Widget Function(BuildContext context, T data) builder;

  /// For a route that is a bare Loader: the app bar to show while loading,
  /// so the back button and title arrive with the route, not after it.
  final PreferredSizeWidget Function(BuildContext context)? bar;

  @override
  State<Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<Loader<T>> {
  StreamSubscription<T>? _sub;
  T? _data;
  var _hasData = false;
  Object? _error;

  /// Refreshing failed for eCourse2 maintenance; the saved data stays.
  var _maintenance = false;

  /// eCourse2 just came back and the page is loading afresh.
  var _back = false;
  Timer? _backTimer;

  /// Asking eCourse2 while something is already shown.
  var _loading = false;

  bool get _capsule => _maintenance || _back || _hasData && _loading;

  @override
  void initState() {
    super.initState();
    EcourseMaintenance.instance.addListener(_maintenanceChanged);
    _start();
  }

  @override
  void dispose() {
    EcourseMaintenance.instance.removeListener(_maintenanceChanged);
    _backTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  /// Loads again once eCourse2's maintenance is over.
  void _maintenanceChanged() {
    final error = _error;
    final waiting =
        _maintenance || error is MoodleException && error.isMaintenance;
    if (!mounted || !waiting || EcourseMaintenance.instance.active) return;
    if (!_hasData) return _retry();
    setState(() {
      _maintenance = false;
      _back = true;
    });
    _backTimer?.cancel();
    _backTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _back = false);
    });
    _start();
  }

  Future<void> _start() {
    _sub?.cancel();
    final done = Completer<void>();
    if (mounted) setState(() => _loading = true);
    void finish() {
      if (mounted) setState(() => _loading = false);
      if (!done.isCompleted) done.complete();
    }

    _sub = widget.watch().listen(
      (value) => setState(() {
        _data = value;
        _hasData = true;
        _error = null;
      }),
      onError: (Object e) {
        if (!mounted) return;
        final maintenance = e is MoodleException && e.isMaintenance;
        if (maintenance) EcourseMaintenance.instance.report();
        if (_hasData && maintenance) {
          // The capsule says so and stays until it is over.
          setState(() => _maintenance = true);
        } else if (_hasData) {
          // The saved data stays on screen; only the reason is new.
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(_reason(e) ?? context.l10n.loadFailed)),
          );
        } else {
          setState(() => _error = e);
        }
        finish();
      },
      onDone: finish,
      cancelOnError: true,
    );
    return done.future;
  }

  /// A known cause in the user's words; null shows the raw error.
  String? _reason(Object e) => switch (e) {
    MoodleException(isMaintenance: true) => context.l10n.ecourseMaintenance,
    MoodleException(needsSignIn: true) => context.l10n.ecourseSignedOut,
    _ => null,
  };

  void _retry() {
    setState(() => _error = null);
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    // Some routes are a bare Loader until their data arrives; an opaque
    // surface keeps the previous page from showing through the incoming
    // route's transition.
    if (!_hasData) {
      final bar = widget.bar;
      final body = error == null
          ? const LoadingView()
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _reason(error) ?? context.l10n.loadFailed,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_reason(error) == null) ...[
                      const SizedBox(height: 4),
                      Text('$error', textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: _retry,
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ),
              ),
            );
      return bar == null
          ? Material(color: Theme.of(context).colorScheme.surface, child: body)
          : Scaffold(
              extendBodyBehindAppBar: true,
              appBar: bar(context),
              body: body,
            );
    }
    // A Loader inside another shows no capsule of its own over the outer
    // one's.
    final outer = context.findAncestorStateOfType<_LoaderState>();
    final capsule = _capsule && !(outer?._capsule ?? false);
    return Stack(
      children: [
        RefreshIndicator(
          // Bodies extend under the glass app bar; start the spinner below it.
          edgeOffset: MediaQuery.paddingOf(context).top,
          // The capsule shows the progress, as on the campus pages.
          onRefresh: () async => unawaited(_start()),
          child: widget.builder(context, _data as T),
        ),
        CapsuleSlot(
          capsule: !capsule
              ? null
              : _maintenance || _back
              ? MaintenanceCapsule(back: _back)
              : StatusCapsule(
                  leading: MorphingCookie(
                    size: 26,
                    color: context.tones.lilac.strong,
                  ),
                  text: context.l10n.campusReading,
                ),
        ),
      ],
    );
  }
}

/// A page loading (design S2-C): the morphing shape in the middle and what
/// is happening in large type near the thumb. With [steps], also the step
/// count and a bar of parts; only for loads that really go in steps.
class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.title,
    this.detail,
    this.step = 0,
    this.steps,
    this.action,
  });

  /// Defaults to 讀取資料.
  final String? title;
  final String? detail;

  /// Zero-based, out of [steps].
  final int step;
  final int? steps;

  /// A button under the bar, e.g. to show a page that needs the user.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final steps = this.steps;
    final title = this.title ?? context.l10n.campusReading;
    return ColoredBox(
      color: scheme.surface,
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0, -0.25),
            child: MorphingCookie(size: 170, color: tones.lilac.fill),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.paddingOf(context).bottom + 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (steps != null) ...[
                  Text(
                    '${step + 1} / $steps',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.bottomLeft,
                    children: [...previous, ?current],
                  ),
                  child: Text(
                    title,
                    key: ValueKey(title),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (detail case final d? when d.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    d,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (steps != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      for (var i = 0; i < steps; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: i < step
                                  ? tones.mint.strong
                                  : i == step
                                  ? tones.lilac.strong
                                  : scheme.surfaceContainerHigh,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (action case final a?) ...[const SizedBox(height: 18), a],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered single-line state for empty lists.
class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: CookieBadge(
            value: '0',
            color: tones.lilac.fill,
            ink: tones.lilac.ink,
            size: 88,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}
