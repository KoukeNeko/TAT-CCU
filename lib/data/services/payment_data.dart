/// 付款及所得查詢 (www026197.ccu.edu.tw/gensys), read in a signed-in WebView.
library;

/// 付款及所得查詢 serves JSON as `{status_code, msg, data}` (0 is success;
/// a refusal says 無權限！ in `msg`), with money as "$1,234" and dates in
/// the ROC calendar (research_notes/…/payment_income_probe.md).
String readPayments(int year) =>
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
