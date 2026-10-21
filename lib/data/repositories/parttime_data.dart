/// 學習暨勞僱時數登錄 (www026190.ccu.edu.tw/parttime), alpha: the app shows
/// its five functions on made-up data and never calls the school's site,
/// whose rows have not been seen yet (research_notes/…/parttime_hours_probe.md).
/// The rules below are the site's own notice.
library;

import 'package:clock/clock.dart' as clk;
import 'package:flutter/foundation.dart';

/// Hours a week, holidays excluded.
const weeklyLimit = 20;

/// Older entries count as waived, so the date picker stops there.
const loggableDays = 90;

enum HoursState { unconfirmed, confirmed, paid }

typedef HoursEntry = ({
  String id,
  DateTime date,
  String unit,

  /// Minutes from midnight.
  int start,
  int end,
  String work,
  HoursState state,
  String? batch,
});

double hoursOf(HoursEntry e) => (e.end - e.start) / 60;

bool isHoliday(DateTime d) =>
    d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Monday of [d]'s week.
DateTime weekOf(DateTime d) => _day(d).subtract(Duration(days: d.weekday - 1));

/// Hours counted toward [weeklyLimit] in [week]: holidays left out.
double weekHours(Iterable<HoursEntry> entries, DateTime week) => entries
    .where((e) => weekOf(e.date) == week && !isHoliday(e.date))
    .fold(0, (sum, e) => sum + hoursOf(e));

/// The first entry on the same day whose time crosses [e]'s, if any.
HoursEntry? overlapOf(HoursEntry e, Iterable<HoursEntry> others) => others
    .where(
      (o) => _day(o.date) == _day(e.date) && o.start < e.end && e.start < o.end,
    )
    .firstOrNull;

typedef PayCase = ({
  String number,
  String kind,
  String summary,
  int year,
  int month,
  int wage,
  int employerLabor,
  int employerPension,
  int employerHealth,
  int employerSupplement,
  int tax,
  int labor,
  int pension,
  int health,
  int supplement,
  int otherDeduction,
});

int grossOf(PayCase c) =>
    c.wage +
    c.employerLabor +
    c.employerPension +
    c.employerHealth +
    c.employerSupplement;

int deductionsOf(PayCase c) =>
    c.tax + c.labor + c.pension + c.health + c.supplement + c.otherDeduction;

int netOf(PayCase c) => c.wage - deductionsOf(c);

const myUnits = ['圖書館', '資訊工程學系'];

/// A sample of the site's 311 units.
const allUnits = [
  '校長室',
  '副校長室',
  '校務研究辦公室',
  '圖書館',
  '資訊處',
  '學生事務處',
  '教務處',
  '中國文學系',
  '外國語文學系',
  '歷史學系',
  '數學系',
  '物理學系',
  '資訊工程學系',
  '電機工程學系',
  '機械工程學系',
  '經濟學系',
  '企業管理學系',
];

/// The alpha's entries and pay: none, as the student's real account has
/// none yet, or made-up ones in demo mode. Kept for the app's run.
class HoursStore extends ChangeNotifier {
  HoursStore._() {
    final now = clk.clock.now();
    final today = _day(now);
    HoursEntry entry(
      int daysAgo,
      String unit,
      int start,
      int end,
      String work,
      HoursState state, [
      String? batch,
    ]) => (
      id: '${_next++}',
      date: today.subtract(Duration(days: daysAgo)),
      unit: unit,
      start: start * 60,
      end: end * 60,
      work: work,
      state: state,
      batch: batch,
    );
    _demoEntries = [
      entry(2, '圖書館', 9, 12, '流通櫃台值班', HoursState.unconfirmed),
      entry(3, '圖書館', 13, 17, '書庫整架', HoursState.confirmed, '1150016'),
      entry(5, '資訊工程學系', 10, 12, '計算機概論助教課', HoursState.confirmed, '1150015'),
      entry(11, '圖書館', 9, 12, '流通櫃台值班', HoursState.paid, '1150009'),
      entry(16, '圖書館', 13, 16, '新書上架', HoursState.paid, '1150009'),
      entry(38, '圖書館', 9, 12, '流通櫃台值班', HoursState.paid, '1150002'),
    ];
    final last = DateTime(now.year, now.month - 1);
    _demoPay = [
      (
        number:
            '${last.year - 1911}${last.month.toString().padLeft(2, '0')}30A12',
        kind: '學習型助學金',
        summary: '圖書館',
        year: last.year - 1911,
        month: last.month,
        wage: 4440,
        employerLabor: 116,
        employerPension: 88,
        employerHealth: 0,
        employerSupplement: 0,
        tax: 0,
        labor: 226,
        pension: 0,
        health: 0,
        supplement: 0,
        otherDeduction: 0,
      ),
      (
        number:
            '${last.year - 1911}${last.month.toString().padLeft(2, '0')}30B07',
        kind: '學習型助學金',
        summary: '資訊工程學系',
        year: last.year - 1911,
        month: last.month,
        wage: 1850,
        employerLabor: 48,
        employerPension: 37,
        employerHealth: 0,
        employerSupplement: 0,
        tax: 0,
        labor: 74,
        pension: 0,
        health: 0,
        supplement: 0,
        otherDeduction: 0,
      ),
    ];
  }

  static final instance = HoursStore._();
  static var _next = 1;

  late List<HoursEntry> _demoEntries;
  late final List<PayCase> _demoPay;
  var _entries = <HoursEntry>[];
  var _demo = false;

  List<HoursEntry> get entries => _demo ? _demoEntries : _entries;
  List<PayCase> get pay => _demo ? _demoPay : const [];

  set demo(bool on) {
    if (on == _demo) return;
    _demo = on;
    notifyListeners();
  }

  void _set(List<HoursEntry> list) {
    if (_demo) {
      _demoEntries = list;
    } else {
      _entries = list;
    }
    notifyListeners();
  }

  /// New entries wait for the unit's supervisor to confirm them.
  void save(List<HoursEntry> staged) {
    _set([
      for (final e in staged)
        (
          id: '${_next++}',
          date: e.date,
          unit: e.unit,
          start: e.start,
          end: e.end,
          work: e.work,
          state: HoursState.unconfirmed,
          batch: null,
        ),
      ...entries,
    ]);
  }

  void delete(Set<String> ids) => _set([
    for (final e in entries)
      if (!ids.contains(e.id)) e,
  ]);
}
