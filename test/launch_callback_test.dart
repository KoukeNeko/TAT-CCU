import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/repositories/ecourse_auth_repository.dart';

void main() {
  // What eCourse2 sends back: base64 of md5(site + passport):::token.
  String callback(String signature, String token) =>
      'tatccu://token=${base64.encode(utf8.encode('$signature:::$token'))}';
  final signed = md5.convert(utf8.encode('${eCourse2Url}p1')).toString();

  test('a callback signed for this passport gives its token', () {
    expect(parseLaunchCallback(callback(signed, 'abc'), 'p1'), 'abc');
  });

  // Only the sign-in the app started may plant a token.
  test('a callback for another passport is refused', () {
    expect(
      () => parseLaunchCallback(callback(signed, 'abc'), 'p2'),
      throwsFormatException,
    );
  });

  test('a callback without a token is refused', () {
    expect(
      () => parseLaunchCallback('tatccu://nothing', 'p1'),
      throwsFormatException,
    );
  });
}
