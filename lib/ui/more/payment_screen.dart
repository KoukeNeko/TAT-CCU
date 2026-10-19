import 'package:flutter/material.dart';

import '../../data/repositories/campus_cache.dart';
import '../../l10n/l10n.dart';
import '../core/campus_session.dart';
import '../core/campus_web_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'portal_screen.dart';

const _host = 'www026197.ccu.edu.tw';
const _api = 'https://$_host/gensys/site/general';

/// 付款及所得查詢 serves JSON as `{status_code, msg, data}` (0 is success;
/// a refusal says 無權限！ in `msg`), with money as "$1,234" and dates in
/// the ROC calendar (research_notes/…/payment_income_probe.md).
String _read(int year) =>
    '''
(async () => {
  const get = async path => {
    const j = await (await fetch('/gensys/site/general/' + path, { credentials: 'same-origin' })).json();
    if (j.status_code !== 0) throw new Error(j.msg || path);
    return j.data || {};
  };
  const range = 'start_date=' + encodeURIComponent('$year/01/01') + '&end_date=' + encodeURIComponent('$year/12/31');
  const rows = [];
  for (let page = 1, pages = 1; page <= pages && page <= 50; page++) {
    const d = await get('loanPayment/query?' + range + '&company_no=&page=' + page + '&change_page=0');
    pages = d.page_amount || 1;
    rows.push(...(d.rows || []));
  }
  const page = await (await fetch('/gensys/site/general/taxDetail/index', { credentials: 'same-origin' })).text();
  const years = [...new DOMParser().parseFromString(page, 'text/html').querySelectorAll('#qry_year option')]
    .map(o => o.value).filter(Boolean);
  const income = {};
  for (const y of years) income[y] = (await get('taxDetail/query?year=' + y)).tax_summary || [];
  Campus.postMessage(JSON.stringify({ year: $year, rows, years, income }));
})().catch(e => Campus.postMessage(JSON.stringify({ error: String(e) })));
''';

int _money(Object? v) =>
    int.tryParse('${v ?? ''}'.replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;

String _show(int n) =>
    '\$${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

/// "115/10/05" → 2026-10-05.
DateTime? _rocDate(Object? v) {
  final m = RegExp(r'^(\d{2,3})/(\d{1,2})/(\d{1,2})$').firstMatch('$v'.trim());
  if (m == null) return null;
  return DateTime(int.parse(m[1]!) + 1911, int.parse(m[2]!), int.parse(m[3]!));
}

typedef Payment = ({
  String id,
  DateTime date,
  int amount,
  String status,
  String account,
  String invoice,
  String handler,
  String unit,
  String note,
});

typedef Income = ({
  String format,
  String payee,
  int gross,
  int tax,
  int net,
  int pension,
});

/// Payments with a readable date, newest first; the same case and serial
/// listed twice by paging counts once.
List<Payment> paymentsOf(Map<String, dynamic> json) {
  final seen = <String>{};
  final out = <Payment>[];
  for (final r in (json['rows'] as List? ?? const []).whereType<Map>()) {
    final date = _rocDate(r['pay_date']);
    final id = '${r['expreg_no']}-${r['expreg_seri_cd']}';
    if (date == null || !seen.add(id)) continue;
    out.add((
      id: '${r['expreg_no'] ?? ''}',
      date: date,
      amount: _money(r['pay_amt']),
      status: '${r['reg_status_name'] ?? ''}',
      account: '${r['bank_acc_no'] ?? ''}',
      invoice: '${r['invoice_no'] ?? ''}',
      handler: '${r['c_name'] ?? ''}',
      unit: '${r['unit_name'] ?? ''}',
      note: '${r['purp_note'] ?? ''}',
    ));
  }
  return out..sort((a, b) => b.date.compareTo(a.date));
}

Map<int, List<Income>> incomeOf(Map<String, dynamic> json) => {
  for (final MapEntry(:key, :value)
      in (json['income'] as Map? ?? const {}).entries)
    ?int.tryParse('$key'): [
      for (final s in (value as List).whereType<Map>())
        (
          format: '${s['incoming_no'] ?? ''}',
          payee: '${s['pro_cd'] ?? ''}',
          gross: _money(s['in_amt_total']),
          tax: _money(s['tax_amt_total']),
          net: _money(s['net_amt_total']),
          pension: _money(s['labor_save_amt_total']),
        ),
    ],
};

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

class _PaymentScreenState extends State<PaymentScreen> {
  final _session = GlobalKey<CampusSessionState>();
  final _yearKey = GlobalKey();
  var _year = DateTime.now().year - 1911;
  Map<String, dynamic>? _json;
  DateTime? _savedAt;
  String? _error;
  int? _month;
  String? _open;

  @override
  void initState() {
    super.initState();
    CampusCache.read(PaymentScreen.cacheKey).then((cached) {
      if (!mounted) return;
      if (cached != null && cached.json['year'] == _year) {
        setState(() {
          _json = cached.json;
          _savedAt = cached.savedAt;
        });
      }
      _session.currentState?.reload();
    });
  }

  Future<void> _received(Map<String, dynamic> json) async {
    if (json['error'] != null) {
      setState(() => _error = '${json['error']}');
      return;
    }
    final savedAt = await CampusCache.write(PaymentScreen.cacheKey, json);
    if (!mounted) return;
    setState(() {
      _error = null;
      _json = json;
      _savedAt = savedAt;
      _month = null;
    });
  }

  Future<void> _pickYear() async {
    final box = _yearKey.currentContext!.findRenderObject()! as RenderBox;
    final now = DateTime.now().year - 1911;
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
      _json = null;
      _month = null;
    });
    _session.currentState?.reload();
  }

  Future<void> _reload() async {
    setState(() => _error = null);
    await _session.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final json = _json;
    return CampusSession(
      key: _session,
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
      script: () => _read(_year),
      onMessage: _received,
      child: _error != null
          ? CampusError(message: _error!, onRetry: _reload)
          : json == null
          ? null
          : Builder(
              builder: (context) => RefreshIndicator(
                edgeOffset: MediaQuery.paddingOf(context).top,
                onRefresh: () async => _session.currentState?.refresh(),
                child: _body(context, json),
              ),
            ),
    );
  }

  Widget _body(BuildContext context, Map<String, dynamic> json) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final payments = paymentsOf(json);
    final income = incomeOf(json);
    final now = DateTime.now();
    final lastMonth = _year == now.year - 1911 ? now.month : 12;
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
    return ListView(
      padding: scrollPadding(context),
      children: [
        _ChartCard(
          title: l10n.payReceived(_year, payments.length),
          total: payments.fold(0, (sum, p) => sum + p.amount),
          months: byMonth.sublist(0, lastMonth),
          selected: month,
          onSelect: (m) => setState(() {
            _month = m;
            _open = null;
          }),
        ),
        SectionLabel(l10n.payMonth(month)),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
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
        if (income.values.every((list) => list.isEmpty))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.incomeNone,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        for (final MapEntry(key: year, value: list)
            in (income.entries.toList()..sort((a, b) => b.key - a.key)))
          for (final item in list)
            Padding(
              padding: const EdgeInsets.only(bottom: rowGap),
              child: _IncomeCard(year: year, income: item),
            ),
        if (_savedAt case final time?) UpdatedAt(time),
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
    return ToneBlock(
      tone: tone,
      radius: Corners.card,
      padding: const EdgeInsets.all(16),
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
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.open,
    required this.onTap,
  });

  final Payment payment;
  final bool open;
  final VoidCallback onTap;

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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      padding: const EdgeInsets.only(top: 10),
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
  const _IncomeCard({required this.year, required this.income});

  final int year;
  final Income income;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final i = income;
    void open(String path, String key, String title) => openCampusPage(
      context,
      '$_api/$path/generatePDF?year=$year&incoming_no=${Uri.encodeQueryComponent(i.format)}'
      '&$key=${Uri.encodeQueryComponent(i.payee)}',
      title,
    );
    Widget figure(String label, int value) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
        padding: const EdgeInsets.all(14),
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
}
