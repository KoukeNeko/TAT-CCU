import 'dart:async';

import 'package:flutter/material.dart';

import 'shapes.dart';
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

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start() {
    _sub?.cancel();
    final done = Completer<void>();
    void finish() {
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
        if (_hasData) {
          ScaffoldMessenger.maybeOf(context)
              ?.showSnackBar(SnackBar(content: Text(context.l10n.loadFailed)));
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
                      context.l10n.loadFailed,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('$error', textAlign: TextAlign.center),
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
    return RefreshIndicator(
      // Bodies extend under the glass app bar; start the spinner below it.
      edgeOffset: MediaQuery.paddingOf(context).top,
      onRefresh: _start,
      child: widget.builder(context, _data as T),
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
