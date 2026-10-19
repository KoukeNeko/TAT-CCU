import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/primo_client.dart';
import '../../l10n/l10n.dart';
import '../core/campus_web_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// 圖書館資源探索 (design: library overview, screens 4–5): search across
/// the catalog, journals and databases; before searching, new books and
/// the themed collections. Public Primo API; no sign-in.
class LibrarySearchScreen extends StatefulWidget {
  const LibrarySearchScreen({super.key});

  @override
  State<LibrarySearchScreen> createState() => _LibrarySearchScreenState();
}

typedef _Filters = ({
  bool onShelf,
  PrimoType? type,
  PrimoSort sort,
  int? years,
});

class _LibrarySearchScreenState extends State<LibrarySearchScreen> {
  final _primo = PrimoClient();
  final _field = TextEditingController();
  var _query = '';
  var _kind = PrimoKind.catalog;
  _Filters _filters = (
    onShelf: false,
    type: null,
    sort: PrimoSort.rank,
    years: null,
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _editFilters() async {
    final picked = await showModalBottomSheet<_Filters>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(initial: _filters),
    );
    if (picked != null) setState(() => _filters = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final f = _filters;
    final catalog = _kind == PrimoKind.catalog;
    final searching = _query.isNotEmpty;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        l10n.libraryDiscovery,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            !searching
                ? 60
                : catalog
                ? 152
                : 104,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _field,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: l10n.librarySearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searching
                        ? IconButton(
                            tooltip: MaterialLocalizations.of(context)
                                .deleteButtonTooltip,
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _field.clear();
                              _query = '';
                            }),
                          )
                        : null,
                    filled: true,
                    fillColor: scheme.surfaceContainerHigh,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (searching) ...[
                  const SizedBox(height: 6),
                  _KindTabs(
                    kind: _kind,
                    onChanged: (k) => setState(() => _kind = k),
                  ),
                ],
                if (searching && catalog) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text(l10n.onShelf),
                          selected: f.onShelf,
                          onSelected: (on) => setState(
                            () => _filters = (
                              onShelf: on,
                              type: f.type,
                              sort: f.sort,
                              years: f.years,
                            ),
                          ),
                        ),
                        for (final label in [
                          f.type == null
                              ? l10n.filterType
                              : _typeLabel(context, f.type!),
                          _sortLabel(context, f.sort),
                          f.years == null
                              ? l10n.filterYear
                              : _yearsLabel(context, f.years),
                        ]) ...[
                          const SizedBox(width: 6),
                          ActionChip(
                            label: Text(label),
                            avatar: const Icon(Icons.expand_more, size: 18),
                            onPressed: _editFilters,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: !searching
          ? Builder(builder: (context) => _Browse(primo: _primo))
          : Builder(
              builder: (context) => RecordList(
                key: ValueKey((_query, _kind, _filters)),
                load: (offset) => _primo.search(
                  _query,
                  kind: _kind,
                  sort: f.sort,
                  onShelf: catalog && f.onShelf,
                  type: catalog ? f.type : null,
                  sinceYear: catalog && f.years != null
                      ? DateTime.now().year - f.years! + 1
                      : null,
                  offset: offset,
                ),
              ),
            ),
    );
  }
}

/// 館藏・期刊・資料庫 as underlined text tabs (design D1).
class _KindTabs extends StatelessWidget {
  const _KindTabs({required this.kind, required this.onChanged});

  final PrimoKind kind;
  final ValueChanged<PrimoKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final (k, label) in [
          (PrimoKind.catalog, l10n.kindCatalog),
          (PrimoKind.journal, l10n.kindJournal),
          (PrimoKind.database, l10n.kindDatabase),
        ])
          InkWell(
            onTap: () => onChanged(k),
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              margin: const EdgeInsets.only(right: 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 3,
                    color: k == kind
                        ? context.tones.lilac.strong
                        : Colors.transparent,
                  ),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: k == kind ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

typedef _Shelves = ({
  LibraryCollection? month,
  List<LibraryRecord> newBooks,
  LibraryCollection? hot,
  List<LibraryRecord> hotBooks,
  List<LibraryCollection> others,
  int collectionCount,
});

/// What to browse before searching: the newest month of 新進圖書, the
/// 誠品暢銷榜 shelf and the other themed collections.
Future<_Shelves> _loadShelves(PrimoClient primo) async {
  final tree = await primo.collections();
  final news = [for (final c in tree) ?c.find(newBooksId)].firstOrNull;
  final hot = tree.where((c) => c.name.contains('暢銷')).firstOrNull;
  final month = news?.withItems.firstOrNull;
  final hotPart = hot?.withItems.firstOrNull;
  final (newPage, hotPage) = await (
    month == null
        ? Future.value((total: 0, records: <LibraryRecord>[]))
        : primo.collectionItems(month.id),
    hotPart == null
        ? Future.value((total: 0, records: <LibraryRecord>[]))
        : primo.collectionItems(hotPart.id),
  ).wait;
  return (
    month: month,
    newBooks: newPage.records,
    hot: hot,
    hotBooks: hotPage.records,
    others: [
      for (final c in tree)
        if (c.id != news?.id && c.id != hot?.id) c,
    ].take(4).toList(),
    collectionCount: tree.length,
  );
}

/// Five new books on the shelf, a different set each day.
List<LibraryRecord> _featured(List<LibraryRecord> books) {
  final onShelf = [
    for (final b in books)
      if (b.availability == Availability.onShelf) b,
  ];
  final pool = onShelf.isEmpty ? books : onShelf;
  if (pool.isEmpty) return const [];
  final now = DateTime.now();
  final day = now.difference(DateTime(now.year)).inDays;
  return [
    for (var i = 0; i < 5 && i < pool.length; i++)
      pool[(day * 5 + i) % pool.length],
  ];
}

/// Design M1-C (design/round-11): a daily carousel of new books, shelves
/// of 新進圖書 and 誠品暢銷榜, then the other collections.
class _Browse extends StatelessWidget {
  const _Browse({required this.primo});

  final PrimoClient primo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final tones = context.tones;
    return Loader(
      load: () => _loadShelves(primo),
      builder: (context, shelves) {
        final featured = _featured(shelves.newBooks);
        final month = shelves.month;
        final hot = shelves.hot;
        return ListView(
          // No side padding: shelves and the carousel run to the screen
          // edge and pad their own content; everything else pads itself.
          padding: scrollPadding(context, top: 4).copyWith(left: 0, right: 0),
          children: [
            if (featured.isNotEmpty)
              _Carousel(
                books: featured,
                label: [l10n.newBooks, ?month?.name].join('・'),
              ),
            if (month != null && shelves.newBooks.isNotEmpty) ...[
              _ShelfHeader(
                title: l10n.newBooks,
                onAll: () =>
                    context.push('/more/library/collection/$newBooksId'),
              ),
              _Shelf(books: shelves.newBooks, offset: 1),
            ],
            if (hot != null && shelves.hotBooks.isNotEmpty) ...[
              _ShelfHeader(
                title: hot.name,
                onAll: () => context.push('/more/library/collection/${hot.id}'),
              ),
              _Shelf(books: shelves.hotBooks, offset: 2),
            ],
            _ShelfHeader(
              title: l10n.otherCollections,
              all: l10n.allCollections(shelves.collectionCount),
              onAll: () => context.push('/more/library/collections'),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.4,
              children: [
                for (final (i, c) in shelves.others.indexed)
                  ToneBlock(
                    tone: tones.cycle[(i + 3) % tones.cycle.length],
                    radius: 20,
                    padding: const EdgeInsets.all(12),
                    onTap: () =>
                        context.push('/more/library/collection/${c.id}'),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        c.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionLabel(l10n.onSchoolWebsite),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: scheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                title: Text(
                  l10n.libraryDiscovery,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                trailing: Icon(
                  Icons.north_east,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                onTap: () => openCampusPage(
                  context,
                  'https://$primoHost/discovery/search?vid=$primoVid&lang=zh-tw',
                  l10n.libraryDiscovery,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Carousel extends StatefulWidget {
  const _Carousel({required this.books, required this.label});

  final List<LibraryRecord> books;
  final String label;

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  final _pages = PageController(viewportFraction: 0.9);
  var _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final books = widget.books;
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pages,
            padEnds: false,
            itemCount: books.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final book = books[i];
              final tone = tones.cycle[(i + 4) % tones.cycle.length];
              final pill = availabilityPill(context, book.availability);
              return Padding(
                // Each page starts with the gap, so the first card lines up
                // with the page margin and the next one peeks in.
                padding: const EdgeInsets.only(left: 16),
                child: ToneBlock(
                  tone: tone,
                  radius: 26,
                  padding: const EdgeInsets.all(16),
                  onTap: () => context.push(
                    '/more/library/record',
                    extra: (record: book, index: i + 4),
                  ),
                  child: Row(
                    children: [
                      BookCover(
                        title: book.title,
                        index: i + 4,
                        width: 78,
                        inverse: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                book.author,
                                ?pill?.$2,
                              ].where((s) => s.isNotEmpty).join('・'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < books.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i == _page
                      ? scheme.onSurface
                      : scheme.surfaceContainerHigh,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ShelfHeader extends StatelessWidget {
  const _ShelfHeader({required this.title, required this.onAll, this.all});

  final String title;
  final String? all;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: onAll,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: Text(all ?? context.l10n.viewAll),
          ),
        ],
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.books, required this.offset});

  final List<LibraryRecord> books;

  /// Shifts the cover colors so neighbouring shelves differ.
  final int offset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final book = books[i];
          return GestureDetector(
            onTap: () => context.push(
              '/more/library/record',
              extra: (record: book, index: i + offset),
            ),
            child: SizedBox(
              width: 76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCover(title: book.title, index: i + offset, width: 76),
                  const SizedBox(height: 6),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _typeLabel(BuildContext context, PrimoType type) {
  final l10n = context.l10n;
  return switch (type) {
    PrimoType.books => l10n.typeBooks,
    PrimoType.journals => l10n.kindJournal,
    PrimoType.dissertations => l10n.typeDissertations,
    PrimoType.videos => l10n.typeVideos,
  };
}

String _sortLabel(BuildContext context, PrimoSort sort) {
  final l10n = context.l10n;
  return switch (sort) {
    PrimoSort.rank => l10n.sortRelevance,
    PrimoSort.newest => l10n.sortNewest,
    PrimoSort.title => l10n.sortTitle,
  };
}

String _yearsLabel(BuildContext context, int? years) => switch (years) {
  null => context.l10n.anyTime,
  _ => context.l10n.lastYears(years),
};

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final _Filters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late var _f = widget.initial;

  Widget _group<T>(
    String title,
    List<(T, String)> options,
    T value,
    _Filters Function(T) pick,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (option, label) in options)
              ChoiceChip(
                label: Text(label),
                selected: option == value,
                onSelected: (_) => setState(() => _f = pick(option)),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = _f;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.filter,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            _group<bool>(
              l10n.filterAvailability,
              [(true, l10n.onShelf), (false, l10n.anyTime)],
              f.onShelf,
              (v) => (onShelf: v, type: f.type, sort: f.sort, years: f.years),
            ),
            _group<PrimoType?>(
              l10n.filterType,
              [
                for (final t in PrimoType.values) (t, _typeLabel(context, t)),
                (null, l10n.anyTime),
              ],
              f.type,
              (v) =>
                  (onShelf: f.onShelf, type: v, sort: f.sort, years: f.years),
            ),
            _group<PrimoSort>(
              l10n.filterSort,
              [for (final s in PrimoSort.values) (s, _sortLabel(context, s))],
              f.sort,
              (v) =>
                  (onShelf: f.onShelf, type: f.type, sort: v, years: f.years),
            ),
            _group<int?>(
              l10n.filterYear,
              [
                for (final y in [5, 10, null]) (y, _yearsLabel(context, y)),
              ],
              f.years,
              (v) => (onShelf: f.onShelf, type: f.type, sort: f.sort, years: v),
            ),
            const SizedBox(height: 22),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
              onPressed: () => Navigator.pop(context, _f),
              child: Text(l10n.showResults),
            ),
          ],
        ),
      ),
    );
  }
}

/// A Primo result list that loads the next page near its end.
class RecordList extends StatefulWidget {
  const RecordList({super.key, required this.load, this.header});

  final Future<SearchPage> Function(int offset) load;
  final Widget? header;

  @override
  State<RecordList> createState() => _RecordListState();
}

class _RecordListState extends State<RecordList> {
  final _records = <LibraryRecord>[];
  int? _total;
  var _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _more();
  }

  Future<void> _more() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.load(_records.length);
      if (!mounted) return;
      setState(() {
        _records.addAll(page.records);
        _total = page.total;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = _total;
    final more = total != null && _records.length < total;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (more && n.metrics.extentAfter < 400) _more();
        return false;
      },
      child: ListView(
        padding: scrollPadding(context),
        children: [
          ?widget.header,
          if (total != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                l10n.resultCount(total),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final (i, r) in _records.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RecordRow(record: r, index: i),
            ),
          if (_error != null)
            Center(
              child: TextButton(onPressed: _more, child: Text(l10n.retry)),
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

/// Tone and label for a record's availability; null when there is none.
(Tone, String)? availabilityPill(BuildContext context, Availability a) {
  final tones = context.tones;
  final l10n = context.l10n;
  return switch (a) {
    Availability.onShelf => (tones.mint, l10n.onShelf),
    Availability.out => (tones.sun, l10n.checkedOut),
    Availability.online => (tones.lilac, l10n.online),
    Availability.none => null,
  };
}

/// A colored book spine with the title's first letter.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    required this.index,
    this.width = 44,
    this.inverse = false,
  });

  final String title;
  final int index;
  final double width;

  /// Dark cover, for sitting on a card of the same tone.
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final base = context.tones.cycle[index % context.tones.cycle.length];
    final tone = inverse ? Tone(base.ink, base.fill, base.strong) : base;
    return Container(
      width: width,
      height: width * 1.36,
      decoration: BoxDecoration(
        color: tone.fill,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(width * 0.12),
          right: Radius.circular(width * 0.2),
        ),
        border: Border(
          left: BorderSide(color: tone.strong, width: width * 0.09),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        title.isEmpty ? '' : title.characters.first,
        style: TextStyle(
          color: tone.ink,
          fontSize: width * 0.36,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class RecordRow extends StatelessWidget {
  const RecordRow({super.key, required this.record, required this.index});

  final LibraryRecord record;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pill = availabilityPill(context, record.availability);
    final where = record.holdings.isEmpty
        ? ''
        : [
            record.holdings.first.location,
            record.holdings.first.callNumber,
          ].where((s) => s.isNotEmpty).join('・');
    final small = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          '/more/library/record',
          extra: (record: record, index: index),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(title: record.title, index: index),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      [
                        record.author,
                        record.year,
                      ].where((s) => s.isNotEmpty).join('・'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: small,
                    ),
                    if (where.isNotEmpty)
                      Text(
                        where,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: small,
                      ),
                    if (pill case (final tone, final label)) ...[
                      const SizedBox(height: 6),
                      StatusPill(tone: tone, label: label),
                    ],
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
