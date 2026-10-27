import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/campus_cache.dart';
import '../../data/repositories/ecourse_auth_repository.dart';
import '../../data/services/ecourse_maintenance.dart';
import '../../data/services/folder_stats.dart';
import '../../data/services/response_cache.dart';
import '../../l10n/l10n.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'academic_screen.dart';
import 'events_screen.dart';
import 'leave_screen.dart';
import 'library_screen.dart';
import 'payment_screen.dart';

/// Design round-11/saved-data-detail.html: what each cache holds, by
/// eCourse2 feature and by campus page, with the eCourse2 account's state.
class SavedDataScreen extends StatefulWidget {
  const SavedDataScreen({super.key});

  @override
  State<SavedDataScreen> createState() => _SavedDataScreenState();
}

/// eCourse2 features by the prefix of the functions their screens call.
const _groups = <(String, IconData, String Function(AppLocalizations))>[
  ('core_enrol_', Icons.school_outlined, _courses),
  ('core_course_get_courses_by_field', Icons.school_outlined, _courses),
  ('core_webservice_', Icons.school_outlined, _courses),
  ('core_course_get_contents', Icons.folder_outlined, _contents),
  ('mod_assign_', Icons.assignment_outlined, _work),
  ('mod_quiz_', Icons.assignment_outlined, _work),
  ('gradereport_', Icons.bar_chart, _grades),
  ('mod_forum_', Icons.forum_outlined, _forums),
  ('local_mail_', Icons.notifications_none, _messages),
  ('message_', Icons.notifications_none, _messages),
  ('core_calendar_', Icons.event_outlined, _calendar),
];
String _courses(AppLocalizations l) => l.savedCourses;
String _contents(AppLocalizations l) => l.savedContents;
String _work(AppLocalizations l) => l.savedWork;
String _grades(AppLocalizations l) => l.grades;
String _forums(AppLocalizations l) => l.savedForums;
String _messages(AppLocalizations l) => l.savedMessages;
String _calendar(AppLocalizations l) => l.savedCalendar;
String _other(AppLocalizations l) => l.savedOther;

class _SavedDataScreenState extends State<SavedDataScreen> {
  final _files = (ResponseCache.files(), CampusCache.files()).wait;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final auth = context.watch<EcourseAuthRepository>();
    final maintenance = EcourseMaintenance.instance.active;
    final campusPages = [
      (LibraryScreen.cacheKey, Icons.menu_book_outlined, l10n.library),
      (PaymentScreen.cacheKey, Icons.payments_outlined, l10n.payTitle),
      (AcademicScreen.cacheKey, Icons.badge_outlined, l10n.academicSystem),
      (LeaveScreen.cacheKey, Icons.event_busy_outlined, l10n.leave),
      (EventsScreen.cacheKey, Icons.star_outline, l10n.events),
    ];
    final (accountTone, accountLabel) = switch (auth) {
      _ when maintenance => (tones.sun, l10n.maintenance),
      EcourseAuthRepository(signInExpired: true) => (
        tones.sun,
        l10n.signInExpired,
      ),
      EcourseAuthRepository(isSignedIn: true) => (tones.mint, l10n.signedIn),
      _ => (tones.peach, l10n.signedOut),
    };
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, l10n.savedData),
      body: Builder(
        builder: (context) => FutureBuilder(
          future: _files,
          builder: (context, snapshot) {
            final (ecourse, campus) =
                snapshot.data ?? (<SavedFile>[], <SavedFile>[]);
            // eCourse2 answers by feature, in the order of [_groups].
            final byGroup =
                <String Function(AppLocalizations), List<SavedFile>>{};
            final icons = <String Function(AppLocalizations), IconData>{};
            for (final (_, icon, name) in _groups) {
              byGroup[name] = [];
              icons[name] = icon;
            }
            for (final f in ecourse) {
              final function = ResponseCache.functionOf(f.name) ?? '';
              final group = _groups
                  .where((g) => function.startsWith(g.$1))
                  .firstOrNull;
              (byGroup[group?.$3 ?? _other] ??= []).add(f);
              icons[_other] = Icons.inventory_2_outlined;
            }
            final ecourseTotal = summarize(ecourse).bytes;
            final campusTotal = summarize(campus).bytes;
            final ecourseRows = [
              for (final MapEntry(key: name, value: files) in byGroup.entries)
                if (name != _other || files.isNotEmpty)
                  (icons[name]!, name(l10n), summarize(files), true),
            ];
            final campusRows = [
              for (final (key, icon, title) in campusPages)
                (
                  icon,
                  title,
                  summarize(campus.where((f) => f.name == key)),
                  false,
                ),
            ];
            if (desktopUi(context)) {
              // design/round-25 saved: the total, then each source's rows
              // side by side.
              return ListView(
                padding: scrollPadding(context),
                children: [
                  Text(
                    l10n.savedData,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Total(ecourse: ecourseTotal, campus: campusTotal),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SectionLabel(
                              'eCourse2',
                              action: auth.isDemo
                                  ? null
                                  : DeskTag(
                                      accountLabel,
                                      color: accountTone.strong,
                                    ),
                            ),
                            _Rows(ecourseRows),
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SectionLabel(l10n.campusSystems),
                            _Rows(campusRows),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return ListView(
              padding: scrollPadding(context),
              children: [
                _Total(ecourse: ecourseTotal, campus: campusTotal),
                SectionLabel(
                  'eCourse2',
                  action: auth.isDemo
                      ? null
                      : StatusPill(tone: accountTone, label: accountLabel),
                ),
                _Rows(ecourseRows),
                SectionLabel(l10n.campusSystems),
                _Rows(campusRows),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The total on the device, split between eCourse2 and the campus pages.
class _Total extends StatelessWidget {
  const _Total({required this.ecourse, required this.campus});

  final int ecourse, campus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final tone = tones.lilac;
    final [value, unit] = fileSize(ecourse + campus).split(' ');
    if (desktopUi(context)) {
      final scheme = Theme.of(context).colorScheme;
      final muted = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: scheme.onSurfaceVariant,
      );
      final parts = [
        (ecourse, tone.strong, 'eCourse2 ${fileSize(ecourse)}'),
        (campus, tones.sun.strong, '${l10n.campusSystems} ${fileSize(campus)}'),
      ];
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.onThisDevice, style: muted),
            const SizedBox(height: Space.xs),
            Text(
              '$value $unit',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            if (ecourse + campus > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: Space.s),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 2,
                      children: [
                        for (final (bytes, color, _) in parts)
                          if (bytes > 0)
                            Expanded(
                              flex: bytes,
                              child: ColoredBox(color: color),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            Wrap(
              spacing: 16,
              children: [
                for (final (_, color, text) in parts)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const SizedBox.square(dimension: 8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        text,
                        style: muted.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );
    }
    final muted = TextStyle(
      color: tone.ink.withValues(alpha: 0.85),
      fontSize: 12,
      fontWeight: FontWeight.w800,
    );
    Widget key(Color color, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: 8),
        ),
        const SizedBox(width: 6),
        Text(text, style: muted),
      ],
    );
    return ToneBlock(
      tone: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onThisDevice, style: muted.copyWith(fontSize: 13)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 18,
                    color: tone.ink.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            style: TextStyle(
              color: tone.ink,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 10,
            child: Row(
              // The segments are empty boxes: stretch them to the bar.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, (bytes, color)) in [
                  (ecourse, tone.strong),
                  (campus, tones.mint.strong),
                ].indexed)
                  if (bytes > 0) ...[
                    if (i > 0 && ecourse > 0) const SizedBox(width: 3),
                    Expanded(
                      flex: bytes,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              key(tone.strong, 'eCourse2 ${fileSize(ecourse)}'),
              key(
                tones.mint.strong,
                '${l10n.campusSystems} ${fileSize(campus)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One card of rows: icon, name, count and time, size.
class _Rows extends StatelessWidget {
  const _Rows(this.rows);

  /// [counted] rows say how many items; campus rows are one page each.
  final List<(IconData, String, FolderStats, bool)> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    if (desktopUi(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (_, title, stats, counted) in rows)
            DeskLine(
              title: title,
              detail: switch (stats.latest) {
                final latest? => [
                  if (counted) l10n.savedItems(stats.files),
                  l10n.updatedAt(monthDayTime(latest)),
                ].join('・'),
                null => l10n.noData,
              },
              value: stats.files == 0 ? '—' : fileSize(stats.bytes),
              valueColor: stats.files == 0 ? scheme.onSurfaceVariant : null,
            ),
        ],
      );
    }
    return Card(
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, (icon, title, stats, counted)) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
            ListTile(
              leading: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Corners.small),
                ),
                child: SizedBox.square(
                  dimension: 36,
                  child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                ),
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: stats.files == 0 ? scheme.onSurfaceVariant : null,
                ),
              ),
              subtitle: Text(switch (stats.latest) {
                final latest? => [
                  if (counted) l10n.savedItems(stats.files),
                  l10n.updatedAt(monthDayTime(latest)),
                ].join('・'),
                null => l10n.noData,
              }),
              trailing: Text(
                stats.files == 0 ? '—' : fileSize(stats.bytes),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: stats.files == 0 ? scheme.onSurfaceVariant : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
