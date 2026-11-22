import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_theme/system_theme.dart';

void main() {
  test('SystemTheme fallback is available', () {
    SystemTheme.fallbackColor = const Color(0xFF00D2C4);
    expect(SystemTheme.fallbackColor, const Color(0xFF00D2C4));
  });
}
