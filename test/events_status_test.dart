import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/services/events_data.dart';

void main() {
  final now = DateTime(2026, 10, 19, 12);
  SchoolEvent event(Map<String, dynamic> j) =>
      eventOf({'id': '1', 'title': 't', ...j});

  test('a sign-up button means open, or waitlist once places are taken', () {
    expect(
      statusOf(event({'canSignUp': true, 'spots': [2, 20]}), now),
      EventStatus.open,
    );
    expect(
      statusOf(
        event({
          'canSignUp': true,
          'spots': [45, 45],
          'waitlist': [4, 5],
        }),
        now,
      ),
      EventStatus.waitlist,
    );
  });

  test('a hidden button is closed after the period, otherwise full', () {
    expect(
      statusOf(
        event({'spots': [48, 48], 'signUpEnd': '2026-10-18T09:00:00'}),
        now,
      ),
      EventStatus.closed,
    );
    expect(
      statusOf(
        event({'spots': [48, 48], 'signUpEnd': '2026-10-22T09:00:00'}),
        now,
      ),
      EventStatus.full,
    );
  });

  test('signed up wins; a linked form without places is external', () {
    expect(
      statusOf(event({'signedUp': true, 'canSignUp': false}), now),
      EventStatus.mine,
    );
    expect(
      statusOf(event({'link': 'https://forms.gle/x'}), now),
      EventStatus.external,
    );
    expect(statusOf(event({}), now), EventStatus.closed);
  });
}
