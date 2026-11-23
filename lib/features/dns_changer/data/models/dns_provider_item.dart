import 'package:flutter/material.dart';

class DnsProviderItem {
  final String id;
  final String name;
  final String tag;
  final String primaryIpv4;
  final String secondaryIpv4;
  final String? primaryIpv6;
  final String? secondaryIpv6;
  final String description;
  final Color brandColor;
  final IconData icon;
  final int? latencyMs;
  final bool isDefaultDhcp;
  final bool isFamilySafe;
  final bool enforcesSafeSearch;

  const DnsProviderItem({
    required this.id,
    required this.name,
    required this.tag,
    required this.primaryIpv4,
    required this.secondaryIpv4,
    this.primaryIpv6,
    this.secondaryIpv6,
    required this.description,
    required this.brandColor,
    required this.icon,
    this.latencyMs,
    this.isDefaultDhcp = false,
    this.isFamilySafe = false,
    this.enforcesSafeSearch = false,
  });

  DnsProviderItem copyWith({
    String? id,
    String? name,
    String? tag,
    String? primaryIpv4,
    String? secondaryIpv4,
    String? primaryIpv6,
    String? secondaryIpv6,
    String? description,
    Color? brandColor,
    IconData? icon,
    int? latencyMs,
    bool? isDefaultDhcp,
    bool? isFamilySafe,
    bool? enforcesSafeSearch,
  }) {
    return DnsProviderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      primaryIpv4: primaryIpv4 ?? this.primaryIpv4,
      secondaryIpv4: secondaryIpv4 ?? this.secondaryIpv4,
      primaryIpv6: primaryIpv6 ?? this.primaryIpv6,
      secondaryIpv6: secondaryIpv6 ?? this.secondaryIpv6,
      description: description ?? this.description,
      brandColor: brandColor ?? this.brandColor,
      icon: icon ?? this.icon,
      latencyMs: latencyMs ?? this.latencyMs,
      isDefaultDhcp: isDefaultDhcp ?? this.isDefaultDhcp,
      isFamilySafe: isFamilySafe ?? this.isFamilySafe,
      enforcesSafeSearch: enforcesSafeSearch ?? this.enforcesSafeSearch,
    );
  }
}
