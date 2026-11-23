import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/duplicate_group.dart';

class DuplicateFinderService {
  static const int _chunkSize = 65536; // 64 KB for fast pre-compare

  /// Scans [rootPath] and returns groups of files with identical content.
  Future<List<DuplicateGroup>> scan({
    required String rootPath,
    void Function(DuplicateScanProgress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final dir = Directory(rootPath);
    if (!dir.existsSync()) return [];

    // ── Phase 1: collect all files and group by size ──────────────────────
    final Map<int, List<String>> bySize = {};
    int fileCount = 0;

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (isCancelled?.call() == true) return [];
        if (entity is File) {
          try {
            final size = entity.statSync().size;
            if (size > 0) {
              bySize.putIfAbsent(size, () => []).add(entity.path);
              fileCount++;
              if (fileCount % 300 == 0) await Future.delayed(Duration.zero);
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('DuplicateFinderService.scan phase1 error: $e');
    }

    // Keep only sizes where there is more than one file
    final candidates = Map.fromEntries(
      bySize.entries.where((e) => e.value.length > 1),
    );

    // ── Phase 2: compare by first+last chunk hash ─────────────────────────
    final Map<String, List<String>> byChunkKey = {};
    int hashed = 0;
    final totalToHash = candidates.values.fold(0, (s, l) => s + l.length);

    for (final entry in candidates.entries) {
      if (isCancelled?.call() == true) return [];
      final size  = entry.key;
      final paths = entry.value;

      for (final path in paths) {
        if (isCancelled?.call() == true) return [];
        try {
          final key = await _chunkKey(path, size);
          byChunkKey.putIfAbsent(key, () => []).add(path);
          hashed++;
          if (hashed % 50 == 0) {
            onProgress?.call(DuplicateScanProgress(
              currentPath: path,
              filesHashed: hashed,
              totalFiles: totalToHash,
            ));
            await Future.delayed(Duration.zero);
          }
        } catch (_) {}
      }
    }

    // Keep only chunk-key groups with >1 file
    final chunkGroups = Map.fromEntries(
      byChunkKey.entries.where((e) => e.value.length > 1),
    );

    // ── Phase 3: full byte comparison within each chunk-match group ────────
    final List<DuplicateGroup> groups = [];

    for (final entry in chunkGroups.entries) {
      if (isCancelled?.call() == true) return [];
      final paths = entry.value;
      // Build sub-groups by full content
      final subGroups = await _fullContentGroups(paths);
      for (final sg in subGroups) {
        if (sg.length > 1) {
          final size = File(sg.first).statSync().size;
          groups.add(DuplicateGroup(paths: sg, sizeBytes: size));
        }
      }
    }

    // Sort: largest wasted space first
    groups.sort((a, b) => b.wastedBytes.compareTo(a.wastedBytes));
    return groups;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Computes a quick key from size + first chunk + last chunk.
  Future<String> _chunkKey(String path, int size) async {
    final f    = File(path);
    final raf  = await f.open();
    try {
      final first = await raf.read(_chunkSize.clamp(0, size));
      int lastStart = size - _chunkSize;
      Uint8List last;
      if (lastStart > _chunkSize) {
        await raf.setPosition(lastStart);
        last = await raf.read(_chunkSize);
      } else {
        last = first;
      }
      return '$size-${_fnv(first)}-${_fnv(last)}';
    } finally {
      await raf.close();
    }
  }

  int _fnv(Uint8List bytes) {
    int hash = 0xcbf29ce484222325;
    for (final b in bytes) {
      hash ^= b;
      // Dart ints are 64-bit signed; keep lower 63 bits to avoid overflow
      hash = (hash * 0x100000001b3) & 0x7FFFFFFFFFFFFFFF;
    }
    return hash;
  }

  /// Groups [paths] by full byte-for-byte equality.
  Future<List<List<String>>> _fullContentGroups(List<String> paths) async {
    final List<List<String>> result = [];
    final used = List.filled(paths.length, false);

    for (int i = 0; i < paths.length; i++) {
      if (used[i]) continue;
      final group = [paths[i]];
      used[i] = true;
      for (int j = i + 1; j < paths.length; j++) {
        if (used[j]) continue;
        try {
          if (await _filesEqual(paths[i], paths[j])) {
            group.add(paths[j]);
            used[j] = true;
          }
        } catch (_) {}
      }
      result.add(group);
    }
    return result;
  }

  Future<bool> _filesEqual(String pathA, String pathB) async {
    final a = File(pathA);
    final b = File(pathB);
    final sa = a.statSync().size;
    final sb = b.statSync().size;
    if (sa != sb) return false;

    final ra = await a.open();
    final rb = await b.open();
    try {
      while (true) {
        final ba = await ra.read(_chunkSize);
        final bb = await rb.read(_chunkSize);
        if (ba.length != bb.length) return false;
        if (ba.isEmpty) return true;
        for (int i = 0; i < ba.length; i++) {
          if (ba[i] != bb[i]) return false;
        }
      }
    } finally {
      await ra.close();
      await rb.close();
    }
  }

  /// Shows a Windows folder picker dialog.
  Future<String?> pickFolder() async {
    try {
      final r = await Process.run('powershell.exe', [
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command',
        r'''
Add-Type -AssemblyName System.Windows.Forms
$dlg = New-Object System.Windows.Forms.FolderBrowserDialog
$dlg.Description = "Select folder to scan for duplicates"
$dlg.ShowNewFolderButton = $false
if ($dlg.ShowDialog() -eq "OK") { Write-Output $dlg.SelectedPath }
''',
      ]);
      final out = r.stdout.toString().trim();
      return out.isNotEmpty ? out : null;
    } catch (_) {
      return null;
    }
  }
}
