import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/services/primo_client.dart';

void main() {
  test('a pnxs doc becomes a record with its copies', () {
    final record = LibraryRecord.fromDoc({
      'pnx': {
        'control': {
          'recordid': ['alma990054103030107979'],
        },
        'display': {
          'title': ['Machine learning / '],
          'creator': [r'Mitchell, Thomas M$$QMitchell, Thomas M'],
          'creationdate': ['c1997'],
          'type': ['book'],
          'identifier': [r'$$CISBN$$V9780070428072'],
          'subject': ['Machine learning'],
        },
      },
      'delivery': {
        'availability': ['available_in_library'],
        'deliveryCategory': ['Alma-P'],
        'holding': [
          {
            'mainLocation': '非開放書庫區',
            'subLocation': '地下樓密集書庫',
            'callNumber': '(Q325.5 M681)',
            'availabilityStatus': 'available',
          },
        ],
      },
    });
    expect(record.title, 'Machine learning');
    expect(record.author, 'Mitchell, Thomas M');
    expect(record.isbn, '9780070428072');
    expect(record.availability, Availability.onShelf);
    expect(record.holdings.single.location, '非開放書庫區 地下樓密集書庫');
    expect(record.holdings.single.callNumber, 'Q325.5 M681');
    expect(record.url, contains('docid=alma990054103030107979'));
  });

  test('online and checked-out availability', () {
    LibraryRecord doc(List<String> av, String category) =>
        LibraryRecord.fromDoc({
          'pnx': {'display': <String, dynamic>{}},
          'delivery': {
            'availability': av,
            'deliveryCategory': [category],
          },
        });
    expect(doc(['not_restricted'], 'Alma-E').availability, Availability.online);
    expect(doc(['unavailable'], 'Alma-P').availability, Availability.out);
  });

  test('the collection tree keeps ids and which parts hold books', () {
    final tree = LibraryCollection.fromJson({
      'name': '新進圖書',
      'pid': {'value': '1'},
      'items': 'N',
      'collections': {
        'collection': [
          {
            'name': '2026年',
            'pid': {'value': '2'},
            'items': 'N',
            'collections': {
              'collection': {
                'name': '2026年10月',
                'pid': {'value': '3'},
                'items': 'Y',
              },
            },
          },
        ],
      },
    });
    final month = tree.children.single.children.single;
    expect((month.id, month.name, month.hasItems), ('3', '2026年10月', true));
  });
}
