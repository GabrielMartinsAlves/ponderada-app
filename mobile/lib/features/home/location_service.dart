import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Resultado da tentativa de obter a localização do dispositivo.
class PosicaoResultado {
  final Position? posicao;
  final String? aviso; // mensagem quando negado/desligado (degrade elegante)
  bool get permitido => posicao != null;
  const PosicaoResultado({this.posicao, this.aviso});
}

/// Usa o hardware de localização (GPS) via geolocator, com tratamento de
/// permissão: se negar/estiver desligado, retorna um aviso (não quebra a tela).
class LocationService {
  /// No Android usa o LocationManager da plataforma (lê a posição real do GPS,
  /// inclusive a simulada em testes); nas demais plataformas, o ajuste padrão.
  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        forceLocationManager: true,
        timeLimit: const Duration(seconds: 15),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    );
  }

  Future<PosicaoResultado> obter() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const PosicaoResultado(aviso: 'Ative a localização do dispositivo para ver as distâncias.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return const PosicaoResultado(aviso: 'Permissão de localização negada — habilite para ver as distâncias.');
    }
    try {
      final pos = await Geolocator.getCurrentPosition(locationSettings: _settings());
      return PosicaoResultado(posicao: pos);
    } catch (_) {
      // Fix recente indisponível (ex.: emulador): usa a última posição conhecida.
      final ultima = await Geolocator.getLastKnownPosition();
      if (ultima != null) return PosicaoResultado(posicao: ultima);
      return const PosicaoResultado(aviso: 'Não foi possível obter sua localização agora.');
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

final posicaoProvider = FutureProvider<PosicaoResultado>((ref) => ref.read(locationServiceProvider).obter());
