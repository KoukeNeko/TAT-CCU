import 'dart:async';

import 'package:clock/clock.dart' as clk;
import 'package:flutter/foundation.dart';

import '../repositories/ecourse_auth_repository.dart';

/// eCourse2's maintenance mode as the app has seen it: switched on when a
/// request is refused for maintenance, then checked against the public
/// settings every [interval], and on coming back to the app, until it ends.
class EcourseMaintenance extends ChangeNotifier {
  EcourseMaintenance({Future<bool?> Function()? check})
    : _check = check ?? EcourseAuthRepository.siteInMaintenance;

  static final instance = EcourseMaintenance();

  static const interval = Duration(minutes: 2);

  final Future<bool?> Function() _check;
  Timer? _timer;

  bool get active => _active;
  var _active = false;

  bool get checking => _checking;
  var _checking = false;

  /// When the next check runs, while [active].
  DateTime? get nextCheck => _nextCheck;
  DateTime? _nextCheck;

  /// A request was refused for maintenance.
  void report() {
    if (_active) return;
    _active = true;
    _schedule();
    notifyListeners();
  }

  /// Checks now, while [active]; an unreadable answer counts as still down.
  Future<void> check() async {
    if (!_active || _checking) return;
    _timer?.cancel();
    _checking = true;
    notifyListeners();
    final down = await _check();
    _checking = false;
    if (down == false) {
      _active = false;
      _nextCheck = null;
    } else {
      _schedule();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _nextCheck = clk.clock.now().add(interval);
    _timer = Timer(interval, check);
  }
}
