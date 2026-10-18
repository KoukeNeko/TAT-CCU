import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Favorite and recently opened campus systems, by portal `linkId`.
/// Stored on the device only.
class PortalPrefs extends ChangeNotifier {
  static const _favKey = 'portal_favorites';
  static const _recentKey = 'portal_recent';

  /// 選課、成績查詢、學生請假、My圖書館: the systems students open most.
  static const defaultFavorites = ['0075', '0007', '0064', '0003'];
  static const maxFavorites = 8;
  static const maxRecent = 6;

  List<String> favorites = defaultFavorites;
  List<String> recent = const [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    favorites = prefs.getStringList(_favKey) ?? defaultFavorites;
    recent = prefs.getStringList(_recentKey) ?? const [];
    notifyListeners();
  }

  Future<void> setFavorites(List<String> ids) async {
    favorites = ids.take(maxFavorites).toList();
    notifyListeners();
    await (await SharedPreferences.getInstance()).setStringList(
      _favKey,
      favorites,
    );
  }

  Future<void> opened(String id) async {
    recent = [id, ...recent.where((r) => r != id)].take(maxRecent).toList();
    notifyListeners();
    await (await SharedPreferences.getInstance()).setStringList(
      _recentKey,
      recent,
    );
  }
}
