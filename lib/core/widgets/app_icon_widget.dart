import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable application icon widget.
/// Displays the genuine extracted Windows executable icon if available,
/// or falls back to a clean, standard Material Icon.
/// No code-drawn custom canvas logos.
class AppIconWidget extends StatelessWidget {
  final String name;
  final String? iconPath;
  final String? iconCachePath;
  final IconData? fallbackIcon;
  final Color? brandColor;
  final double size;
  final double borderRadius;

  const AppIconWidget({
    super.key,
    required this.name,
    this.iconPath,
    this.iconCachePath,
    this.fallbackIcon,
    this.brandColor,
    this.size = 32,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Check if an extracted PNG icon file exists in cache
    if (iconCachePath != null && iconCachePath!.trim().isNotEmpty) {
      final file = File(iconCachePath!.trim());
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => _buildFallback(),
          ),
        );
      }
    }

    // 2. Also check if iconPath directly points to an existing image file (.ico or .png)
    if (iconPath != null && iconPath!.trim().isNotEmpty) {
      final clean = iconPath!.replaceAll('"', '').split(',').first.trim();
      if (clean.toLowerCase().endsWith('.png') || clean.toLowerCase().endsWith('.ico')) {
        final file = File(clean);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => _buildFallback(),
            ),
          );
        }
      }
    }

    // 3. Fallback: Normal, clean Material Icon or app letter
    return _buildFallback();
  }

  Widget _buildFallback() {
    final effectiveColor = brandColor ?? const Color(0xFFF57C00);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.surfaceBorder,
        ),
      ),
      child: Center(
        child: Icon(
          fallbackIcon ?? Icons.widgets_rounded,
          size: size * 0.58,
          color: effectiveColor,
        ),
      ),
    );
  }
}
