// ignore_for_file: constant_identifier_names

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart';

// Win32 SHEmptyRecycleBin Flags
const int SHERB_NOCONFIRMATION = 0x00000001;
const int SHERB_NOPROGRESSUI = 0x00000002;
const int SHERB_NOSOUND = 0x00000004;

// SHFileOperation Flags for Recycling
const int FO_DELETE = 0x0003;
const int FOF_ALLOWUNDO = 0x0040;
const int FOF_NOCONFIRMATION = 0x0010;
const int FOF_SILENT = 0x0004;
const int FOF_NOERRORUI = 0x0400;

final class SHQUERYRBINFO extends Struct {
  @Uint32()
  external int cbSize;
  @Int64()
  external int i64Size;
  @Int64()
  external int i64NumItems;
}

final class SHFILEOPSTRUCTW extends Struct {
  @IntPtr()
  external int hwnd;
  @Uint32()
  external int wFunc;
  external Pointer<Utf16> pFrom;
  external Pointer<Utf16> pTo;
  @Uint16()
  external int fFlags;
  @Int32()
  external int fAnyOperationsAborted;
  @IntPtr()
  external int hNameMappings;
  external Pointer<Utf16> lpszProgressTitle;
}

typedef SHEmptyRecycleBinNative = Int32 Function(
  IntPtr hwnd,
  Pointer<Utf16> pszRootPath,
  Uint32 dwFlags,
);
typedef SHEmptyRecycleBinDart = int Function(
  int hwnd,
  Pointer<Utf16> pszRootPath,
  int dwFlags,
);

typedef SHQueryRecycleBinNative = Int32 Function(
  Pointer<Utf16> pszRootPath,
  Pointer<SHQUERYRBINFO> pSHQueryRBInfo,
);
typedef SHQueryRecycleBinDart = int Function(
  Pointer<Utf16> pszRootPath,
  Pointer<SHQUERYRBINFO> pSHQueryRBInfo,
);

typedef SHFileOperationNative = Int32 Function(
  Pointer<SHFILEOPSTRUCTW> lpFileOp,
);
typedef SHFileOperationDart = int Function(
  Pointer<SHFILEOPSTRUCTW> lpFileOp,
);

class RecycleBinInfo {
  final int totalBytes;
  final int totalItems;

  const RecycleBinInfo({required this.totalBytes, required this.totalItems});
}

class Win32ShellService {
  Win32ShellService._();

  static DynamicLibrary? _shell32;
  static SHEmptyRecycleBinDart? _shEmptyRecycleBin;
  static SHQueryRecycleBinDart? _shQueryRecycleBin;
  static SHFileOperationDart? _shFileOperation;

  static void _init() {
    if (!Platform.isWindows) return;
    if (_shell32 != null) return;

    try {
      _shell32 = DynamicLibrary.open('shell32.dll');
      _shEmptyRecycleBin = _shell32!
          .lookupFunction<SHEmptyRecycleBinNative, SHEmptyRecycleBinDart>(
              'SHEmptyRecycleBinW');
      _shQueryRecycleBin = _shell32!
          .lookupFunction<SHQueryRecycleBinNative, SHQueryRecycleBinDart>(
              'SHQueryRecycleBinW');
      _shFileOperation = _shell32!
          .lookupFunction<SHFileOperationNative, SHFileOperationDart>(
              'SHFileOperationW');
    } catch (_) {
      // Dynamic loading failure on non-Windows or restricted environment
    }
  }

  /// Queries the Recycle Bin for total size and items count on Windows (offloaded to background Isolate).
  static Future<RecycleBinInfo?> queryRecycleBin() async {
    if (!Platform.isWindows) return null;
    return Isolate.run(_queryRecycleBinSync);
  }

  static RecycleBinInfo? _queryRecycleBinSync() {
    if (!Platform.isWindows) return null;
    _init();
    if (_shQueryRecycleBin == null) return null;

    final infoPtr = calloc<SHQUERYRBINFO>();
    try {
      infoPtr.ref.cbSize = sizeOf<SHQUERYRBINFO>();
      final result = _shQueryRecycleBin!(nullptr, infoPtr);
      if (result == 0) {
        return RecycleBinInfo(
          totalBytes: infoPtr.ref.i64Size,
          totalItems: infoPtr.ref.i64NumItems,
        );
      }
    } catch (_) {
      // Ignored
    } finally {
      calloc.free(infoPtr);
    }
    return null;
  }

  /// Empties the Windows Recycle Bin safely using shell32.dll (offloaded to background Isolate).
  static Future<bool> emptyRecycleBin({bool showUi = false}) async {
    if (!Platform.isWindows) return false;
    return Isolate.run(() => _emptyRecycleBinSync(showUi: showUi));
  }

  static bool _emptyRecycleBinSync({bool showUi = false}) {
    if (!Platform.isWindows) return false;
    _init();
    if (_shEmptyRecycleBin == null) return false;

    var flags = SHERB_NOSOUND;
    if (!showUi) {
      flags |= SHERB_NOCONFIRMATION | SHERB_NOPROGRESSUI;
    }

    try {
      final hr = _shEmptyRecycleBin!(0, nullptr, flags);
      return hr == 0;
    } catch (_) {
      return false;
    }
  }

  /// Moves a file to the Windows Recycle Bin instead of permanent deletion (offloaded to background Isolate).
  static Future<bool> moveToRecycleBin(String filePath) async {
    if (!Platform.isWindows) return false;
    return Isolate.run(() => moveToRecycleBinSync(filePath));
  }

  /// Synchronous FFI version intended for use inside background worker Isolates.
  static bool moveToRecycleBinSync(String filePath) {
    if (!Platform.isWindows) return false;
    _init();
    if (_shFileOperation == null) return false;

    // SHFileOperation requires double null-terminated strings
    final pFrom = '$filePath\x00\x00'.toNativeUtf16();
    final fileOp = calloc<SHFILEOPSTRUCTW>();

    try {
      fileOp.ref.hwnd = 0;
      fileOp.ref.wFunc = FO_DELETE;
      fileOp.ref.pFrom = pFrom;
      fileOp.ref.pTo = nullptr;
      fileOp.ref.fFlags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_SILENT | FOF_NOERRORUI;
      fileOp.ref.fAnyOperationsAborted = 0;
      fileOp.ref.hNameMappings = 0;
      fileOp.ref.lpszProgressTitle = nullptr;

      final res = _shFileOperation!(fileOp);
      return res == 0 && fileOp.ref.fAnyOperationsAborted == 0;
    } catch (_) {
      return false;
    } finally {
      calloc.free(pFrom);
      calloc.free(fileOp);
    }
  }

  /// Launches cleanmgr (Windows Disk Cleanup) for advanced Windows.old cleanup
  static Future<void> launchCleanmgr() async {
    if (!Platform.isWindows) return;
    try {
      await Process.start('cleanmgr.exe', [], runInShell: true);
    } catch (_) {}
  }
}
