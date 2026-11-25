import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'brand_icon_painters.dart';

enum BrandType {
  spotify,
  chrome,
  firefox,
  edge,
  brave,
  opera,
  operaGx,
  discord,
  telegram,
  whatsapp,
  vscode,
  git,
  python,
  vlc,
  steam,
  internetExplorer,
  unknown,
}

class AppIconWidget extends StatelessWidget {
  final String name;
  final String? iconPath;
  final String? iconCachePath;
  final String? packageId;
  final IconData? fallbackIcon;
  final Color? brandColor;
  final double size;
  final double borderRadius;

  const AppIconWidget({
    super.key,
    required this.name,
    this.iconPath,
    this.iconCachePath,
    this.packageId,
    this.fallbackIcon,
    this.brandColor,
    this.size = 38,
    this.borderRadius = 8,
  });

  /// Identifies if the app matches a curated high-fidelity vector brand
  BrandType _resolveBrand() {
    final lowerName = name.toLowerCase().trim();
    final lowerPkg = (packageId ?? '').toLowerCase().trim();
    final combined = '$lowerName $lowerPkg';

    if (combined.contains('spotify')) return BrandType.spotify;
    if (combined.contains('chrome')) return BrandType.chrome;
    if (combined.contains('firefox')) return BrandType.firefox;
    if (combined.contains('opera gx') || combined.contains('operagx')) return BrandType.operaGx;
    if (combined.contains('opera')) return BrandType.opera;
    if (combined.contains('brave')) return BrandType.brave;
    if (combined.contains('edge') || combined.contains('msedge')) return BrandType.edge;
    if (combined.contains('discord')) return BrandType.discord;
    if (combined.contains('telegram')) return BrandType.telegram;
    if (combined.contains('whatsapp')) return BrandType.whatsapp;
    if (combined.contains('code') || combined.contains('vscode') || combined.contains('visual studio code')) {
      return BrandType.vscode;
    }
    if (combined.contains('vlc') || combined.contains('videolan')) return BrandType.vlc;
    if (combined.contains('steam')) return BrandType.steam;
    if (combined.contains('git.') || combined.contains('git for windows') || combined == 'git') {
      return BrandType.git;
    }
    if (combined.contains('python')) return BrandType.python;
    if (combined.contains('internet explorer') || combined.contains('iexplore')) {
      return BrandType.internetExplorer;
    }

    return BrandType.unknown;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Check if a local cached PNG icon exists from Windows executable
    if (iconCachePath != null && iconCachePath!.isNotEmpty) {
      final file = File(iconCachePath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => _buildBrandOrFallback(),
          ),
        );
      }
    }

    // 2. Also check if iconPath directly points to an existing image file (e.g. .ico or .png)
    if (iconPath != null && iconPath!.isNotEmpty) {
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
              errorBuilder: (context, error, stackTrace) => _buildBrandOrFallback(),
            ),
          );
        }
      }
    }

    // 3. Fallback to vector brand or stylized avatar
    return _buildBrandOrFallback();
  }

  Widget _buildBrandOrFallback() {
    final brand = _resolveBrand();

    if (brand != BrandType.unknown) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: CustomPaint(
            size: Size(size, size),
            painter: _getPainter(brand),
          ),
        ),
      );
    }

    // Curated high-quality vector fallbacks for popular installer apps
    final lower = name.toLowerCase();
    if (lower.contains('7-zip') || lower.contains('7zip')) {
      return _buildBadge(
        label: '7z',
        bgColor: const Color(0xFF1E3A8A),
        textColor: Colors.white,
      );
    }
    if (lower.contains('notepad++') || lower.contains('notepadplusplus')) {
      return _buildBadge(
        label: 'N++',
        bgColor: const Color(0xFF15803D),
        textColor: const Color(0xFF86EFAC),
      );
    }
    if (lower.contains('winrar')) {
      return _buildBadge(
        label: 'RAR',
        bgColor: const Color(0xFF0369A1),
        textColor: Colors.white,
      );
    }
    if (lower.contains('epic games')) {
      return _buildBadge(
        label: 'EPIC',
        bgColor: const Color(0xFF18181B),
        textColor: Colors.white,
      );
    }
    if (lower.contains('powertoys')) {
      return _buildBadge(
        icon: Icons.tune_rounded,
        bgColor: const Color(0xFF0284C7),
        iconColor: Colors.white,
      );
    }
    if (lower.contains('obs studio') || lower.contains('obs')) {
      return _buildBadge(
        icon: Icons.videocam_rounded,
        bgColor: const Color(0xFF27272A),
        iconColor: Colors.white,
      );
    }
    if (lower.contains('everything')) {
      return _buildBadge(
        icon: Icons.search_rounded,
        bgColor: const Color(0xFFD97706),
        iconColor: Colors.white,
      );
    }

    // Fallback: icon or initial letter
    final effectiveColor = brandColor ?? _computeColorFromName(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.35),
        ),
      ),
      child: Center(
        child: fallbackIcon != null
            ? Icon(fallbackIcon, size: size * 0.52, color: effectiveColor)
            : Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: size * 0.44,
                  fontWeight: FontWeight.bold,
                  color: effectiveColor,
                ),
              ),
      ),
    );
  }

  Widget _buildBadge({
    String? label,
    IconData? icon,
    required Color bgColor,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: label != null
            ? Text(
                label,
                style: TextStyle(
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w900,
                  color: textColor ?? Colors.white,
                  letterSpacing: -0.5,
                ),
              )
            : Icon(icon, size: size * 0.52, color: iconColor ?? Colors.white),
      ),
    );
  }

  CustomPainter _getPainter(BrandType brand) {
    switch (brand) {
      case BrandType.spotify:
        return const SpotifyPainter();
      case BrandType.chrome:
        return const ChromePainter();
      case BrandType.firefox:
        return const FirefoxPainter();
      case BrandType.edge:
        return const EdgePainter();
      case BrandType.brave:
        return const BravePainter();
      case BrandType.opera:
        return const OperaPainter(isGx: false);
      case BrandType.operaGx:
        return const OperaPainter(isGx: true);
      case BrandType.discord:
        return const DiscordPainter();
      case BrandType.telegram:
        return const TelegramPainter();
      case BrandType.whatsapp:
        return const WhatsAppPainter();
      case BrandType.vscode:
        return const VSCodePainter();
      case BrandType.git:
        return const GitPainter();
      case BrandType.python:
        return const PythonPainter();
      case BrandType.vlc:
        return const VLCPainter();
      case BrandType.steam:
        return const SteamPainter();
      case BrandType.internetExplorer:
        return const InternetExplorerPainter();
      case BrandType.unknown:
        return const SpotifyPainter();
    }
  }

  Color _computeColorFromName(String str) {
    if (str.isEmpty) return AppColors.primary;
    final hash = str.hashCode.abs();
    final colors = [
      const Color(0xFF3B82F6), // blue
      const Color(0xFF10B981), // emerald
      const Color(0xFF8B5CF6), // purple
      const Color(0xFFF59E0B), // amber
      const Color(0xFFEC4899), // pink
      const Color(0xFF06B6D4), // cyan
      const Color(0xFF6366F1), // indigo
      const Color(0xFF14B8A6), // teal
    ];
    return colors[hash % colors.length];
  }
}
