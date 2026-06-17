/// Configuração de ambiente do app.
///
/// A base URL do backend é injetada em tempo de build via:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
/// Default: 10.0.2.2 = host loopback visto de dentro do emulador Android.
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
