/// Markup to plain text: line breaks kept, tags dropped, entities decoded.
String plainText(String html) {
  final text = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|li|h\d)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAllMapped(RegExp(r'&(#x?[0-9a-fA-F]+|\w+);'), (m) {
        final e = m[1]!;
        if (e.startsWith('#x')) {
          return String.fromCharCode(int.parse(e.substring(2), radix: 16));
        }
        if (e.startsWith('#')) {
          return String.fromCharCode(int.parse(e.substring(1)));
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
