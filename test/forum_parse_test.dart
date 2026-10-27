import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tat_ccu/data/repositories/ecourse_repository.dart';
import 'package:tat_ccu/data/services/moodle_client.dart';

EcourseRepository _repo(Object answer) => EcourseRepository(
  MoodleClient(
    siteUrl: Uri.parse('https://example.test/'),
    token: 't',
    newHttpClient: () => MockClient(
      (_) async => http.Response.bytes(utf8.encode(jsonEncode(answer)), 200),
    ),
  ),
);

void main() {
  test('discussions use the discussion id, not the first post id', () async {
    final list = await _repo({
      'discussions': [
        {
          'id': 900,
          'discussion': 42,
          'name': '作業三說明補充',
          'subject': '作業三說明補充',
          'userfullname': '助教',
          'created': 1760000000,
          'timemodified': 1760500000,
          'message': '<p>請下載<b>新版</b></p>',
          'numreplies': 3,
          'pinned': true,
        },
      ],
    }).discussions(7);
    expect(list.single.id, 42);
    expect(list.single.body, '請下載新版');
    expect(list.single.replies, 3);
    expect(list.single.pinned, isTrue);
  });

  test('posts keep their parent and attachments', () async {
    final repo = _repo({
      'posts': [
        {
          'id': 1,
          'parentid': 0,
          'subject': '作業三說明補充',
          'message': '說明',
          'timecreated': 1760000000,
          'author': {'fullname': '助教'},
          'attachments': [
            {
              'filename': 'hw3.zip',
              'filesize': 2048,
              // A post's attachment says `url`, outside webservice/.
              'url': 'https://example.test/pluginfile.php/1/hw3.zip',
              'timemodified': 1760000000,
            },
          ],
        },
        {
          'id': 2,
          'parentid': 1,
          'subject': 'Re: 作業三說明補充',
          'message': '收到',
          'timecreated': 1760100000,
          'author': {'fullname': '同學'},
        },
      ],
    });
    final posts = await repo.discussionPosts(42);
    expect(posts.map((p) => p.parent), [0, 1]);
    expect(posts.first.attachments.single.name, 'hw3.zip');
    expect(
      repo.fileUrl(posts.first.attachments.single.url),
      'https://example.test/webservice/pluginfile.php/1/hw3.zip?token=t',
    );
    expect(posts.last.attachments, isEmpty);
    expect(posts.last.author, '同學');
  });
}
