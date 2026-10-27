import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/repositories/ecourse_auth_repository.dart';
import '../../data/services/demo_data.dart';
import '../../data/repositories/certificate_store.dart';
import '../../data/services/payment_data.dart';
import '../../l10n/l10n.dart';
import '../core/auto_refresh.dart';
import '../core/campus_session.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/pdf_viewer.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../core/campus_systems.dart';

const _host = 'www026197.ccu.edu.tw';
const _api = 'https://$_host/gensys/site/general';

String _show(int n) => '\$${grouped(n)}';

/// The tax office's income format codes most students see.
const _formatNames = {
  '50': '薪資',
  '9A': '執行業務',
  '9B': '稿費',
  '51': '租賃',
  '5A': '利息',
  '92': '其他所得',
};

/// Only the last four digits of an account are shown.
String _masked(String account) => account.length <= 4
    ? account
    : '${'*' * (account.length - 4)}${account.substring(account.length - 4)}';

/// Design round-11 payment-home H2: the year's payments as a chart on the
/// main card, the chosen month's payments, then each year's income with
/// its two statements.
class PaymentScreen extends StatefulWidget {
  static const cacheKey = 'payment';

  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with AutoRefresh, CampusPageState {
  final _yearKey = GlobalKey();
  var _year = rocYear(clk.clock.now());
  int? _month;
  String? _open;
  ({String title, String file})? _pdf;
  Timer? _pdfWatchdog;

  @override
  String get cacheKey => PaymentScreen.cacheKey;

  /// Only the year on screen; another one waits for its read.
  @override
  bool keepsSaved(Map<String, dynamic> saved) => saved['year'] == _year;

  void _openPdf(String url, String title, String file) {
    if (context.read<EcourseAuthRepository>().isDemo) {
      session.currentState?.run('');
      return;
    }
    if (_pdf != null) return;
    _pdf = (title: title, file: file);
    session.currentState?.runSignedIn(fetchPdfScript(url));
    // An expired session may never answer; let the buttons work again.
    _pdfWatchdog = Timer(const Duration(seconds: 30), () {
      if (!mounted || _pdf == null) return;
      _pdf = null;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.loadFailed)));
    });
  }

  @override
  void dispose() {
    _pdfWatchdog?.cancel();
    super.dispose();
  }

  /// Opens the statement with its own share button. The file is named by
  /// year and format only, never by the ID number in its URL.
  Future<void> _showPdf(Map<String, dynamic> json) async {
    _pdfWatchdog?.cancel();
    final pdf = _pdf;
    if (pdf == null) return;
    _pdf = null;
    final l10n = context.l10n;
    final bytes = json['error'] == null
        ? base64Decode('${json['data']}')
        : null;
    if (bytes == null || !isPdf(bytes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${json['error'] ?? l10n.notPdf}')),
      );
      return;
    }
    final file = File(
      '${(await getTemporaryDirectory()).path}/${pdf.file}.pdf',
    );
    // macOS hands out its temporary folder before creating it.
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    if (mounted) await showFile(context, file, pdf.title);
  }

  /// A statement answers `pdf`; a new read also clears the chosen month.
  @override
  Future<void> received(Map<String, dynamic> message) async {
    if (message['kind'] == 'pdf') return _showPdf(message);
    if (message['error'] == null) _month = null;
    await super.received(message);
  }

  Future<void> _pickYear() async {
    final box = _yearKey.currentContext!.findRenderObject()! as RenderBox;
    final now = rocYear(clk.clock.now());
    final y = await showGlassMenu<int>(
      context,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      selected: _year,
      items: [
        for (var y = now; y > now - 6; y--)
          (
            value: y,
            title: context.l10n.payYear(y),
            detail: null,
            icon: null,
            tone: null,
          ),
      ],
    );
    if (y == null || y == _year) return;
    setState(() {
      _year = y;
      this.json = null;
      _month = null;
    });
    session.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final saved = this.json;
    return CampusSession(
      key: session,
      title: context.l10n.payTitle,
      entry: entryUrl(campusSystems['0042']!),
      host: _host,
      loadOnStart: false,
      action: const SchoolSiteButton('0042'),
      bottom: ChipBar(
        children: [
          BarChip(
            key: _yearKey,
            label: context.l10n.payYear(_year),
            selected: true,
            dropdown: true,
            onTap: _pickYear,
          ),
        ],
      ),
      script: () => readPayments(_year),
      demo: () => DemoCampus.payments(_year),
      onMessage: received,
      child: error != null
          ? CampusError(message: error!, onRetry: retry)
          : saved == null
          ? null
          : Builder(
              builder: (context) => PullRefresh(
                onRefresh: () async => session.currentState?.refresh(),
                child: _body(context, saved),
              ),
            ),
    );
  }

  Widget _body(BuildContext context, Map<String, dynamic> json) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final payments = paymentsOf(json);
    final income = incomeOf(json);
    final now = clk.clock.now();
    final lastMonth = _year == rocYear(now) ? now.month : 12;
    final byMonth = List.filled(12, 0);
    for (final p in payments) {
      byMonth[p.date.month - 1] += p.amount;
    }
    final month =
        _month ?? (payments.isEmpty ? lastMonth : payments.first.date.month);
    final shown = [
      for (final p in payments)
        if (p.date.month == month) p,
    ];
    final chart = _ChartCard(
      title: l10n.payReceived(_year, payments.length),
      total: payments.fold(0, (sum, p) => sum + p.amount),
      months: byMonth.sublist(0, lastMonth),
      selected: month,
      onSelect: (m) => setState(() {
        _month = m;
        _open = null;
      }),
    );
    final incomes = [
      for (final MapEntry(key: year, value: list)
          in (income.entries.toList()..sort((a, b) => b.key - a.key)))
        for (final item in list)
          _IncomeCard(year: year, income: item, onOpen: _openPdf),
    ];
    if (desktopUi(context)) {
      // design/round-25 payment: the chart across, then the month's
      // payments beside the year's income.
      final muted = TextStyle(
        fontWeight: FontWeight.w700,
        color: scheme.onSurfaceVariant,
      );
      return ListView(
        padding: scrollPadding(context),
        children: [
          chart,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 13,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionLabel(
                      l10n.payMonth(month),
                      detail: shown.isEmpty
                          ? null
                          : '${l10n.recordCount(shown.length)}・'
                                '${_show(shown.fold(0, (sum, p) => sum + p.amount))}',
                    ),
                    if (shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: Space.xl),
                        child: Text(l10n.payNone, style: muted),
                      ),
                    for (final p in shown) _PaymentRow(payment: p, open: true),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                flex: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionLabel(l10n.incomeTitle),
                    if (incomes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: Space.xl),
                        child: Text(l10n.incomeNone, style: muted),
                      ),
                    for (final card in incomes)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.m),
                        child: card,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (savedAt case final time?)
            Align(alignment: Alignment.centerLeft, child: UpdatedAt(time)),
        ],
      );
    }
    return ListView(
      padding: scrollPadding(context),
      children: [
        chart,
        SectionLabel(l10n.payMonth(month)),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xxl),
            child: Text(
              l10n.payNone,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          )
        else
          Card(
            color: scheme.surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, p) in shown.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  _PaymentRow(
                    payment: p,
                    open: _open == '${p.id}${p.date}',
                    onTap: () => setState(
                      () => _open = _open == '${p.id}${p.date}'
                          ? null
                          : '${p.id}${p.date}',
                    ),
                  ),
                ],
              ],
            ),
          ),
        SectionLabel(l10n.incomeTitle),
        if (incomes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xxl),
            child: Text(
              l10n.incomeNone,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        for (final card in incomes)
          Padding(
            padding: const EdgeInsets.only(bottom: rowGap),
            child: card,
          ),
        if (savedAt case final time?) UpdatedAt(time),
      ],
    );
  }
}

/// The year's total over a bar per month; tapping a bar picks the month.
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.total,
    required this.months,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final int total;

  /// Amounts for January to the last month shown.
  final List<int> months;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.lilac;
    final light = Theme.of(context).brightness == Brightness.light;
    final top = months.fold(0, (a, b) => b > a ? b : a);
    if (desktopUi(context)) return _desk(context, top);
    return ToneBlock(
      tone: tone,
      radius: Corners.card,
      padding: cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          Text(
            _show(total),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, amount) in months.indexed) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(i + 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (i + 1 == selected && amount > 0)
                            FittedBox(
                              child: Text(
                                _show(amount),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutQuart,
                            height: top == 0 ? 4 : 4 + 96 * amount / top,
                            decoration: BoxDecoration(
                              color: i + 1 == selected
                                  ? tone.strong
                                  : Colors.white.withValues(
                                      alpha: light ? 0.55 : 0.14,
                                    ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                                bottom: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: tone.ink.withValues(
                                  alpha: i + 1 == selected ? 1 : 0.7,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// design/round-25 payment: a bordered box, the year's total at the
  /// right, thin bars over a rule with the chosen month lit.
  Widget _desk(BuildContext context, int top) {
    final scheme = Theme.of(context).colorScheme;
    final sun = context.tones.sun.strong;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                _show(total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 110,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, amount) in months.indexed)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(i + 1),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 30,
                          height: amount == 0 || top == 0
                              ? 2
                              : 110 * amount / top,
                          decoration: BoxDecoration(
                            color: amount == 0
                                ? scheme.outline
                                : i + 1 == selected
                                ? sun
                                : sun.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(
                              amount == 0 ? 1 : 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var m = 1; m <= months.length; m++)
                Expanded(
                  child: Text(
                    '$m',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: m == selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, required this.open, this.onTap});

  final Payment payment;
  final bool open;

  /// Opens or closes the details; null on a desktop, where they show.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final p = payment;
    final muted = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    if (desktopUi(context)) {
      // design/round-25 payment: the case and account under the title.
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.note.isEmpty ? p.unit : p.note,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    [
                      '${l10n.payCase} ${p.id}',
                      if (p.handler.isNotEmpty)
                        '${l10n.payHandler} ${p.handler}',
                    ].join('・'),
                    style: muted,
                  ),
                  if (p.account.isNotEmpty || p.invoice.isNotEmpty)
                    Text(
                      [
                        if (p.account.isNotEmpty)
                          '${l10n.payAccount} ${_masked(p.account)}',
                        if (p.invoice.isNotEmpty)
                          '${l10n.payInvoice} ${p.invoice}',
                      ].join('・'),
                      style: muted,
                    ),
                ],
              ),
            ),
            const SizedBox(width: Space.m),
            Text(
              _show(p.amount),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.l,
          vertical: Space.m,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.note.isEmpty ? p.unit : p.note,
                        maxLines: open ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.date.month}/${p.date.day}・${p.unit}',
                        style: muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _show(p.amount),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (p.status.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      StatusPill(tone: context.tones.mint, label: p.status),
                    ],
                  ],
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutQuart,
              alignment: Alignment.topCenter,
              child: open
                  ? Padding(
                      padding: const EdgeInsets.only(top: Space.m),
                      child: Text(
                        [
                          '${l10n.payCase} ${p.id}',
                          if (p.handler.isNotEmpty)
                            '${l10n.payHandler} ${p.handler}（${p.unit}）',
                          if (p.account.isNotEmpty)
                            '${l10n.payAccount} ${_masked(p.account)}',
                          if (p.invoice.isNotEmpty)
                            '${l10n.payInvoice} ${p.invoice}',
                        ].join('\n'),
                        style: muted.copyWith(height: 1.6),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeCard extends StatelessWidget {
  const _IncomeCard({
    required this.year,
    required this.income,
    required this.onOpen,
  });

  final int year;
  final Income income;
  final void Function(String url, String title, String file) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final i = income;
    void open(String path, String key, String title) => onOpen(
      '$_api/$path/generatePDF?year=$year&incoming_no=${Uri.encodeQueryComponent(i.format)}'
          '&$key=${Uri.encodeQueryComponent(i.payee)}',
      title,
      '$year-${i.format}-$path',
    );
    if (desktopUi(context)) return _desk(context, open);
    Widget figure(String label, int value) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.m,
          vertical: Space.s,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(Corners.small),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: scheme.onSurfaceVariant,
              ),
            ),
            FittedBox(
              child: Text(
                _show(value),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: cardPadding,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tones.sun.fill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    i.format,
                    style: TextStyle(
                      color: tones.sun.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatNames[i.format] ?? i.format,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        l10n.incomeYear(year),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.incomeNet,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _show(i.net),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                figure(l10n.incomeGross, i.gross),
                const SizedBox(width: 6),
                figure(l10n.incomeTax, i.tax),
                const SizedBox(width: 6),
                figure(l10n.incomePension, i.pension),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () =>
                        open('taxDetail', 'proCd', l10n.incomeDetail),
                    child: Text(l10n.incomeDetail),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () =>
                        open('tax', 'pro_cd', l10n.incomeWithholding),
                    child: Text(l10n.incomeWithholding),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// design/round-25 payment: the year's net large, its parts as lines,
  /// and the two statements.
  Widget _desk(
    BuildContext context,
    void Function(String path, String key, String title) open,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final i = income;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            [
              l10n.incomeYear(year),
              _formatNames[i.format] ?? i.format,
            ].join('・'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _show(i.net),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            l10n.incomeNet,
            style: TextStyle(fontWeight: FontWeight.w700, color: muted),
          ),
          const SizedBox(height: Space.s),
          for (final (label, value) in [
            (l10n.incomeGross, i.gross),
            (l10n.incomeTax, i.tax),
            (l10n.incomePension, i.pension),
          ])
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: muted,
                      ),
                    ),
                  ),
                  Text(
                    grouped(value),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              DeskButton(
                icon: Icons.description_outlined,
                label: l10n.incomeDetail,
                onPressed: () => open('taxDetail', 'proCd', l10n.incomeDetail),
              ),
              DeskButton(
                icon: Icons.print_outlined,
                label: l10n.incomeWithholding,
                onPressed: () => open('tax', 'pro_cd', l10n.incomeWithholding),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
