import 'package:flutter/material.dart';

class DnsProviderItem {
  final String id;
  final String name;
  final String tag;
  final String primaryIpv4;
  final String secondaryIpv4;
  final String description;
  final Color brandColor;
  final IconData icon;
  final int? latencyMs;
  final bool isDefaultDhcp;

  const DnsProviderItem({
    required this.id,
    required this.name,
    required this.tag,
    required this.primaryIpv4,
    required this.secondaryIpv4,
    required this.description,
    required this.brandColor,
    required this.icon,
    this.latencyMs,
    this.isDefaultDhcp = false,
  });

  DnsProviderItem copyWith({
    String? id,
    String? name,
    String? tag,
    String? primaryIpv4,
    String? secondaryIpv4,
    String? description,
    Color? brandColor,
    IconData icon = Icons.dns_rounded,
    int? latencyMs,
    bool? isDefaultDhcp,
  }) {
    return DnsProviderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      primaryIpv4: primaryIpv4 ?? this.primaryIpv4,
      secondaryIpv4: secondaryIpv4 ?? this.secondaryIpv4,
      description: description ?? this.description,
      brandColor: brandColor ?? this.brandColor,
      icon: icon,
      latencyMs: latencyMs ?? this.latencyMs,
      isDefaultDhcp: isDefaultDhcp ?? this.isDefaultDhcp,
    );
  }
}
