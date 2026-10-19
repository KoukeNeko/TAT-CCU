import 'dart:convert';

import 'package:http/http.dart' as http;

/// The library's Primo VE (資源探索). Searching, records and collections
/// are public: no sign-in, plain HTTP (research_notes/…/library_probe.md).
const primoHost = 'ccu.primo.exlibrisgroup.com';
const primoVid = '886CCU_INST:886CCU_INST';
const _inst = '886CCU_INST';

/// 主題館藏 → 新進圖書, split by year and then month.
const newBooksId = '81114712300007979';

enum PrimoKind { catalog, journal, database }

enum PrimoSort { rank, newest, title }

/// Resource types offered as a filter, by Primo's `facet_rtype` value.
enum PrimoType { books, journals, dissertations, videos }

enum Availability { onShelf, out, online, none }

typedef Holding = ({String location, String callNumber, Availability status});

class LibraryRecord {
  const LibraryRecord({
    required this.recordId,
    required this.title,
    required this.author,
    required this.year,
    required this.type,
    required this.publisher,
    required this.isbn,
    required this.subjects,
    required this.availability,
    required this.holdings,
  });

  /// e.g. `alma990054103030107979`.
  final String recordId;
  final String title, author, year, type, publisher, isbn;
  final List<String> subjects;
  final Availability availability;
  final List<Holding> holdings;

  /// Primo's own page for the record, for requests and sharing.
  String get url =>
      'https://$primoHost/discovery/fulldisplay?docid=$recordId'
      '&context=L&vid=$primoVid&lang=zh-tw';

  factory LibraryRecord.fromDoc(Map<String, dynamic> doc) {
    final pnx = doc['pnx'] as Map<String, dynamic>;
    final display = (pnx['display'] as Map?) ?? const {};
    String first(String key) {
      final v = display[key];
      // Primo appends `$$Q…` search keys to names.
      return v is List && v.isNotEmpty
          ? '${v.first}'.split(r'$$').first.trim()
          : '';
    }

    final delivery = (doc['delivery'] as Map?) ?? const {};
    final best = delivery['bestlocation'] as Map?;
    return LibraryRecord(
      recordId:
          '${((pnx['control'] as Map?)?['recordid'] as List?)?.first ?? ''}',
      title: first('title').replaceAll(RegExp(r'[\s:/]+$'), ''),
      author: first('creator').isNotEmpty
          ? first('creator')
          : first('contributor'),
      year: first('creationdate'),
      type: first('type'),
      publisher: first('publisher'),
      isbn:
          RegExp(r'\$\$CISBN\$\$V([\dXx-]+)')
              .firstMatch('${display['identifier'] ?? ''}')
              ?.group(1) ??
          '',
      subjects: [
        for (final s in (display['subject'] as List?) ?? const []) '$s',
      ],
      availability: _availability([
        for (final a in (delivery['availability'] as List?) ?? const []) '$a',
      ], '${delivery['deliveryCategory'] ?? ''}'),
      holdings: [
        for (final h in [
          ...?(delivery['holding'] as List?),
          if ((delivery['holding'] as List?)?.isEmpty ?? true) ?best,
        ].whereType<Map>())
          (
            location: [h['mainLocation'], h['subLocation']]
                .where((s) => s != null && '$s'.isNotEmpty && '$s' != '圖書館')
                .join(' '),
            callNumber: '${h['callNumber'] ?? ''}'
                .replaceAll(RegExp(r'[()]'), '')
                .trim(),
            status: _availability(['${h['availabilityStatus'] ?? ''}'], ''),
          ),
      ],
    );
  }
}

Availability _availability(List<String> values, String category) {
  if (values.any((v) => v.startsWith('available'))) return Availability.onShelf;
  if (category.contains('Alma-E') ||
      values.any((v) => v.contains('fulltext') || v == 'not_restricted')) {
    return Availability.online;
  }
  if (values.any((v) => v == 'unavailable' || v == 'check_holdings')) {
    return Availability.out;
  }
  return Availability.none;
}

typedef SearchPage = ({int total, List<LibraryRecord> records});

class LibraryCollection {
  const LibraryCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.hasItems,
    required this.children,
  });

  final String id, name, description;

  /// True when books sit directly in it; otherwise only [children] do.
  final bool hasItems;
  final List<LibraryCollection> children;

  /// This collection or one below it with [id].
  LibraryCollection? find(String id) {
    if (this.id == id) return this;
    for (final c in children) {
      if (c.find(id) case final found?) return found;
    }
    return null;
  }

  /// The parts that hold books, newest first as Primo orders them (新進圖書
  /// is year → month).
  List<LibraryCollection> get withItems => [
    if (hasItems) this,
    for (final c in children) ...c.withItems,
  ];

  factory LibraryCollection.fromJson(Map json) {
    final nested = (json['collections'] as Map?)?['collection'];
    return LibraryCollection(
      id: '${(json['pid'] as Map?)?['value'] ?? ''}',
      name: '${json['name'] ?? ''}',
      description: '${json['description'] ?? ''}',
      hasItems: json['items'] == 'Y',
      children: [
        for (final c in (nested is List ? nested : [?nested]).whereType<Map>())
          LibraryCollection.fromJson(c),
      ],
    );
  }
}

class PrimoClient {
  PrimoClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  static const _timeout = Duration(seconds: 30);
  final http.Client _http;

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query, {
    String? jwt,
  }) async {
    final uri = Uri.https(primoHost, '/primaws/rest$path', {
      'vid': primoVid,
      'lang': 'zh-tw',
      ...query,
    });
    final response = await _http
        .get(uri, headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'})
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('${response.statusCode}', uri);
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<SearchPage> _pnxs(Map<String, String> query) async {
    final json = await _get('/pub/pnxs', {
      'inst': _inst,
      'skipDelivery': 'N',
      'limit': '20',
      ...query,
    });
    return (
      total: ((json['info'] as Map?)?['total'] as num?)?.toInt() ?? 0,
      records: [
        for (final d
            in (json['docs'] as List? ?? const [])
                .whereType<Map<String, dynamic>>())
          LibraryRecord.fromDoc(d),
      ],
    );
  }

  Future<SearchPage> search(
    String text, {
    PrimoKind kind = PrimoKind.catalog,
    PrimoSort sort = PrimoSort.rank,
    bool onShelf = false,
    PrimoType? type,
    int? sinceYear,
    int offset = 0,
  }) {
    final include = [
      if (onShelf) 'facet_tlevel,exact,available_p',
      if (type != null) 'facet_rtype,exact,${type.name}',
      if (sinceYear != null)
        'facet_searchcreationdate,exact,[$sinceYear TO ${DateTime.now().year}]',
    ];
    return _pnxs({
      'q': 'any,contains,$text',
      'offset': '$offset',
      'sort': switch (sort) {
        PrimoSort.rank => 'rank',
        PrimoSort.newest => 'date_d',
        PrimoSort.title => 'title',
      },
      if (include.isNotEmpty) 'qInclude': include.join('|,|'),
      ...switch (kind) {
        PrimoKind.catalog => {
          'tab': 'LibraryCatalog',
          'scope': 'MyInstitution',
        },
        PrimoKind.journal => {
          'tab': 'jsearch_slot',
          'scope': 'MyInst_and_CI',
          'journals': 'any,$text',
        },
        PrimoKind.database => {
          'tab': 'jsearch_slot',
          'scope': 'MyInst_and_CI',
          'databases': 'any,$text',
        },
      },
    });
  }

  /// Books in a collection with `items: Y`.
  Future<SearchPage> collectionItems(String id, {int offset = 0}) => _pnxs({
    'q': 'cdparentid,exact,$id',
    'tab': 'Everything',
    'scope': 'browse_search',
    'isCDSearch': 'true',
    'offset': '$offset',
  });

  /// The collection tree. It sits behind the account API, but a guest
  /// token is enough.
  Future<List<LibraryCollection>> collections() async {
    final response = await _http
        .get(
          Uri.https(
            primoHost,
            '/primaws/rest/pub/institution/$_inst/guestJwt',
            {'isGuest': 'true', 'lang': 'zh-tw', 'viewId': primoVid},
          ),
        )
        .timeout(_timeout);
    final jwt = response.body.replaceAll('"', '');
    final json = await _get('/priv/myaccount/collection', {
      'inst': _inst,
      'userInst': _inst,
      'name': 'get_collections',
      'useCache': 'true',
      'ilsgEntityParams':
          'primo_user_institution,$_inst;ils_user_institution,$_inst',
    }, jwt: jwt);
    final list = ((json['data'] as Map?)?['collection'] as List?) ?? const [];
    return [
      for (final c in list.whereType<Map>()) LibraryCollection.fromJson(c),
    ];
  }
}
