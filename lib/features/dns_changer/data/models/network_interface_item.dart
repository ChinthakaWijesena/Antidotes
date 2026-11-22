class NetworkInterfaceItem {
  final String name;
  final String description;
  final String ipAddress;
  final List<String> currentDnsServers;
  final bool isDhcp;
  final bool isConnected;

  const NetworkInterfaceItem({
    required this.name,
    this.description = '',
    this.ipAddress = '',
    this.currentDnsServers = const [],
    this.isDhcp = true,
    this.isConnected = true,
  });

  String get formattedCurrentDns {
    if (currentDnsServers.isEmpty) {
      return isDhcp ? 'Automatic (DHCP / Router)' : 'None';
    }
    return currentDnsServers.join('  •  ');
  }

  NetworkInterfaceItem copyWith({
    String? name,
    String? description,
    String? ipAddress,
    List<String>? currentDnsServers,
    bool? isDhcp,
    bool? isConnected,
  }) {
    return NetworkInterfaceItem(
      name: name ?? this.name,
      description: description ?? this.description,
      ipAddress: ipAddress ?? this.ipAddress,
      currentDnsServers: currentDnsServers ?? this.currentDnsServers,
      isDhcp: isDhcp ?? this.isDhcp,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
