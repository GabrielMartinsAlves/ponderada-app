import 'package:url_launcher/url_launcher.dart';

String fmtDistancia(double metros) {
  if (metros < 950) return '${metros.round()} m';
  return '${(metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Abre a rota até a coordenada no app de mapas / navegador (url_launcher).
Future<bool> abrirRota(double lat, double lng) async {
  final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
