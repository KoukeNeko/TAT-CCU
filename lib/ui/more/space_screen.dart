import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../l10n/l10n.dart';
import 'portal_screen.dart';
import '../core/campus_session.dart';
import '../core/campus_web_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

const _host = 'selfstudy.lib.ccu.edu.tw';
final _entry = entryUrl(campusSystems['0059']!);

/// The space system's PWA keeps its tokens in `localStorage.vuex` and sends
/// them as query parameters (research_notes/…/space_booking_probe.md). The
/// first read hands the tokens to the app, which then refreshes the QR code
/// and free places over plain HTTP: iOS stops scripts in a hidden WebView,
/// so it cannot be left to tick there. Booking stays on the website.
final _read =
    '''
(async () => {
  const app = () => { try { return JSON.parse(localStorage.vuex || '{}').App || {}; } catch (e) { return {}; } };
  const call = async (auth, path, extra = {}) => {
    const u = new URL('/RWDAPISSO/' + path, location.origin);
    for (const [k, v] of Object.entries({ ...auth, lang: 'zh-tw', restype: 'json', ...extra })) u.searchParams.set(k, v);
    const j = await (await fetch(u)).json();
    return Array.isArray(j) ? j[0] : j;
  };
  // The stored tokens may be a previous session's until the PWA writes the
  // new ones, and a page passing through can drop a request: keep checking.
  let auth = null;
  for (let i = 0; i < 30 && !auth; i++) {
    const a = app();
    if (a.userToken?.authid && a.deviceToken?.sid) {
      const t = { sid: a.deviceToken.sid, userid: a.userToken.userid, authid: a.userToken.authid };
      try { if ((await call(t, 'GetQRCode.aspx')).rescode === '1') auth = t; } catch (e) {}
    }
    if (!auth) await new Promise(r => setTimeout(r, 500));
  }
  if (!auth) {
    if (sessionStorage.getItem('tatccuSpace') === '1') throw new Error('Space sign-in did not finish');
    sessionStorage.setItem('tatccuSpace', '1');
    localStorage.removeItem('vuex');
    location.href = '$_entry';
    return;
  }
  sessionStorage.removeItem('tatccuSpace');
  const get = (path, extra) => call(auth, path, extra);
  const d = new Date();
  const today = d.getFullYear() + '/' + String(d.getMonth() + 1).padStart(2, '0') + '/' + String(d.getDate()).padStart(2, '0');
  const [params, types] = await Promise.all([get('Door/getParams.aspx'), get('GetCanBookSpaceType.aspx')]);
  // The PWA's own order (configs/spacetype.json SPACETYPE_ORDER).
  const order = ['60', '8', '50', '51'];
  const kinds = (types.resdata || []).slice().sort((x, y) => order.indexOf(String(x.spacetype)) - order.indexOf(String(y.spacetype)));
  const open = kinds.length ? (await get('GetOpenTime.aspx', { spacetype: kinds[0].spacetype, bookdate: today })).resdata?.[0] : null;
  // Floors the zone names do not carry (AI區) come from the floor guide.
  let guide = [];
  try {
    const doc = new DOMParser().parseFromString(await (await fetch('/floorInfo/lib_zh-tw.html')).text(), 'text/html');
    guide = [...doc.querySelectorAll('tr')].map(tr => [...tr.cells].map(td => td.textContent.trim()));
  } catch (e) {}
  Campus.postMessage(JSON.stringify({
    auth,
    refresh: Number(params.resdata?.[0]?.qrrefresh) || 180,
    interval: Number(params.resdata?.[0]?.apiinterval) || 30,
    open: open ? open.opentime + '–' + open.closetime : '',
    kinds: kinds.map(k => {
      const name = String(k.spacetypename).replace(/^QR/, '');
      const row = guide.find(c => c[0] && c[0].includes(name));
      const floor = row && (/^(\\d|B\\d)F?/.exec(row[1] || '') || [])[1];
      return { type: String(k.spacetype), name, floor: floor || '' };
    }),
  }));
})().catch(e => {
  sessionStorage.removeItem('tatccuSpace');
  Campus.postMessage(JSON.stringify({ error: String(e) }));
});
''';

const _api = 'https://$_host/RWDAPISSO';

typedef _Space = ({String type, String name, int free, String floors});

/// Design B-1 with B-2's places (design/round-11): a library pass whose
/// stub is the door QR code, then the free places, each booked on the
/// website. Nothing is cached: the code expires within minutes.
class SpaceScreen extends StatefulWidget {
  const SpaceScreen({super.key});

  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> {
  final _session = GlobalKey<CampusSessionState>();
  final _http = http.Client();
  Map<String, String>? _auth;
  List<Map>? _kinds;
  String _open = '';
  Uint8List? _qr;
  List<_Space> _spaces = const [];
  String? _error;
  var _refresh = 180, _interval = 30;
  var _qrLeft = 0, _placesLeft = 0;
  var _renewing = false;

  /// Tokens just came from a sign-in; a failure now is not an expiry.
  var _fresh = false;
  Timer? _tick, _watchdog;

  @override
  void dispose() {
    _tick?.cancel();
    _watchdog?.cancel();
    _http.close();
    super.dispose();
  }

  Future<dynamic> _get(String path) async {
    final uri = Uri.parse(
      '$_api/$path',
    ).replace(queryParameters: {..._auth!, 'lang': 'zh-tw', 'restype': 'json'});
    final res = await _http.get(uri).timeout(const Duration(seconds: 15));
    final json = jsonDecode(utf8.decode(res.bodyBytes));
    return json is List ? json.first : json;
  }

  void _received(Map<String, dynamic> json) {
    _watchdog?.cancel();
    if (json['error'] != null) {
      setState(() {
        _error = '${json['error']}';
        _renewing = false;
      });
      return;
    }
    _auth = {
      for (final e in (json['auth'] as Map).entries) '${e.key}': '${e.value}',
    };
    _kinds = (json['kinds'] as List).whereType<Map>().toList();
    _open = '${json['open'] ?? ''}';
    _refresh = (json['refresh'] as num?)?.toInt() ?? 180;
    _interval = (json['interval'] as num?)?.toInt() ?? 30;
    _fresh = true;
    _renewQr();
    _renewPlaces();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _qrLeft--;
        _placesLeft--;
      });
      if (_qrLeft <= 0 && !_renewing) _renewQr();
      if (_placesLeft <= 0) _renewPlaces();
    });
  }

  /// A new door code. If the tokens no longer work, signs in again.
  Future<void> _renewQr() async {
    setState(() => _renewing = true);
    try {
      final json = await _get('GetQRCode.aspx') as Map;
      if (json['rescode'] != '1') throw StateError('${json['resmsg']}');
      final data = '${(json['resdata'] as List).first['qrcode']}';
      if (!mounted) return;
      setState(() {
        _qr = base64Decode(data.split(',').last);
        _qrLeft = _refresh;
        _renewing = false;
        _error = null;
      });
      _fresh = false;
    } catch (e) {
      if (!mounted) return;
      if (_fresh) {
        // Signing in again would only loop.
        _tick?.cancel();
        setState(() {
          _renewing = false;
          _error = '$e';
        });
      } else {
        _signInAgain();
      }
    }
  }

  Future<void> _renewPlaces() async {
    _placesLeft = _interval;
    final kinds = _kinds;
    if (kinds == null) return;
    try {
      final rows = ((await _get('GetDevUseStatus.aspx') as Map)['rows'] as List)
          .whereType<Map>();
      if (!mounted) return;
      setState(() {
        _spaces = [
          for (final k in kinds)
            if (rows.where((r) => '${r['spacetype']}' == '${k['type']}')
                case final mine)
              (
                type: '${k['type']}',
                name: '${k['name']}',
                free: mine.fold(
                  0,
                  (n, r) => n + ((r['count'] as num?)?.toInt() ?? 0),
                ),
                floors: _floors(mine, '${k['floor']}'),
              ),
        ];
      });
    } on Exception {
      // Places are a hint: a failed request waits for the next interval.
      // Parse errors are bugs and are not caught.
    }
  }

  /// `5F` or `5–8F` from the zone names (5L, 807~810…), else the guide's.
  static String _floors(Iterable<Map> zones, String fallback) {
    final floors = {
      for (final z in zones)
        if (RegExp(r'^(\d)').firstMatch('${z['zonename']}') case final m?)
          int.parse(m[1]!),
    }.toList()..sort();
    if (floors.isEmpty) {
      return fallback.isEmpty || fallback.endsWith('F')
          ? fallback
          : '${fallback}F';
    }
    return floors.length == 1
        ? '${floors.first}F'
        : '${floors.first}–${floors.last}F';
  }

  void _signInAgain() {
    _tick?.cancel();
    setState(() => _renewing = true);
    _session.currentState?.reload();
    _watchdog?.cancel();
    _watchdog = Timer(const Duration(seconds: 30), () {
      if (!mounted || !_renewing) return;
      setState(() {
        _renewing = false;
        _error = context.l10n.loadFailed;
      });
    });
  }

  Future<void> _retry() async {
    setState(() => _error = null);
    await _session.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final qr = _qr;
    return CampusSession(
      key: _session,
      title: context.l10n.studySpace,
      entry: _entry,
      host: _host,
      script: () => _read,
      onMessage: _received,
      child: _error != null
          ? CampusError(message: _error!, onRetry: _retry)
          : qr == null
          ? null
          : Builder(
              builder: (context) => RefreshIndicator(
                edgeOffset: MediaQuery.paddingOf(context).top,
                onRefresh: () async {
                  await _renewQr();
                  await _renewPlaces();
                },
                child: ListView(
                  padding: scrollPadding(context),
                  children: [
                    _Pass(
                      qr: qr,
                      open: _open,
                      left: _qrLeft.clamp(0, _refresh),
                      renewing: _renewing,
                      onRenew: _renewQr,
                    ),
                    SectionLabel(
                      context.l10n.available,
                      detail: context.l10n.updatesIn(
                        _placesLeft.clamp(0, _interval),
                      ),
                    ),
                    _Places(spaces: _spaces),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Pass extends StatelessWidget {
  const _Pass({
    required this.qr,
    required this.open,
    required this.left,
    required this.renewing,
    required this.onRenew,
  });

  final Uint8List qr;
  final String open;
  final int left;
  final bool renewing;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final tone = context.tones.lilac;
    final card = scheme.surfaceContainerLow;
    TextStyle small(Color c) => TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
      color: c,
    );
    Widget field(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: small(scheme.onSurfaceVariant)),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ],
    );
    return Material(
      color: card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: tone.strong,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Text(
                  'LIBRARY PASS',
                  style: TextStyle(
                    color: tone.fill,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(l10n.studySpace, style: small(tone.fill)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: Row(
              children: [
                if (open.isNotEmpty)
                  Expanded(child: field(l10n.openHours, open)),
                Expanded(
                  child: field(
                    l10n.validFor,
                    renewing ? l10n.refreshing : clock(left),
                  ),
                ),
              ],
            ),
          ),
          const _Perforation(),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // Scanners need dark modules on white, in dark mode too.
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Corners.inset),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ImageFiltered(
                        enabled: renewing,
                        imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Opacity(
                          opacity: renewing ? 0.45 : 1,
                          child: Image.memory(
                            qr,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.none,
                            semanticLabel: l10n.scanToCheckIn,
                          ),
                        ),
                      ),
                      if (renewing)
                        Text(
                          l10n.refreshing,
                          style: const TextStyle(
                            color: Color(0xFF22191A),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.scanToCheckIn,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    BarChip(
                      label: '↻ ${l10n.refresh}',
                      selected: false,
                      onTap: renewing ? null : onRenew,
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

/// The dashed tear line with a notch cut on each side, in the page color.
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: CustomPaint(
              size: const Size(double.infinity, 2),
              painter: _Dashes(scheme.outlineVariant),
            ),
          ),
          for (final left in [-12.0, null])
            Positioned(
              left: left,
              right: left == null ? -12 : null,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dashes extends CustomPainter {
  _Dashes(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (var x = 0.0; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, 0), Offset(x + 5, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_Dashes old) => old.color != color;
}

class _Places extends StatelessWidget {
  const _Places({required this.spaces});

  final List<_Space> spaces;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final colors = [tones.lilac, tones.mint, tones.peach, tones.sun];
    // Same height for every card, whatever the name's length.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, s) in spaces.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Material(
                color: scheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Corners.row),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => openCampusPage(
                    context,
                    'https://$_host/pwaspace/space/${s.type}',
                    s.name,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s.floors.isNotEmpty)
                          StatusPill(
                            tone: colors[i % colors.length],
                            label: s.floors,
                          ),
                        const SizedBox(height: 6),
                        Text(
                          '${s.free}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 6),
                        Text(
                          '${context.l10n.bookSpace} ↗',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: tones.lilac.strong,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
