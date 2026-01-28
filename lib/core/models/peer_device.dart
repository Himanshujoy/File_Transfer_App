class PeerDevice {
  final String id;
  final String name;
  final String host;

  /// mDNS host (may be .local)
  final String ip;

  /// Resolved IPv4 address (used for socket/http)
  final int port;

  PeerDevice({
    required this.id,
    required this.name,
    required this.host,
    required this.ip,
    required this.port,
  });
}
