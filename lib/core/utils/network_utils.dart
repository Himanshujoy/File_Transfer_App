import 'dart:io';

class NetworkUtils {
  static Future<String> resolveHostToIp(String host) async {
    // Already IPv4
    final ipv4Regex = RegExp(r'^\d+\.\d+\.\d+\.\d+$');
    if (ipv4Regex.hasMatch(host)) {
      return host;
    }

    final addresses = await InternetAddress.lookup(host);
    return addresses.first.address;
  }
}
