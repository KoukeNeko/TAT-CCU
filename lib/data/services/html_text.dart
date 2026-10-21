import 'dart:convert';

/// Markup to plain text: line breaks kept, tags dropped, entities decoded.
String plainText(String html) {
  final text = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|li|h\d)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAllMapped(RegExp(r'&(#x?[0-9a-fA-F]+|\w+);'), (m) {
        final e = m[1]!;
        if (e.startsWith('#')) {
          final code = e.startsWith('#x')
              ? int.tryParse(e.substring(2), radix: 16)
              : int.tryParse(e.substring(1));
          // A malformed or out-of-range reference stays as written.
          return code == null || code > 0x10FFFF
              ? m[0]!
              : String.fromCharCode(code);
        }
        return const {
              'amp': '&',
              'lt': '<',
              'gt': '>',
              'quot': '"',
              'apos': "'",
              'nbsp': ' ',
            }[e] ??
            m[0]!;
      });
  return text
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'[ \t\u00a0]+'), ' ').trim())
      .where((l) => l.isNotEmpty)
      .join('\n');
}

/// Typed text as HTML for eCourse2 posts and mail: escaped, line breaks kept.
String textAsHtml(String text) =>
    const HtmlEscape().convert(text).replaceAll('\n', '<br>');
