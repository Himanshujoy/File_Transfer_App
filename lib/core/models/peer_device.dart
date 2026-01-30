class PeerDevice {
  final String id;
  final String name;
  final String host;

  /// mDNS host (may be .local)
  final String ip;

  /// Resolved IPv4 address (used for socket/http)
  final int port;

  final String displayName;

  PeerDevice({
    required this.id,
    required this.name,
    required this.host,
    required this.ip,
    required this.port,
    required this.displayName,
  });

  @override
  String toString() => 'PeerDevice(name: $name, ip: $ip, port: $port)';
}
