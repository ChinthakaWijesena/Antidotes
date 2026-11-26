import 'dart:convert';
import 'dart:io';
import '../models/game_model.dart';

/// Handles persistent local storage of registered games in `%APPDATA%\Antidotes\game_booster.json`.
class GameStorageService {
  File _getStorageFile() {
    final appData = Platform.environment['APPDATA'] ??
        Directory.systemTemp.path;
    final dir = Directory('$appData\\Antidotes');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return File('${dir.path}\\game_booster.json');
  }

  /// Loads saved games from disk. Returns empty list if no file exists.
  Future<List<Game>> loadGames() async {
    try {
      final file = _getStorageFile();
      if (!await file.exists()) {
        return [];
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];

      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Game.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Persists the games list to disk in JSON format.
  Future<void> saveGames(List<Game> games) async {
    try {
      final file = _getStorageFile();
      final data = games.map((g) => g.toJson()).toList();
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    } catch (_) {
      // Ignore or log error
    }
  }
}
