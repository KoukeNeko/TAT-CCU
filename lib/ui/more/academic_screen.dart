import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/ecourse_auth_repository.dart';
import '../../data/services/demo_data.dart';
import '../../data/repositories/certificate_store.dart';
import '../../data/repositories/campus_cache.dart';
import '../core/campus_session.dart';
import '../core/campus_web_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../l10n/l10n.dart';
import '../core/campus_systems.dart';

const _host = 'www026198.ccu.edu.tw';
const _detailUrl = 'https://$_host/academic/academic_detail.php';
final _entry = entryUrl(campusSystems['0004']!);

/// The hand-off lands on the detail page; its form holds the record
/// (research_notes/…/academic_records_probe.md).
const _readDetail = '''
(() => {
  const v = n => (document.querySelector('[name="' + n + '"]') || {}).value || '';
  Campus.postMessage(JSON.stringify({ kind: 'detail', studentNo: v('std_no'),
    englishName: v('e_name'), email: v('e_mail'), mobile: v('cellur_no') }));
})();
''';

/// `prt_CerEnr.php` answers a plain GET with a freshly printed PDF.
final _fetchCertificate = fetchPdfScript('prt_CerEnr.php');

typedef _Detail = ({
  String studentNo,
  String englishName,
  String email,
  String mobile,
});

/// Design C1 "票券佔滿螢幕" (design/round-11): saved 在學證明書 as tickets
/// you swipe through, newest first, then the record and website links.
/// Saved certificates open without a connection.
class AcademicScreen extends StatefulWidget {
  const AcademicScreen({super.key});

  static const cacheKey = 'academic';

  @override
  State<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends State<AcademicScreen> {
  final _session = GlobalKey<CampusSessionState>();
  final _store = CertificateStore();
  final _pages = PageController(viewportFraction: 0.92);
  List<Certificate>? _certificates;
  _Detail? _detail;
  var _printing = false;
  var _page = 0;
  String? _error;
  DateTime? _savedAt;

  /// Whether the session reached the school this visit; printing needs it.
  var _signedIn = false;
  var _printWhenSignedIn = false;

  @override
  void initState() {
    super.initState();
    _refreshList();
    // The record rarely changes: show the last read and fetch only when
    // there is none or the user pulls to refresh.
    CampusCache.read(AcademicScreen.cacheKey).then((cached) {
      if (!mounted) return;
      if (cached == null) {
        _session.currentState?.reload();
      } else {
        setState(() {
          _detail = _detailOf(cached.json);
          _savedAt = cached.savedAt;
        });
      }
    });
  }

  static _Detail _detailOf(Map<String, dynamic> json) => (
    studentNo: '${json['studentNo']}',
    englishName: '${json['englishName']}',
    email: '${json['email']}',
    mobile: '${json['mobile']}',
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _refreshList() async {
    // Saved certificates are the real student's; the demo has none.
    final list = context.read<EcourseAuthRepository>().isDemo
        ? const <Certificate>[]
        : await _store.list();
    if (mounted) setState(() => _certificates = list);
  }

  void _print() {
    if (context.read<EcourseAuthRepository>().isDemo) {
      _session.currentState?.run('');
      return;
    }
    setState(() {
      _printing = true;
      _error = null;
    });
    if (_signedIn) {
      _session.currentState?.run(_fetchCertificate);
    } else {
      // Sign in through the hand-off first; printing follows the record.
      _printWhenSignedIn = true;
      _session.currentState?.reload();
    }
  }

  Future<void> _received(Map<String, dynamic> json) async {
    switch (json['kind']) {
      case 'detail':
        _signedIn = true;
        final savedAt = await CampusCache.write(AcademicScreen.cacheKey, json);
        if (!mounted) return;
        setState(() {
          _detail = _detailOf(json);
          _savedAt = savedAt;
        });
        if (_printWhenSignedIn) {
          _printWhenSignedIn = false;
          _session.currentState?.run(_fetchCertificate);
        }
      case 'pdf':
        try {
          if (json['error'] != null) throw Exception(json['error']);
          await _store.save(base64Decode('${json['data']}'), DateTime.now());
          await _refreshList();
          if (_pages.hasClients) _pages.jumpToPage(0);
          _page = 0;
        } on NotPdfException {
          if (mounted) setState(() => _error = context.l10n.notPdf);
        } catch (e) {
          setState(() => _error = '$e');
        } finally {
          if (mounted) setState(() => _printing = false);
        }
    }
  }

  Widget _tickets(List<Certificate> certificates) {
    final tickets = [
      if (certificates.isEmpty)
        _Ticket(certificate: null, printing: _printing, onPrint: _print),
      for (final (i, c) in certificates.indexed)
        _Ticket(
          certificate: c,
          printing: _printing,
          // Only the newest offers to print again.
          onPrint: i == 0 ? _print : null,
        ),
    ];
    if (tickets.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.l),
        child: tickets.single,
      );
    }
    // Older copies peek in from the right.
    return PageView(
      controller: _pages,
      padEnds: false,
      onPageChanged: (i) => setState(() => _page = i),
      children: [
        for (final t in tickets)
          Padding(
            padding: const EdgeInsets.only(left: Space.l),
            child: t,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final certificates = _certificates;
    final detail = _detail;
    final scheme = Theme.of(context).colorScheme;
    return CampusSession(
      key: _session,
      title: context.l10n.academicSystem,
      entry: _entry,
      host: _host,
      script: () => _readDetail,
      demo: DemoCampus.academic,
      loadOnStart: false,
      onMessage: _received,
      // Always shown, so saved certificates open offline.
      child: Builder(
        builder: (context) => PullRefresh(
          onRefresh: () async => _session.currentState?.refresh(),
          child: ListView(
            padding: scrollPadding(context).copyWith(left: 0, right: 0),
            children: [
              SizedBox(
                height: 520,
                child: certificates == null
                    ? const Center(child: CircularProgressIndicator())
                    : _tickets(certificates),
              ),
              if ((certificates?.length ?? 0) > 1)
                Padding(
                  padding: const EdgeInsets.only(top: Space.m),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < certificates!.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutQuart,
                          width: i == _page ? 20 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _page
                                ? scheme.onSurfaceVariant
                                : scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.l,
                    Space.s,
                    Space.l,
                    0,
                  ),
                  child: Text(_error!, style: TextStyle(color: scheme.error)),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (detail != null) ...[
                      SectionLabel(context.l10n.academicRecord),
                      Card(
                        color: scheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.l,
                          ),
                          child: Column(
                            children: [
                              for (final (i, (label, value)) in [
                                (context.l10n.studentNo, detail.studentNo),
                                (context.l10n.englishName, detail.englishName),
                                (context.l10n.email, detail.email),
                                (context.l10n.mobile, detail.mobile),
                              ].indexed) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    color: scheme.outlineVariant,
                                  ),
                                _Field(label, value),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    SectionLabel(context.l10n.onSchoolWebsite),
                    Card(
                      color: scheme.surfaceContainerLow,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (final title in [
                            context.l10n.editNameContact,
                            context.l10n.studentPhoto,
                          ])
                            ListTile(
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              trailing: Icon(
                                Icons.north_east,
                                size: 18,
                                color: scheme.onSurfaceVariant,
                              ),
                              onTap: () => openCampusPage(
                                context,
                                _detailUrl,
                                context.l10n.academicSystem,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_savedAt case final time?) UpdatedAt(time),
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

class _Ticket extends StatelessWidget {
  const _Ticket({
    required this.certificate,
    required this.printing,
    required this.onPrint,
  });

  final Certificate? certificate;
  final bool printing;
  final VoidCallback? onPrint;

  void _open(BuildContext context, Certificate c) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: subBar(context, context.l10n.enrollmentCertificate),
        body: PdfViewer.file(c.file.path),
      ),
    ),
  );

  void _share(BuildContext context, Certificate c) {
    final box = context.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        files: [XFile(c.file.path, mimeType: 'application/pdf')],
        // iPad anchors the share sheet to the ticket.
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final c = certificate;
    final current = c != null && isCurrent(c, DateTime.now());
    final tone = current ? tones.mint : tones.sun;
    final semester = c == null
        ? semesterOf(DateTime.now())
        : semesterOf(c.printedAt);
    final l10n = context.l10n;
    final printLabel = printing
        ? l10n.generating
        : (c == null ? l10n.generate : l10n.regenerate);
    final buttons = <Widget>[
      if (c != null && current) ...[
        _Action(l10n.open, primary: true, onTap: () => _open(context, c)),
        _Action(l10n.share, onTap: () => _share(context, c)),
        if (onPrint != null)
          _Action(printLabel, onTap: printing ? null : onPrint),
      ] else ...[
        if (onPrint != null)
          _Action(printLabel, primary: true, onTap: printing ? null : onPrint),
        if (c != null) _Action(l10n.open, onTap: () => _open(context, c)),
      ],
    ];
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: tone.fill,
            padding: const EdgeInsets.fromLTRB(
              Space.l,
              Space.l,
              Space.l,
              Space.l,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  // Inset so `115-1` stays inside the star's points.
                  padding: const EdgeInsets.all(Space.m),
                  decoration: ShapeDecoration(
                    color: tone.strong,
                    shape: spikyStar,
                  ),
                  child: FittedBox(
                    child: Text(
                      semester,
                      style: TextStyle(
                        color: tone.fill,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: tone.ink),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.enrollmentCertificate,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          c == null
                              ? l10n.notYetThisSemester
                              : current
                              ? l10n.validPrinted(monthDay(c.printedAt))
                              : l10n.expiredPrinted(monthDay(c.printedAt)),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: scheme.surfaceContainerHigh,
              padding: const EdgeInsets.symmetric(vertical: Space.l),
              child: c == null
                  ? Center(
                      child: AspectRatio(
                        aspectRatio: 595 / 842,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () => _open(context, c),
                      child: PdfDocumentViewBuilder.file(
                        c.file.path,
                        builder: (context, document) => PdfPageView(
                          document: document,
                          pageNumber: 1,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
            ),
          ),
          if (c != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 0),
              child: Row(
                children: [
                  Text(
                    l10n.savedToDevice(monthDayTime(c.printedAt)),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'PDF・${fileSize(c.size)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          // Ticket stub: punched notches and a perforation.
          SizedBox(
            height: 24,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.xl),
                  child: CustomPaint(
                    size: const Size(double.infinity, 2),
                    painter: _Perforation(scheme.outlineVariant),
                  ),
                ),
                for (final left in [true, false])
                  Positioned(
                    left: left ? -10 : null,
                    right: left ? null : -10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.m, 0, Space.m, Space.m),
            child: Row(
              children: [
                for (final (i, b) in buttons.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: b),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Perforation extends CustomPainter {
  const _Perforation(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 1), Offset(x + 4, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_Perforation old) => old.color != color;
}

class _Action extends StatelessWidget {
  const _Action(this.label, {required this.onTap, this.primary = false});

  final String label;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      // Three buttons share the ticket; 重新產生 must fit on one line.
      padding: const EdgeInsets.symmetric(horizontal: Space.s),
      textStyle: Theme.of(context).textTheme.labelLarge
          ?.copyWith(fontWeight: FontWeight.w900),
    );
    return primary
        ? FilledButton(
            onPressed: onTap,
            style: style,
            child: Text(label, maxLines: 1, softWrap: false),
          )
        : FilledButton.tonal(
            onPressed: onTap,
            style: style,
            child: Text(label, maxLines: 1, softWrap: false),
          );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label, value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.m),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
