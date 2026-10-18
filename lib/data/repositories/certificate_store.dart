import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// A saved 在學證明書 PDF. The school regenerates it on every request; the
/// print date decides which semester it proves.
typedef Certificate = ({File file, DateTime printedAt, int size});

/// Semester a date falls in, e.g. `115-1`: the first term runs August to
/// January, the second February to July (ROC year = AD − 1911).
String semesterOf(DateTime d) {
  final year = d.month >= 8 ? d.year - 1911 : d.year - 1912;
  final term = d.month >= 8 || d.month == 1 ? 1 : 2;
  return '$year-$term';
}

/// The certificate only proves enrolment for the semester it was printed in.
bool isCurrent(Certificate c, DateTime now) =>
    semesterOf(c.printedAt) == semesterOf(now);

/// Certificates kept in the app's documents folder so they open offline.
/// File names carry only the print time, not the student number.
class CertificateStore {
  Future<Directory> _dir() async {
    final dir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/certificates',
    );
    return dir.create(recursive: true);
  }

  /// Newest first.
  Future<List<Certificate>> list() async {
    final files = (await _dir()).listSync().whereType<File>().where(
      (f) => f.path.endsWith('.pdf'),
    );
    final out = <Certificate>[
      for (final f in files)
        if (_parse(f.uri.pathSegments.last) case final printed?)
          (file: f, printedAt: printed, size: f.lengthSync()),
    ]..sort((a, b) => b.printedAt.compareTo(a.printedAt));
    return out;
  }

  /// Rejects anything that is not a PDF, such as a sign-in page served in
  /// its place when the session has expired.
  Future<Certificate> save(Uint8List bytes, DateTime printedAt) async {
    if (bytes.length < 5 ||
        String.fromCharCodes(bytes.sublist(0, 5)) != '%PDF-') {
      throw const FormatException('學校回傳的不是 PDF');
    }
    final file = File('${(await _dir()).path}/${_name(printedAt)}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return (file: file, printedAt: printedAt, size: bytes.length);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _name(DateTime d) =>
      '${d.year}${_two(d.month)}${_two(d.day)}-${_two(d.hour)}${_two(d.minute)}${_two(d.second)}';

  static DateTime? _parse(String name) {
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})\.pdf$')
        .firstMatch(name);
    if (m == null) return null;
    final v = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
    return DateTime(v[0], v[1], v[2], v[3], v[4], v[5]);
  }
}
