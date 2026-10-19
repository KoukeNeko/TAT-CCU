import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/primo_client.dart';
import '../../l10n/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'library_search_screen.dart';

/// The library's themed collections (design: library overview, screen 7).
class LibraryCollectionsScreen extends StatelessWidget {
  const LibraryCollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, context.l10n.collections),
      body: Builder(
        builder: (context) => Loader(
          load: PrimoClient().collections,
          builder: (context, collections) => GridView.count(
            padding: scrollPadding(context),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
            children: [
              for (final (i, c) in collections.indexed)
                ToneBlock(
                  tone: tones.cycle[i % tones.cycle.length],
                  radius: Corners.row,
                  padding: const EdgeInsets.all(14),
                  onTap: () => context.push('/more/library/collection/${c.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        c.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One collection's books (screen 8). Nested collections such as 新進圖書
/// (year → month) become chips of the parts that hold books.
class LibraryCollectionScreen extends StatelessWidget {
  const LibraryCollectionScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Loader(
      load: PrimoClient().collections,
      builder: (context, tree) {
        final collection = [for (final c in tree) ?c.find(id)].firstOrNull;
        return _Collection(
          title: collection?.name ?? '',
          parts: collection?.withItems ?? const [],
        );
      },
    );
  }
}

class _Collection extends StatefulWidget {
  const _Collection({required this.title, required this.parts});

  final String title;
  final List<LibraryCollection> parts;

  @override
  State<_Collection> createState() => _CollectionState();
}

class _CollectionState extends State<_Collection> {
  final _primo = PrimoClient();
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final parts = widget.parts;
    final chips = parts.length > 1;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        widget.title,
        bottom: chips
            ? ChipBar(
                children: [
                  for (final (i, p) in parts.indexed)
                    BarChip(
                      label: p.name,
                      selected: i == _selected,
                      onTap: () => setState(() => _selected = i),
                    ),
                ],
              )
            : null,
      ),
      body: parts.isEmpty
          ? EmptyState(context.l10n.noBooks)
          : Builder(
              builder: (context) => RecordList(
                key: ValueKey(parts[_selected].id),
                load: (offset) =>
                    _primo.collectionItems(parts[_selected].id, offset: offset),
              ),
            ),
    );
  }
}
