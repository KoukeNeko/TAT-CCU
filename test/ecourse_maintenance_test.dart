import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/services/ecourse_maintenance.dart';

void main() {
  test('stays on until a check says eCourse2 is back', () async {
    bool? down = true;
    final maintenance = EcourseMaintenance(check: () async => down);
    addTearDown(maintenance.dispose);

    // Not in maintenance: nothing to check.
    await maintenance.check();
    expect(maintenance.active, isFalse);

    maintenance.report();
    expect(maintenance.active, isTrue);
    expect(maintenance.nextCheck, isNotNull);

    await maintenance.check();
    expect(maintenance.active, isTrue);

    // Offline: an unreadable answer is not taken as back.
    down = null;
    await maintenance.check();
    expect(maintenance.active, isTrue);

    down = false;
    await maintenance.check();
    expect((maintenance.active, maintenance.nextCheck), (false, null));
  });
}
