import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/shred_models.dart';

class FileShredderService {
  static const int _bufferSize = 1024 * 1024; // 1 MB write buffer

  /// Shreds all [filePaths] using [algorithm].
  /// Calls [onFileStart] before each file and [onFileFinish] after.
  Future<ShredResult> shred({
    required List<String> filePaths,
    required ShredAlgorithm algorithm,
    void Function(String path, int index, int total)? onFileStart,
    void Function(ShredFileResult result)? onFileFinish,
  }) async {
    final results = <ShredFileResult>[];

    for (int i = 0; i < filePaths.length; i++) {
      final path = filePaths[i];
      onFileStart?.call(path, i, filePaths.length);
      final r = await _shredOne(path, algorithm);
      results.add(r);
      onFileFinish?.call(r);
    }

    return ShredResult(fileResults: results);
  }

  /// Shreds a single file.
  Future<ShredFileResult> _shredOne(String path, ShredAlgorithm algo) async {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return ShredFileResult(
          path: path, success: false, passes: 0,
          errorMessage: 'File not found.',
        );
      }

      final size = file.statSync().size;
      if (size == 0) {
        await file.delete();
        return ShredFileResult(path: path, success: true, passes: 0);
      }

      final random = Random.secure();

      // ── Write passes ────────────────────────────────────────────────────
      for (int pass = 0; pass < algo.passes; pass++) {
        final raf = await file.open(mode: FileMode.writeOnly);
        try {
          int remaining = size;
          while (remaining > 0) {
            final chunk = min(remaining, _bufferSize);
            final buf   = _passBuffer(pass, algo, chunk, random);
            await raf.writeFrom(buf);
            remaining -= chunk;
          }
          await raf.flush();
        } finally {
          await raf.close();
        }
      }

      // ── Rename to random name before delete (hides original filename) ────
      final dir     = file.parent;
      final tmpPath = '${dir.path}\\${_randomName()}.tmp';
      final renamed = await file.rename(tmpPath);

      // ── Final delete ─────────────────────────────────────────────────────
      await renamed.delete();

      return ShredFileResult(path: path, success: true, passes: algo.passes);
    } catch (e) {
      debugPrint('FileShredderService._shredOne error [$path]: $e');
      return ShredFileResult(
        path: path,
        success: false,
        passes: 0,
        errorMessage: e.toString(),
      );
    }
  }

  /// Returns the write buffer for a specific pass.
  /// Pass pattern:
  ///   DoD  (7)  : 0x00, 0xFF, random, 0x00, 0xFF, random, random
  ///   3-pass    : 0x00, 0xFF, random
  ///   1-pass    : random
  ///   Gutmann   : 35 passes, mix of patterns
  Uint8List _passBuffer(
      int pass, ShredAlgorithm algo, int size, Random random) {
    final buf = Uint8List(size);
    int fillByte = -1; // -1 → random

    switch (algo) {
      case ShredAlgorithm.standard:
        if (pass == 0) fillByte = 0x00;
        if (pass == 1) fillByte = 0xFF;
        break;
      case ShredAlgorithm.dod:
        if (pass == 0) fillByte = 0x00;
        if (pass == 1) fillByte = 0xFF;
        if (pass == 3) fillByte = 0x00;
        if (pass == 4) fillByte = 0xFF;
        break;
      case ShredAlgorithm.gutmann:
        // Simple approximation: alternate 0x00 / 0xFF / random groups
        if (pass % 3 == 0) fillByte = 0x00;
        if (pass % 3 == 1) fillByte = 0xFF;
        break;
      case ShredAlgorithm.single:
        break; // always random
    }

    if (fillByte >= 0) {
      buf.fillRange(0, buf.length, fillByte);
    } else {
      for (int i = 0; i < buf.length; i++) {
        buf[i] = random.nextInt(256);
      }
    }
    return buf;
  }

  String _randomName() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    return List.generate(16, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// Opens a Windows multi-select file picker, returns selected paths.
  Future<List<String>> pickFiles() async {
    try {
      final r = await Process.run('powershell.exe', [
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command',
        r'''
Add-Type -AssemblyName System.Windows.Forms
$dlg = New-Object System.Windows.Forms.OpenFileDialog
$dlg.Multiselect = $true
$dlg.Title = "Select files to permanently shred"
$dlg.Filter = "All Files (*.*)|*.*"
if ($dlg.ShowDialog() -eq "OK") {
  Write-Output ($dlg.FileNames -join "|")
}
''',
      ]);
      final out = r.stdout.toString().trim();
      if (out.isEmpty) return [];
      return out.split('|').where((s) => s.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }
}
