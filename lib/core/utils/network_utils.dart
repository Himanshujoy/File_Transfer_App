import 'dart:io';

class NetworkUtils {
  /// Returns the device's primary IPv4 address
  static Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('❌ Failed to get local IP: $e');
    }
    return null;
  }

  /// Resolves a host (.local or IP) to IPv4 only
  static Future<String?> resolveHostToIp(String host) async {
    try {
      // Already IPv4
      final ipv4Regex = RegExp(r'^\d+\.\d+\.\d+\.\d+$');
      if (ipv4Regex.hasMatch(host)) {
        return host;
      }

      final addresses = await InternetAddress.lookup(host);

      for (final addr in addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          return addr.address;
        }
      }
    } catch (e) {
      print('❌ Failed to resolve host $host: $e');
    }
    return null;
  }
}
