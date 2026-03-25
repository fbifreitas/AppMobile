import 'package:url_launcher/url_launcher.dart';

class MapService {
  /// Abre Waze para coordenadas
  Future<void> abrirWaze(double latitude, double longitude) async {
    final wazeUrl = 'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes';
    final googleUrl = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';

    if (await canLaunchUrl(Uri.parse(wazeUrl))) {
      await launchUrl(Uri.parse(wazeUrl));
    } else if (await canLaunchUrl(Uri.parse(googleUrl))) {
      await launchUrl(Uri.parse(googleUrl));
    } else {
      throw 'Não foi possível abrir Waze ou Google Maps';
    }
  }
}