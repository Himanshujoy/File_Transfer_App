class PeerDevice {
  final String id;
  final String name;
  final String ip;
  final int port;

  PeerDevice({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
  });

  /// Used when resolving .local hostnames to IPv4
  PeerDevice copyWith({String? id, String? name, String? ip, int? port}) {
    return PeerDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
    );
  }

  @override
  String toString() {
    return 'PeerDevice(name: $name, ip: $ip, port: $port)';
  }
}
