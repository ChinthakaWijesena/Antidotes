class NetworkInfo {
  final bool isConnected;
  final String adapterName;
  final String description;
  final String connectionType; // Wi-Fi / Ethernet
  final String linkSpeed;
  final String ipAddress;
  final int signalPercent; // for Wi-Fi

  const NetworkInfo({
    required this.isConnected,
    required this.adapterName,
    required this.description,
    required this.connectionType,
    required this.linkSpeed,
    required this.ipAddress,
    required this.signalPercent,
  });
}
