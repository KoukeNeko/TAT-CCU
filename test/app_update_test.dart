import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tat_ccu/data/services/app_update.dart';

void main() {
  test('versions compare by number, not text', () {
    expect(isNewer('0.1.10', '0.1.9'), isTrue);
    expect(isNewer('0.2.0', '0.1.9'), isTrue);
    expect(isNewer('0.1.9', '0.1.9'), isFalse);
    expect(isNewer('0.1.8', '0.1.9'), isFalse);
    // A build number does not make a version newer.
    expect(isNewer('0.1.9+3', '0.1.9'), isFalse);
    expect(isNewer('1.0', '0.9.9'), isTrue);
  });

  test('release notes keep their items, not headings or gaps', () {
    expect(releaseLines('## 錯誤修正\n\n📶 宿網不再出錯。\n\n🔔 Windows：通知有圖示。\n'), [
      '📶 宿網不再出錯。',
      '🔔 Windows：通知有圖示。',
    ]);
  });

  test('the latest GitHub release gives its version, notes and page', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/repos/KoukeNeko/TAT-CCU/releases/latest');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'tag_name': 'v0.2.0',
            'html_url':
                'https://github.com/KoukeNeko/TAT-CCU/releases/tag/v0.2.0',
            'body': '## 新功能\n\n✨ 新的版本卡。\n',
          }),
        ),
        200,
      );
    });
    final release = await latestRelease(client: client);
    expect(release?.version, '0.2.0');
    expect(release?.notes, ['✨ 新的版本卡。']);
    expect(release?.source, 'GitHub');
  });

  test('a failed read is an error, not a missing release', () {
    final client = MockClient((_) async => http.Response('', 503));
    expect(latestRelease(client: client), throwsA(isA<http.ClientException>()));
  });
}
