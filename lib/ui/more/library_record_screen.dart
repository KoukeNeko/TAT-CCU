import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/services/primo_client.dart';
import '../../l10n/l10n.dart';
import '../core/campus_web_screen.dart';
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
        builder: (context) => ListView(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: Text(online ? l10n.readOnline : l10n.requestHold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(text: '${record.title}\n${record.url}'),
                    ),
                    child: Text(l10n.share),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _citation));
                      if (!context.mounted) return;
                      // Copying leaves nothing on screen to show it worked.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.citationCopied)),
                      );
                    },
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
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Text(
                            value,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.w800),
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
