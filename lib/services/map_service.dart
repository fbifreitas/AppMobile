import 'package:url_launcher/url_launcher.dart';

class MapService {
  Future<void> abrirWaze(double latitude, double longitude) async {
    final wazeUri = Uri.parse(
      'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes',
    );

    if (await canLaunchUrl(wazeUri)) {
      await launchUrl(
        wazeUri,
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    await launchUrl(
      googleMapsUri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> abrirBuscaPorEndereco(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
    );

    await launchUrl(
      googleMapsUri,
      mode: LaunchMode.externalApplication,
    );
  }
}
