import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/repositories/ecourse_auth_repository.dart';
import 'package:tat_ccu/data/repositories/ecourse_repository.dart';
import 'package:tat_ccu/data/services/demo_data.dart';
import 'package:tat_ccu/data/services/library_data.dart';
import 'package:tat_ccu/data/services/payment_data.dart';

void main() {
  test('the demo client answers every read the screens make', () async {
    final repo = EcourseRepository(DemoMoodleClient());
    final courses = await repo.currentCourses();
    expect(courses, hasLength(5));
    expect(courses.every((c) => c.sessions.isNotEmpty), isTrue);
    expect(await repo.dueSoon(days: 14), isNotEmpty);
    await repo.monthEvents(DateTime.now());
    expect(await repo.unreadNotices(), 2);
    expect(await repo.notices(), isNotEmpty);
    expect(await repo.inbox(), isNotEmpty);
    expect(await repo.gradeOverview(), isNotEmpty);
    for (final c in courses) {
      final sections = await repo.contents(c.id);
      final modules = [for (final s in sections) ...s.modules];
      // Module ids are the cmids pages are found by: never shared.
      expect(modules.map((m) => m.id).toSet(), hasLength(modules.length));
      final posts = await repo.announcements(c.id);
      expect(posts, isNotEmpty);
      expect(await repo.discussionPosts(posts.first.id), isNotEmpty);
      await repo.gradeItems(c.id);
      for (final m in modules) {
        if (m.type == 'assign') await repo.assignment(c.id, m.instance);
        if (m.type == 'quiz') await repo.quiz(c.id, m.instance);
      }
    }
  });

  test('demo campus pages parse like the real ones', () {
    final year = DateTime.now().year - 1911;
    expect(paymentsOf(DemoCampus.payments(year)), isNotEmpty);
    expect(incomeOf(DemoCampus.payments(year)), isNotEmpty);
    expect(loansOf(DemoCampus.library()), hasLength(2));
    expect(holdsOf(DemoCampus.library()).single.ready, isTrue);
  });

  test('the demo account keeps the real sign-in to switch back to', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('support');
    addTearDown(() => dir.delete(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => dir.path,
        );
    FlutterSecureStorage.setMockInitialValues({'ecourse2_token': 'real'});
    final auth = EcourseAuthRepository(storage: const FlutterSecureStorage());
    await auth.load();
    expect((auth.isSignedIn, auth.isDemo), (true, false));

    await auth.setDemo(true);
    expect(auth.client(), isA<DemoMoodleClient>());

    // Signing out of the demo goes back to the real account.
    await auth.signOut(byUser: true);
    expect(
      (auth.isDemo, auth.token, auth.signedOutByUser),
      (false, 'real', false),
    );
  });
}
