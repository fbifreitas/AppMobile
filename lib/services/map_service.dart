import 'package:url_launcher/url_launcher.dart';

class MapService {

  /// 🧭 ABRIR WAZE
  Future<void> abrirWaze(double lat, double lng) async {
    final url = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      /// fallback navegador
      final fallback = Uri.parse(
        'https://waze.com/ul?ll=$lat,$lng&navigate=yes',
      );
      await launchUrl(fallback);
    }
  }

  /// 🗺️ GOOGLE MAPS
  Future<void> abrirGoogleMaps(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    await launchUrl(url);
  }
}