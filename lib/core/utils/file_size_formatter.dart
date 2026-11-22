class FileSizeFormatter {
  FileSizeFormatter._();

  static String format(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    // Don't show decimal points for exact byte counts
    if (i == 0) {
      return '$bytes B';
    }

    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
