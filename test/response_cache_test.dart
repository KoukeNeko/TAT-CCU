import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/services/response_cache.dart';

void main() {
  // A write cut short leaves a broken file; it reads as never answered, so
  // the request goes to eCourse2 instead of failing every time.
  test('a damaged answer reads as missing', () async {
    final dir = await Directory.systemTemp.createTemp('cache');
    addTearDown(() => dir.delete(recursive: true));
    final cache = ResponseCache('token', dir: dir);
    await cache.write('k', {'userid': 1});
    expect(await cache.read('k'), {'userid': 1});
    final file = dir.listSync(recursive: true).whereType<File>().single;
    await file.writeAsString('{"userid": ');
    expect(await cache.read('k'), isNull);
  });
}
