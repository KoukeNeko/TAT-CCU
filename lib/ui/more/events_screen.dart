import 'dart:ui' show ImageFilter;

import 'package:clock/clock.dart' as clk;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../data/services/demo_data.dart';
import '../../data/repositories/campus_cache.dart';
import '../../l10n/l10n.dart';
import '../core/auto_refresh.dart';
import '../core/campus_session.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../data/services/events_data.dart';

/// What [EventsScreen] read: every current event, the site's categories and
/// the student's sign-ups, for the list and for 我的活動.
typedef EventsData = ({
  List<SchoolEvent> events,
  Map<String, Set<String>> categories,
  List<({String id, String title})> mine,
  List<({String id, String title})> past,
  int attended,
  String hours,
});

EventsData _dataOf(Map<String, dynamic> json) {
  List<({String id, String title})> rows(Object? v) => [
    for (final r in (v as List? ?? const []).whereType<Map>())
      (id: '${r['id']}', title: '${r['title'] ?? ''}'),
  ];
  final mine = rows(json['mine']);
  final mineIds = {for (final r in mine) r.id};
  return (
    events: [
      for (final e in (json['events'] as List? ?? const []))
        eventOf({
          ...(e as Map).cast<String, dynamic>(),
          if (mineIds.contains('${e['id']}')) 'signedUp': true,
        }),
    ]..sort(_byStart),
    categories: {
      for (final MapEntry(:key, :value)
          in (json['categories'] as Map? ?? const {}).entries)
        '$key': {for (final id in value as List) '$id'},
    },
    mine: mine,
    past: rows(json['past']),
    attended: (json['attended'] as num?)?.toInt() ?? 0,
    hours: '${json['hours'] ?? 0}',
  );
}

int _byStart(SchoolEvent a, SchoolEvent b) =>
    (a.start ?? DateTime(9999)).compareTo(b.start ?? DateTime(9999));

enum _Time { days3, week, month, any }

enum _Status { open, ongoing, closed, any }

/// Design M1 with search and posters (design/round-11/events-full.html):
/// the next event the student signed up for on top, then events by date
/// with their posters, filtered by time, status and category.
class EventsScreen extends StatefulWidget {
  static const cacheKey = 'events';

  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with AutoRefresh {
  final _session = GlobalKey<CampusSessionState>();
  final _http = http.Client();
  final _field = TextEditingController();
  final _keys = {
    for (final k in ['time', 'status', 'category']) k: GlobalKey(),
  };

  /// The public pages and 我的活動 together, as cached.
  var _json = <String, dynamic>{};

  /// Also read by 我的活動, which shows a sign-up or cancel made from it.
  final _shown = ValueNotifier<EventsData?>(null);
  EventsData? get _data => _shown.value;
  set _data(EventsData? data) => _shown.value = data;
  DateTime? _savedAt;
  String? _error;
  var _time = _Time.week;
  var _status = _Status.open;
  String? _category;

  /// The submitted search, and the site's results for it.
  String? _query;
  List<SchoolEvent>? _results;

  @override
  void initState() {
    super.initState();
    // Places change by the hour: show the last read at once and read again.
    CampusCache.read(EventsScreen.cacheKey).then((cached) {
      if (!mounted) return;
      if (cached != null) {
        _json = cached.json;
        setState(() {
          _data = _dataOf(_json);
          _savedAt = cached.savedAt;
        });
      }
      _loadPublic();
    });
  }

  @override
  void dispose() {
    _http.close();
    _field.dispose();
    _shown.dispose();
    super.dispose();
  }

  Future<void> _merge(Map<String, dynamic> json) async {
    _json = {..._json, ...json};
    if (_json['events'] == null) return;
    final savedAt = await CampusCache.write(EventsScreen.cacheKey, _json);
    if (!mounted) return;
    setState(() {
      _error = null;
      _data = _dataOf(_json);
      _savedAt = savedAt;
    });
  }

  Future<void> _loadPublic() async {
    try {
      await _merge(await fetchEvents(_http));
    } on Exception catch (e) {
      // Cached events stay; only an empty page shows the error.
      if (mounted && _data == null) setState(() => _error = '$e');
    }
  }

  /// 我的活動 from the signed-in WebView.
  void _received(Map<String, dynamic> json) {
    if (json['error'] != null) {
      if (_data == null) setState(() => _error = '${json['error']}');
      return;
    }
    _merge(json);
  }

  Future<void> _search(String text) async {
    final query = text.trim();
    setState(() {
      _query = query.isEmpty ? null : query;
      _results = null;
    });
    if (query.isEmpty) return;
    try {
      final found = await searchEvents(_http, query);
      if (!mounted || _query != query) return;
      setState(() => _results = _dataOf({..._json, 'events': found}).events);
    } on Exception catch (e) {
      // The list stays; the search can be sent again from the field.
      if (!mounted) return;
      setState(() => _query = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _refresh() async {
    _session.currentState?.refresh();
    await _loadPublic();
  }

  void _clearSearch() {
    _field.clear();
    setState(() {
      _query = null;
      _results = null;
    });
  }

  // Seats and sign-ups move; reading the school is costly, so only on
  // coming back, at most every few minutes.
  @override
  Duration? get refreshEvery => null;

  @override
  Duration get staleAfter => const Duration(minutes: 5);

  @override
  void refresh() => _reload();

  Future<void> _reload() async {
    setState(() => _error = null);
    await Future.wait([_loadPublic(), ?_session.currentState?.reload()]);
  }

  Future<T?> _pick<T>(String key, List<(T, String, int?)> options, T current) {
    final box = _keys[key]!.currentContext!.findRenderObject()! as RenderBox;
    return showGlassMenu<T>(
      context,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      selected: current,
      items: [
        for (final (value, label, count) in options)
          (
            value: value,
            title: label,
            detail: count == null ? null : '$count',
            icon: null,
            tone: null,
          ),
      ],
    );
  }

  bool _inTime(SchoolEvent e, _Time time, DateTime now) {
    final days = switch (time) {
      _Time.days3 => 3,
      _Time.week => 7,
      _Time.month => 30,
      _Time.any => null,
    };
    if (days == null) return true;
    final start = e.start ?? now;
    final end = e.end ?? start;
    return !end.isBefore(now) && start.isBefore(now.add(Duration(days: days)));
  }

  bool _inStatus(SchoolEvent e, _Status status, DateTime now) =>
      switch (status) {
        _Status.open => switch (statusOf(e, now)) {
          EventStatus.open || EventStatus.waitlist || EventStatus.mine => true,
          _ => false,
        },
        _Status.ongoing =>
          e.start != null &&
              !e.start!.isAfter(now) &&
              !(e.end ?? e.start!).isBefore(now),
        _Status.closed => statusOf(e, now) == EventStatus.closed,
        _Status.any => true,
      };

  List<SchoolEvent> _filtered(
    List<SchoolEvent> events,
    DateTime now, {
    _Time? time,
    _Status? status,
    String? category,
  }) {
    final ids = (category ?? _category) != null
        ? _data?.categories[category ?? _category] ?? const <String>{}
        : null;
    return [
      for (final e in events)
        if (_inTime(e, time ?? _time, now) &&
            _inStatus(e, status ?? _status, now) &&
            (ids == null || ids.contains(e.id)))
          e,
    ];
  }

  void _open(SchoolEvent e) => context.push(
    '/more/events/detail',
    extra: (event: e, onChanged: _refresh),
  );

  PreferredSizeWidget _bar(BuildContext context) {
    final l10n = context.l10n;
    final now = clk.clock.now();
    final events = _results ?? _data?.events ?? const <SchoolEvent>[];
    String timeLabel(_Time t) => switch (t) {
      _Time.days3 => l10n.within3Days,
      _Time.week => l10n.withinWeek,
      _Time.month => l10n.withinMonth,
      _Time.any => l10n.allTime,
    };
    String statusLabel(_Status s) => switch (s) {
      _Status.open => l10n.eventsOpen,
      _Status.ongoing => l10n.eventsOngoing,
      _Status.closed => l10n.eventsClosed,
      _Status.any => l10n.anyStatus,
    };
    return PreferredSize(
      preferredSize: const Size.fromHeight(108),
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.m),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: pageMargin),
              child: TextField(
                controller: _field,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                decoration: InputDecoration(
                  hintText: l10n.searchEvents,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query == null
                      ? null
                      : IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .deleteButtonTooltip,
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ChipRow(
              children: [
                BarChip(
                  key: _keys['time'],
                  label: timeLabel(_time),
                  selected: _time != _Time.any,
                  dropdown: true,
                  onTap: () async {
                    final t = await _pick('time', [
                      for (final t in _Time.values)
                        (
                          t,
                          timeLabel(t),
                          _filtered(events, now, time: t).length,
                        ),
                    ], _time);
                    if (t != null) setState(() => _time = t);
                  },
                ),
                BarChip(
                  key: _keys['status'],
                  label: statusLabel(_status),
                  selected: _status != _Status.any,
                  dropdown: true,
                  onTap: () async {
                    final s = await _pick('status', [
                      for (final s in _Status.values)
                        (
                          s,
                          statusLabel(s),
                          _filtered(events, now, status: s).length,
                        ),
                    ], _status);
                    if (s != null) setState(() => _status = s);
                  },
                ),
                BarChip(
                  key: _keys['category'],
                  label: _category ?? l10n.eventCategory,
                  selected: _category != null,
                  dropdown: true,
                  onTap: () async {
                    // The empty string stands for every category in the menu.
                    final c = await _pick('category', [
                      ('', l10n.anyCategory, null),
                      for (final name in _data?.categories.keys ?? <String>[])
                        (
                          name,
                          name,
                          _filtered(events, now, category: name).length,
                        ),
                    ], _category ?? '');
                    if (c != null) {
                      setState(() => _category = c.isEmpty ? null : c);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return CampusSession(
      key: _session,
      title: context.l10n.events,
      entry: eventsEntry(),
      host: eventsHost,
      // Search and filters only once there is something to search.
      bottom: data == null ? null : _bar(context),
      action: data == null
          ? null
          : _MyEventsChip(
              // No count until 我的活動 has been read.
              count: _json['mine'] == null ? null : data.mine.length,
              onTap: () => context.push(
                '/more/events/mine',
                extra: (data: _shown, onChanged: _refresh),
              ),
            ),
      script: () => readMine,
      demo: DemoCampus.myEvents,
      onMessage: _received,
      child: _error != null
          ? CampusError(message: _error!, onRetry: _reload)
          : data == null || (_query != null && _results == null)
          ? const LoadingView()
          : Builder(
              // Reads insets from inside the session's Scaffold.
              builder: (context) =>
                  PullRefresh(onRefresh: _refresh, child: _body(context, data)),
            ),
    );
  }

  Widget _body(BuildContext context, EventsData data) {
    final now = clk.clock.now();
    final searching = _query != null;
    final shown = _filtered(_results ?? data.events, now);
    final groups = <DateTime, List<SchoolEvent>>{};
    for (final e in shown) {
      final s = e.start ?? now;
      (groups[DateTime(s.year, s.month, s.day)] ??= []).add(e);
    }
    return ListView(
      padding: scrollPadding(context),
      children: [
        if (shown.isEmpty)
          _NoMatch(
            onWiden: _time == _Time.any && _status == _Status.any
                ? null
                : () => setState(() {
                    _time = _Time.any;
                    _status = _Status.any;
                  }),
          ),
        for (final MapEntry(key: day, value: events) in groups.entries) ...[
          SectionLabel(
            '${day.month}/${day.day} ${weekdayName(context, day.weekday)}',
          ),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, e) in events.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  EventRow(event: e, query: _query, onTap: () => _open(e)),
                ],
              ],
            ),
          ),
        ],
        if (!searching && _savedAt != null) UpdatedAt(_savedAt!),
      ],
    );
  }
}

/// Days from today to [start]'s date: 0 for today.
int daysUntil(DateTime start, DateTime now) => DateTime(
  start.year,
  start.month,
  start.day,
).difference(DateTime(now.year, now.month, now.day)).inDays;

/// The pill on a row and in a detail: places, waitlist or how to sign up.
(Tone, String) eventPill(BuildContext context, SchoolEvent e, DateTime now) {
  final l10n = context.l10n;
  final tones = context.tones;
  final scheme = Theme.of(context).colorScheme;
  final neutral = Tone(
    scheme.surfaceContainerHigh,
    scheme.onSurfaceVariant,
    scheme.onSurfaceVariant,
  );
  return switch (statusOf(e, now)) {
    EventStatus.open => (
      tones.mint,
      e.spots == null ? l10n.eventsOpen : '${e.spots!.taken}/${e.spots!.total}',
    ),
    EventStatus.waitlist => (
      tones.sun,
      e.waitlist == null
          ? l10n.eventFull
          : l10n.waitlistSpots(e.waitlist!.taken, e.waitlist!.total),
    ),
    EventStatus.full => (neutral, l10n.eventFull),
    EventStatus.mine => (tones.lilac, l10n.signedUp),
    EventStatus.external => (tones.peach, l10n.externalSignUp),
    EventStatus.closed => (neutral, l10n.signUpClosed),
  };
}

/// The event's poster, whole; the same picture blurred fills the space a
/// poster of another shape leaves.
class EventPoster extends StatelessWidget {
  const EventPoster({
    super.key,
    required this.url,
    this.padding,
    this.fadeOut = false,
  });

  final String url;

  /// Keeps the poster itself clear of bars drawn over it.
  final EdgeInsets? padding;

  /// Fades the backdrop into the page at the bottom.
  final bool fadeOut;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final width =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    return Stack(
      fit: StackFit.expand,
      children: [
        // Clipped: a blur spills past its box, leaving an edge below it.
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              cacheWidth: width ~/ 4,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            // Some posters are 4535 px wide; decode only what the screen
            // shows.
            cacheWidth: width,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        if (fadeOut)
          // Below the poster: clear at its edge, the page colour at the
          // bottom, so the backdrop ends without a line.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: padding?.bottom ?? 0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [surface.withValues(alpha: 0), surface],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A poster cropped to a small landscape tile; the status tone with the
/// title's first character when there is none.
class EventThumb extends StatelessWidget {
  const EventThumb({
    super.key,
    required this.event,
    this.width = 96,
    this.height = 56,
  });

  final SchoolEvent event;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final (tone, _) = eventPill(context, event, clk.clock.now());
    final initial = event.title.replaceAll(RegExp(r'[【〔（(].*?[】〕）)]'), '');
    final fallback = Container(
      color: tone.fill,
      alignment: Alignment.center,
      child: Text(
        initial.isEmpty ? '' : initial.characters.first,
        style: TextStyle(
          color: tone.ink,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: width,
        height: height,
        child: event.image == null
            ? fallback
            : Image.network(
                event.image!,
                fit: BoxFit.cover,
                cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class EventRow extends StatelessWidget {
  const EventRow({
    super.key,
    required this.event,
    required this.onTap,
    this.query,
  });

  final SchoolEvent event;
  final String? query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = context.tones;
    final (tone, label) = eventPill(context, event, clk.clock.now());
    final start = event.start;
    final end = event.end;
    final time = start == null
        ? ''
        : '${clock(start.hour * 60 + start.minute)}'
              '${end == null ? '' : '–${clock(end.hour * 60 + end.minute)}'}';
    const titleStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w900);
    final at = query == null ? -1 : event.title.indexOf(query!);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.m, Space.m, Space.m, Space.m),
        child: Row(
          children: [
            EventThumb(event: event),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    at < 0
                        ? TextSpan(text: event.title)
                        : TextSpan(
                            children: [
                              TextSpan(text: event.title.substring(0, at)),
                              TextSpan(
                                text: query,
                                style: TextStyle(
                                  backgroundColor: tones.sun.fill,
                                  color: tones.sun.ink,
                                ),
                              ),
                              TextSpan(
                                text: event.title.substring(at + query!.length),
                              ),
                            ],
                          ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [time, event.place].where((s) => s.isNotEmpty).join('・'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusPill(tone: tone, label: label),
          ],
        ),
      ),
    );
  }
}

/// The next event signed up for: its poster with the days left, then the
/// title, time and place.
class _NextCard extends StatelessWidget {
  const _NextCard({required this.event, required this.onTap});

  final SchoolEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = context.tones.lilac;
    final light = Theme.of(context).brightness == Brightness.light;
    final start = event.start;
    final days = start == null ? null : daysUntil(start, clk.clock.now());
    final chip = Colors.white.withValues(alpha: light ? 0.55 : 0.12);
    return ToneBlock(
      tone: tone,
      radius: Corners.card,
      padding: const EdgeInsets.fromLTRB(Space.s, Space.s, Space.s, Space.l),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Corners.row),
            child: SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (event.image case final url?)
                    EventPoster(url: url)
                  else
                    ColoredBox(color: tone.strong.withValues(alpha: 0.25)),
                  if (days != null)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tone.strong,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.m,
                            vertical: Space.s,
                          ),
                          child: Text(
                            days <= 0 ? l10n.today : l10n.inDays(days),
                            style: TextStyle(
                              color: tone.fill,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.m, Space.m, Space.m, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.nextSignedUp,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final s in [
                      if (start != null) dateTimeLabel(context, start),
                      if (event.place.isNotEmpty) event.place,
                    ])
                      DecoratedBox(
                        decoration: ShapeDecoration(
                          color: chip,
                          shape: const StadiumBorder(),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.m,
                            vertical: Space.s,
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The app bar's way to 我的活動, styled like the timetable's semester menu.
class _MyEventsChip extends StatelessWidget {
  const _MyEventsChip({required this.count, required this.onTap});

  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.lilac;
    return Material(
      color: tone.fill,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(left: Space.l, right: Space.s),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                [context.l10n.myEvents, ?count?.toString()].join(' '),
                style: TextStyle(
                  color: tone.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Icon(Icons.chevron_right, color: tone.ink, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.onWiden});

  /// Drops the time and status filters; null when there are none.
  final VoidCallback? onWiden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.search,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.noMatchingEvents,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          if (onWiden != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onWiden,
              child: Text(l10n.searchAnyTimeStatus),
            ),
          ],
        ],
      ),
    );
  }
}

/// 我的活動: counts, the events signed up for, then past ones.
class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key, required this.data, this.onChanged});

  /// The events page's data, read again after a sign-up or cancel.
  final ValueListenable<EventsData?> data;

  /// Called after a sign-up or cancel in a detail opened from here.
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: data,
    builder: (context, data, _) =>
        data == null ? const SizedBox.shrink() : _build(context, data),
  );

  Widget _build(BuildContext context, EventsData data) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final byId = {for (final e in data.events) e.id: e};
    final now = clk.clock.now();
    final next = data.events
        .where((e) => e.signedUp && !(e.end ?? e.start ?? now).isBefore(now))
        .firstOrNull;
    Widget group(List<({String id, String title})> rows) => Card(
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (rows.isEmpty)
            ListTile(
              title: Text(
                l10n.noEventRecords,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) const Divider(height: 1),
            if (byId[r.id] case final e?)
              EventRow(
                event: e,
                onTap: () => context.push(
                  '/more/events/detail',
                  extra: (event: e, onChanged: onChanged),
                ),
              )
            else
              ListTile(
                title: Text(
                  r.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ],
      ),
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, l10n.myEvents),
      body: Builder(
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: [
            if (next != null) ...[
              _NextCard(
                event: next,
                onTap: () => context.push(
                  '/more/events/detail',
                  extra: (event: next, onChanged: onChanged),
                ),
              ),
              const SizedBox(height: rowGap),
            ],
            Row(
              children: [
                for (final (i, (tone, value, label)) in [
                  (tones.lilac, '${data.mine.length}', l10n.signedUp),
                  (
                    tones.mint,
                    '${data.attended}',
                    l10n.eventsAttended(data.hours),
                  ),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: rowGap),
                  Expanded(
                    child: ToneBlock(
                      tone: tone,
                      radius: Corners.row,
                      padding: cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SectionLabel(l10n.signedUp),
            group(data.mine),
            SectionLabel(l10n.pastEvents),
            group(data.past),
          ],
        ),
      ),
    );
  }
}
