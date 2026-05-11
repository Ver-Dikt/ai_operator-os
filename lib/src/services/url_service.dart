import 'package:url_launcher/url_launcher.dart';

class UrlService {
  const UrlService();

  Future<void> open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
