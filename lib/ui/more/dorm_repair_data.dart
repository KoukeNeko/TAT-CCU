/// 宿舍維修申請系統 (www026186.ccu.edu.tw/dormrepair), alpha: the app shows
/// the site's form and request list on made-up data and never calls the
/// site, whose list has not been seen with a request in it yet
/// (research_notes/…/dorm_repair_probe.md).
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The only room forms the site accepts: 3316A (undergraduate), 1325, A301
/// and 5108-1 (graduate).
final roomPattern = RegExp(r'^(\d{4}[A-Z]|\d{4}|[A-Z]\d{3}|\d{4}-\d)$');

final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

typedef RepairRequest = ({
  DateTime date,
  String room,
  String email,
  String memo,
  bool needPresence,
});

/// The student's requests: none, as the real account has none, or made-up
/// ones in demo mode. Kept for the app's run.
class DormRepairStore extends ChangeNotifier {
  DormRepairStore._();

  static final instance = DormRepairStore._();

  late final _demoRequests = () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    RepairRequest r(int daysAgo, String memo) => (
      date: today.subtract(Duration(days: daysAgo)),
      room: '3316A',
      email: 'student@ccu.edu.tw',
      memo: memo,
      needPresence: false,
    );
    return [r(1, '冷氣不冷，出風口有異味'), r(17, '書桌檯燈閃爍'), r(28, '衣櫃門鎖卡住')];
  }();
  final _requests = <RepairRequest>[];
  var _demo = false;

  List<RepairRequest> get requests => _demo ? _demoRequests : _requests;

  set demo(bool on) {
    if (on == _demo) return;
    _demo = on;
    notifyListeners();
  }

  void submit(RepairRequest request) {
    requests.insert(0, request);
    notifyListeners();
  }
}

/// The room and email the student last sent, when asked to remember them.
class RepairContact {
  const RepairContact._();

  static const _roomKey = 'dorm_repair_room';
  static const _emailKey = 'dorm_repair_email';

  static Future<({String room, String email})?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final room = prefs.getString(_roomKey);
    final email = prefs.getString(_emailKey);
    return room == null || email == null ? null : (room: room, email: email);
  }

  /// Null forgets them.
  static Future<void> write(({String room, String email})? contact) async {
    final prefs = await SharedPreferences.getInstance();
    if (contact == null) {
      await (prefs.remove(_roomKey), prefs.remove(_emailKey)).wait;
    } else {
      await (
        prefs.setString(_roomKey, contact.room),
        prefs.setString(_emailKey, contact.email),
      ).wait;
    }
  }
}
