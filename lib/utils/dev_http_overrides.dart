import 'dart:io';

// Trusts the ASP.NET Core local dev certificate, which isn't in the
// system trust store. Debug-only — never applied in release builds.
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) =>
          _isTrustedDevHost(host);
  }

  static bool _isTrustedDevHost(String host) {
    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
      return true;
    }

    // Physical device on the same Wi‑Fi reaches the PC via a LAN IP.
    final ip = InternetAddress.tryParse(host);
    if (ip?.type != InternetAddressType.IPv4) return false;

    final o = ip!.rawAddress;
    if (o[0] == 10) return true;
    if (o[0] == 192 && o[1] == 168) return true;
    if (o[0] == 172 && o[1] >= 16 && o[1] <= 31) return true;
    return false;
  }
}
