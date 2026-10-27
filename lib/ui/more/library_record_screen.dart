import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/services/primo_client.dart';
import '../../l10n/l10n.dart';
import '../core/campus_web_screen.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'library_search_screen.dart';

/// One record (design: library overview, screen 6): copies with location
/// and call number, then request, share and cite. Requests are placed on
/// Primo's own page, in the shared campus WebView.
class LibraryRecordScreen extends StatelessWidget {
  const LibraryRecordScreen({
    super.key,
    required this.record,
    required this.index,
  });

  final LibraryRecord record;

  /// Position in the list it came from; keeps the cover's color.
  final int index;

  /// `Author (year). Title. Publisher.`, enough to paste into notes.
  String get _citation => [
    if (record.author.isNotEmpty)
      record.year.isEmpty ? record.author : '${record.author} (${record.year})',
    record.title,
    if (record.publisher.isNotEmpty) record.publisher,
  ].join('. ');

  void _share() => SharePlus.instance.share(
    ShareParams(text: '${record.title}\n${record.url}'),
  );

  Future<void> _cite(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _citation));
    if (!context.mounted) return;
    // Copying leaves nothing on screen to show it worked.
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.citationCopied)));
  }

  /// design/round-25 library-record: the cover beside the title and its
  /// actions, then the copies and the details as lines.
  Widget _desk(
    BuildContext context,
    Iterable<(String, String)> details,
    bool online,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    return ListView(
      padding: scrollPadding(context),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(title: record.title, index: index, width: 132),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (record.year.isNotEmpty)
                    Text(
                      record.year,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: muted,
                      ),
                    ),
                  const SizedBox(height: Space.s),
                  SelectableText(
                    record.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  if (record.author.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.author,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.l),
                  Wrap(
                    spacing: Space.s,
                    runSpacing: Space.s,
                    children: [
                      DeskButton(
                        icon: online
                            ? Icons.open_in_new
                            : Icons.menu_book_outlined,
                        label: online ? l10n.readOnline : l10n.requestHold,
                        primary: true,
                        onPressed: () =>
                            openCampusPage(context, record.url, record.title),
                      ),
                      DeskButton(
                        icon: Icons.ios_share,
                        label: l10n.share,
                        onPressed: _share,
                      ),
                      DeskButton(
                        icon: Icons.description_outlined,
                        label: l10n.cite,
                        onPressed: () => _cite(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (record.holdings.isNotEmpty) ...[
          SectionLabel(l10n.holdings),
          for (final h in record.holdings)
            DeskLine(
              leading: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.local_library_outlined,
                  size: 15,
                  color: muted,
                ),
              ),
              title: h.location,
              detail: h.callNumber.isEmpty ? null : h.callNumber,
              value: availabilityPill(context, h.status)?.$2,
              valueColor: availabilityPill(context, h.status)?.$1.strong,
            ),
        ],
        if (details.isNotEmpty) ...[
          SectionLabel(l10n.bibDetails),
          for (final (label, value) in details)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 106,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: muted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final online = record.availability == Availability.online;
    final details = [
      (l10n.publisher, record.publisher),
      ('ISBN', record.isbn),
      (l10n.subjects, record.subjects.take(3).join('、')),
    ].where((d) => d.$2.isNotEmpty);
    final muted = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, ''),
      body: Builder(
        builder: (context) => desktopUi(context)
            ? _desk(context, details, online)
            : ListView(
                padding: scrollPadding(context),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      BookCover(title: record.title, index: index, width: 110),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(record.year, style: muted),
                            const SizedBox(height: 4),
                            Text(
                              record.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                              ),
                            ),
                            if (record.author.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(record.author, style: muted),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (record.holdings.isNotEmpty) ...[
                    SectionLabel(l10n.holdings),
                    for (final h in record.holdings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.s),
                        child: Material(
                          color: scheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Corners.row),
                          ),
                          child: Padding(
                            padding: cardPadding,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        h.location,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      if (h.callNumber.isNotEmpty)
                                        Text(h.callNumber, style: muted),
                                    ],
                                  ),
                                ),
                                if (availabilityPill(context, h.status) case (
                                  final tone,
                                  final label,
                                ))
                                  StatusPill(tone: tone, label: label),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 52),
                          ),
                          onPressed: () =>
                              openCampusPage(context, record.url, record.title),
                          child: Text(
                            online ? l10n.readOnline : l10n.requestHold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 52),
                          ),
                          onPressed: _share,
                          child: Text(l10n.share),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 52),
                          ),
                          onPressed: () => _cite(context),
                          child: Text(l10n.cite),
                        ),
                      ),
                    ],
                  ),
                  if (details.isNotEmpty) ...[
                    SectionLabel(l10n.bibDetails),
                    Card(
                      color: scheme.surfaceContainerLow,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (final (label, value) in details)
                            ListTile(
                              title: Text(label, style: muted),
                              trailing: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 220,
                                ),
                                child: Text(
                                  value,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
