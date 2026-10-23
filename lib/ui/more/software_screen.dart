import 'dart:convert' show base64Decode, jsonEncode;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/l10n.dart';
import '../core/auto_refresh.dart';
import '../core/campus_session.dart';
import '../core/campus_systems.dart';
import '../core/campus_web_screen.dart';
import '../core/pdf_viewer.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

const _host = 'software.ccu.edu.tw';
final _system = campusSystems['0008']!;

/// The home page lists the categories as cards whose onclick posts them to
/// download.php; each category page has a table per section (名稱｜適用系統｜
/// 版本/位元｜下載次數), and every row a form posting its `id` to get_file.php,
/// which opens in a new window for an outside link
/// (research_notes/…/campus_software_probe.md).
const _readCategories = r'''
(async () => {
  const cards = [...document.querySelectorAll('a.soft-card')]
    .map(a => (a.getAttribute('onclick').match(/'([^']*)'/g) || []).map(s => s.slice(1, -1)));
  if (!cards.length) throw new Error('software categories not found');
  const categories = [];
  for (const [link, title, icon, desc] of cards) {
    const r = await fetch('/download.php', { method: 'POST', credentials: 'same-origin',
      body: new URLSearchParams({ category_link: link, category_title: title,
        category_icon: icon, category_desc: desc }) });
    const d = new DOMParser().parseFromString(await r.text(), 'text/html');
    const sections = [...d.querySelectorAll('h3')].map(h => {
      let t = h.nextElementSibling;
      while (t && t.tagName !== 'TABLE' && !t.querySelector('table')) t = t.nextElementSibling;
      const table = t && (t.tagName === 'TABLE' ? t : t.querySelector('table'));
      const items = table ? [...table.querySelectorAll('tbody tr')].map(tr => {
        const c = [...tr.cells].map(td => td.textContent.trim());
        const form = tr.querySelector('form');
        return { name: c[0], os: c[1] || '', version: c[2] || '', count: parseInt(c[3]) || 0,
          id: form?.querySelector('input[name=id]')?.value,
          link: form?.getAttribute('target') === '_blank' };
      }).filter(i => i.id) : [];
      // The headings start with an emoji.
      return { title: h.textContent.replace(/^[^\p{L}\p{N}]+/u, '').trim(), items };
    }).filter(s => s.items.length);
    categories.push({ title, name: desc, sections });
  }
  Campus.postMessage(JSON.stringify({ categories }));
})().catch(e => Campus.postMessage(JSON.stringify({ error: String(e) })));
''';

/// Larger files (installers) are left to the website: they would cross the
/// WebView bridge as base64 in one piece.
const _openLimit = 40 * 1024 * 1024;

/// Fetches file [id] from get_file.php and answers it as base64, or
/// `tooBig` when it is over [_openLimit].
String _fetchFile(String id) =>
    '''
(async () => {
  const post = json => Campus.postMessage(JSON.stringify({ kind: 'file', id: ${jsonEncode(id)}, ...json }));
  try {
    const r = await fetch('/get_file.php', { method: 'POST', credentials: 'same-origin',
      body: new URLSearchParams({ id: ${jsonEncode(id)} }) });
    if (!r.ok) throw new Error('HTTP ' + r.status);
    if ((r.headers.get('content-type') || '').startsWith('text/html')) {
      throw new Error('no file');
    }
    if (+r.headers.get('content-length') > $_openLimit) {
      r.body?.cancel();
      return post({ tooBig: true });
    }
    let name = (r.headers.get('content-disposition') || '')
      .match(/filename\\*?=(?:UTF-8'')?"?([^";]+)/i)?.[1] || '';
    try { name = decodeURIComponent(name); } catch (_) {}
    const bytes = new Uint8Array(await r.arrayBuffer());
    let bin = '';
    for (let i = 0; i < bytes.length; i += 0x8000) {
      bin += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
    }
    post({ name, data: btoa(bin) });
  } catch (e) {
    post({ error: String(e) });
  }
})();
''';

typedef _Item = ({
  String name,
  String os,
  String version,
  int count,
  String id,
  bool link,
});

typedef _Category = ({
  String title,
  String name,
  List<({String title, List<_Item> items})> sections,
});

List<_Category> _categoriesOf(Map<String, dynamic> json) => [
  for (final c in json['categories'] as List? ?? const [])
    (
      title: '${c['title']}',
      name: '${c['name']}',
      sections: [
        for (final s in c['sections'] as List)
          (
            title: '${s['title']}',
            items: [
              for (final i in s['items'] as List)
                (
                  name: '${i['name']}',
                  os: '${i['os']}',
                  version: '${i['version']}',
                  count: (i['count'] as num).toInt(),
                  id: '${i['id']}',
                  link: i['link'] == true,
                ),
            ],
          ),
      ],
    ),
];

int _downloads(_Category c) => [
  for (final s in c.sections)
    for (final i in s.items) i.count,
].fold(0, (a, b) => a + b);

List<_Category> _ranked(List<_Category> categories) =>
    [...categories]..sort((a, b) => _downloads(b).compareTo(_downloads(a)));

/// Activation files, licences and manuals open in the app; the rest are
/// installers, downloaded on the website.
// shortcut: told apart by name, since the site marks neither; switch to the
// file's size once the list says it.
bool _opensHere(_Item i) =>
    RegExp('啟用|授權|序號|手冊|說明|規範|導引|常見問題').hasMatch(i.name);

/// The website's categories on a floating switch, the chosen one's files
/// below by its sections; it opens on the most downloaded category.
class SoftwareScreen extends StatefulWidget {
  static const cacheKey = 'software';

  const SoftwareScreen({super.key});

  @override
  State<SoftwareScreen> createState() => _SoftwareScreenState();
}

class _SoftwareScreenState extends State<SoftwareScreen>
    with AutoRefresh, CampusPageState {
  @override
  String get cacheKey => SoftwareScreen.cacheKey;

  // The list changes a few times a year.
  @override
  bool get readOnOpen => false;

  /// The category shown, by name; the most downloaded until one is chosen.
  String? _open;

  /// The file being fetched, by id.
  final _fetching = ValueNotifier<String?>(null);

  Future<void> _onMessage(Map<String, dynamic> message) async {
    if (message['kind'] != 'file') return received(message);
    final l10n = context.l10n;
    final name = _fetchingName;
    _fetching.value = null;
    if (message['tooBig'] == true) return _openSite();
    if (message['error'] != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${message['error']}')));
      return;
    }
    final fileName = '${message['name']}'.isEmpty ? name : '${message['name']}';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(base64Decode('${message['data']}'));
    if (!mounted) return;
    if (fileName.toLowerCase().endsWith('.pdf')) {
      await showPdfFile(context, file, name);
    } else {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], title: l10n.campusSoftware),
      );
    }
  }

  String _fetchingName = '';

  void _openSite() => openExternal(entryUrl(_system));

  Future<void> _act(_Item item) async {
    if (item.link) {
      return openCampusPage(
        context,
        'https://$_host/get_file.php',
        item.name,
        form: {'id': item.id},
      );
    }
    if (!_opensHere(item)) return _openSite();
    _fetchingName = item.name;
    _fetching.value = item.id;
    await session.currentState?.runSignedIn(_fetchFile(item.id));
  }

  @override
  void dispose() {
    _fetching.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = json == null ? null : _categoriesOf(json!);
    final open = categories == null || categories.isEmpty
        ? null
        : categories.where((c) => c.name == _open).firstOrNull ??
              _ranked(categories).first;
    return CampusSession(
      key: session,
      title: open?.name ?? l10n.campusSoftware,
      titleChild: open == null
          ? null
          : _CategoryMenu(
              categories: categories!,
              open: open,
              onPick: (c) => setState(() => _open = c.name),
            ),
      entry: entryUrl(_system),
      host: _host,
      loadOnStart: false,
      script: () => _readCategories,
      onMessage: _onMessage,
      action: const SchoolSiteButton('0008'),
      child: error != null
          ? CampusError(message: error!, onRetry: retry)
          : open == null
          ? null
          : Builder(
              // Reads insets from inside the session's Scaffold.
              builder: (context) => PullRefresh(
                onRefresh: () async => session.currentState?.refresh(),
                child: ValueListenableBuilder(
                  valueListenable: _fetching,
                  builder: (context, fetching, _) => _CategoryPage(
                    category: open,
                    fetching: fetching,
                    onAct: _act,
                    onSite: _openSite,
                  ),
                ),
              ),
            ),
    );
  }
}

/// The category as the page title, a menu of the others when tapped.
class _CategoryMenu extends StatelessWidget {
  const _CategoryMenu({
    required this.categories,
    required this.open,
    required this.onPick,
  });

  final List<_Category> categories;
  final _Category open;
  final ValueChanged<_Category> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      // Builder: the menu drops from the name, not the whole title row.
      child: Builder(
        builder: (context) => InkWell(
          borderRadius: BorderRadius.circular(Corners.small),
          onTap: () async {
            final box = context.findRenderObject()! as RenderBox;
            final name = await showGlassMenu<String>(
              context,
              anchor: box.localToGlobal(Offset.zero) & box.size,
              selected: open.name,
              items: [
                for (final c in categories)
                  (
                    value: c.name,
                    title: c.name,
                    detail: l10n.swDownloads(_downloads(c)),
                    icon: null,
                    tone: null,
                  ),
              ],
            );
            final picked = categories.where((c) => c.name == name).firstOrNull;
            if (picked != null) onPick(picked);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  open.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.expand_more,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Design round-23 C: what opens in the app (activation files, licences,
/// manuals) and the outside links apart from the installers, which are
/// downloaded on the website; side by side on a wide screen.
class _CategoryPage extends StatelessWidget {
  const _CategoryPage({
    required this.category,
    required this.fetching,
    required this.onAct,
    required this.onSite,
  });

  final _Category category;
  final String? fetching;
  final ValueChanged<_Item> onAct;
  final VoidCallback onSite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [for (final s in category.sections) ...s.items];
    final here = [
      for (final i in items)
        if (i.link || _opensHere(i)) i,
    ];
    final installers = [
      for (final i in items)
        if (!i.link && !_opensHere(i)) i,
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 760;
        final hereColumn = [
          if (here.isNotEmpty) ...[
            _Heading(
              l10n.swHere,
              hint: l10n.swHereHint,
              color: context.tones.lilac.strong,
            ),
            for (final i in here) ...[
              _HereCard(item: i, fetching: fetching, onAct: onAct),
              const SizedBox(height: Space.s),
            ],
          ],
        ];
        final siteColumn = [
          if (installers.isNotEmpty) ...[
            _Heading(
              l10n.swInstallers,
              hint: l10n.swOnSite,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            _Installers(items: installers, full: wide, onSite: onSite),
            const SizedBox(height: Space.m),
            Align(
              alignment: wide
                  ? AlignmentDirectional.centerStart
                  : Alignment.center,
              child: FilledButton.tonal(
                onPressed: onSite,
                child: Text('${l10n.swOnSite} ↗'),
              ),
            ),
          ],
        ];
        if (!wide) {
          return ListView(
            padding: scrollPadding(context),
            children: [...hereColumn, ...siteColumn],
          );
        }
        return ListView(
          padding: scrollPadding(context, maxWidth: 1100),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (siteColumn.isNotEmpty)
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: siteColumn,
                    ),
                  ),
                if (siteColumn.isNotEmpty && hereColumn.isNotEmpty)
                  const SizedBox(width: Space.xxl),
                if (hereColumn.isNotEmpty)
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: hereColumn,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {required this.hint, required this.color});

  final String text, hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.xs,
        sectionAbove,
        Space.xs,
        Space.s,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: Space.s),
          Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          Text(
            hint,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// A file that opens in the app, or an outside link, on the lilac tone.
class _HereCard extends StatelessWidget {
  const _HereCard({
    required this.item,
    required this.fetching,
    required this.onAct,
  });

  final _Item item;
  final String? fetching;
  final ValueChanged<_Item> onAct;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = context.tones.lilac;
    return Material(
      color: tone.fill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: tone.ink,
                    ),
                  ),
                  Text(
                    l10n.swDownloads(item.count),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: tone.ink.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.m),
            if (fetching == item.id)
              SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: tone.ink,
                ),
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: tone.ink,
                  foregroundColor: tone.fill,
                ),
                onPressed: fetching == null || item.link
                    ? () => onAct(item)
                    : null,
                child: Text(item.link ? '${l10n.swLink} ↗' : l10n.open),
              ),
          ],
        ),
      ),
    );
  }
}

/// The installers in one card, each with its download count; a phone
/// leaves out the words every name shares.
class _Installers extends StatelessWidget {
  const _Installers({
    required this.items,
    required this.full,
    required this.onSite,
  });

  final List<_Item> items;
  final bool full;
  final VoidCallback onSite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final shared = full || items.length < 2 ? 0 : _sharedWords(items);
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Column(
        children: [
          for (final (n, i) in items.indexed) ...[
            if (n > 0)
              const Divider(height: 1, indent: Space.l, endIndent: Space.l),
            InkWell(
              onTap: onSite,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.l,
                  vertical: Space.m,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        i.name.split(' ').skip(shared).join(' '),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: Space.m),
                    Text(
                      l10n.swDownloads(i.count),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// How many leading words every name has in common, keeping one at least.
int _sharedWords(List<_Item> items) {
  final words = [for (final i in items) i.name.split(' ')];
  final shortest = words.map((w) => w.length).reduce((a, b) => a < b ? a : b);
  var n = 0;
  while (n < shortest - 1 && words.every((w) => w[n] == words.first[n])) {
    n++;
  }
  return n;
}
