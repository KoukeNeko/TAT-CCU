import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The More page's status tiles, by route. Stored on the device only.
class MoreTilesPrefs extends ChangeNotifier {
  static const _tilesKey = 'more_tiles';

  /// The More page's four status tiles.
  static const defaultTiles = [
    '/more/space',
    '/more/library',
    '/more/grades',
    '/more/leave',
  ];

  List<String> tiles = defaultTiles;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    tiles = prefs.getStringList(_tilesKey) ?? defaultTiles;
    notifyListeners();
  }

  Future<void> setTiles(List<String> paths) async {
    tiles = paths;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setStringList(
      _tilesKey,
      tiles,
    );
  }
}
