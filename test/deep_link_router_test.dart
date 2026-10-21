import 'package:flutter_test/flutter_test.dart';
import 'package:sahulat_ghar_tak/utils/deep_link_router.dart';

void main() {
  DeepLink? parse(String url) => parseDeepLink(Uri.parse(url));

  group('parseDeepLink', () {
    test('marketing pages and the site root open Home', () {
      for (final path in const [
        '',
        '/',
        '/home-maintenance',
        '/home-maintenance/plumbing',
        '/specialized-services',
        '/property-and-legal-services',
        '/Home/DownloadApp',
      ]) {
        expect(parse('https://sahulatghartak.com$path'),
            const DeepLink(DeepLinkKind.home),
            reason: path);
      }
    });

    test('www host is accepted', () {
      expect(parse('https://www.sahulatghartak.com/home-maintenance'),
          const DeepLink(DeepLinkKind.home));
    });

    test('app links carry the id', () {
      expect(parse('https://sahulatghartak.com/app/requests/42'),
          const DeepLink(DeepLinkKind.request, 42));
      expect(parse('https://sahulatghartak.com/app/bookings/7/'),
          const DeepLink(DeepLinkKind.booking, 7));
      expect(parse('https://sahulatghartak.com/app/notifications'),
          const DeepLink(DeepLinkKind.notifications));
    });

    test('malformed or unknown paths fall back to Home', () {
      for (final path in const [
        '/app',
        '/app/requests',
        '/app/requests/abc',
        '/app/requests/42/extra',
        '/app/unknown/1',
        '/something-new',
      ]) {
        expect(parse('https://sahulatghartak.com$path'),
            const DeepLink(DeepLinkKind.home),
            reason: path);
      }
    });

    test('foreign hosts and schemes are ignored', () {
      expect(parse('https://evil.example/app/requests/1'), isNull);
      expect(parse('https://sahulatghartak.com.evil.example/'), isNull);
      expect(parse('http://sahulatghartak.com/'), isNull);
      expect(parse('sahulatghartak://app/requests/1'), isNull);
    });
  });
}
