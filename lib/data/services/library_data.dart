/// Loans and holds from the library's Primo account API.
library;

typedef Loan = ({
  String id,
  String title,
  String author,
  DateTime due,
  bool renewable,
});
typedef Hold = ({
  String id,
  String type,
  String title,
  String status,
  bool ready,
  String pickup,
  DateTime? until,
});

// shortcut: id, title, due date, renewable and the request fields come from
// Primo's own account code; author, pickup and the ready wording are still
// guesses until a real loan and hold are seen.

String _field(Map item, List<String> names) {
  final lower = {for (final e in item.entries) '${e.key}'.toLowerCase(): e};
  for (final n in names) {
    if (lower[n]?.value case final v? when '$v'.trim().isNotEmpty) {
      return '$v'.trim();
    }
  }
  return '';
}

/// Primo dates come as `yyyyMMdd`, ISO, or `M/d/yyyy`.
DateTime? _date(String s) {
  if (RegExp(r'^\d{8}').hasMatch(s)) {
    return DateTime(
      int.parse(s.substring(0, 4)),
      int.parse(s.substring(4, 6)),
      int.parse(s.substring(6, 8)),
    );
  }
  if (RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(s) case final m?) {
    return DateTime(int.parse(m[3]!), int.parse(m[1]!), int.parse(m[2]!));
  }
  final t = DateTime.tryParse(s);
  return t == null ? null : DateTime(t.year, t.month, t.day);
}

/// Loans sorted most urgent first; loans without a readable due date are
/// left out rather than shown as due at a wrong time.
List<Loan> loansOf(Map<String, dynamic> json) {
  final loans = <Loan>[
    for (final item in (json['loans'] as List? ?? const []).whereType<Map>())
      if (_date(_field(item, ['duedate', 'due_date'])) case final due?)
        (
          id: _field(item, ['loanid', 'id']),
          title: _field(item, ['title']),
          author: _field(item, ['author', 'creator']),
          due: due,
          // Primo marks a loan it will not renew with `N`.
          renewable: _field(item, ['renewable', 'renew']).toUpperCase() != 'N',
        ),
  ];
  return loans..sort((a, b) => a.due.compareTo(b.due));
}

List<Hold> holdsOf(Map<String, dynamic> json) => [
  for (final item in (json['holds'] as List? ?? const []).whereType<Map>())
    _holdOf(item),
];

Hold _holdOf(Map item) {
  final status = _field(item, ['requeststatus', 'status', 'request_status']);
  return (
    id: _field(item, ['requestid', 'request_id', 'id']),
    type: _field(item, ['requesttype', 'request_type']),
    title: _field(item, ['title']),
    status: status,
    ready: RegExp(
      r'hold ?shelf|ready|pickup|可取|待取',
      caseSensitive: false,
    ).hasMatch(status),
    pickup: _field(item, ['pickuplocation', 'pickup_location', 'pickup']),
    until: _date(
      _field(item, ['expirydate', 'holdshelfexpirydate', 'expiry_date']),
    ),
  );
}
