import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/app_user.dart';
import '../../core/config/env.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_providers.dart';
import '../../core/network/token_storage.dart';

class AuthRepository {
  final ApiClient _api; // dio com Bearer + refresh (para /perfil)
  final TokenStorage _tokens;
  // dio "cru" (sem interceptors) para os endpoints públicos de auth
  final Dio _auth = Dio(BaseOptions(
    baseUrl: '${Env.apiBaseUrl}/api/booking',
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 12),
    headers: {'Content-Type': 'application/json'},
  ));

  AuthRepository(this._api, this._tokens);

  Future<AppUser> login(String email, String senha) async {
    try {
      final res = await _auth.post('/auth/login', data: {'email': email, 'senha': senha});
      await _tokens.save(
        accessToken: res.data['access_token'] as String,
        refreshToken: res.data['refresh_token'] as String,
      );
      return AppUser.fromJson(res.data['user'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  Future<AppUser> signup({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    try {
      final res = await _auth.post('/auth/signup',
          data: {'nome': nome, 'email': email, 'telefone': telefone, 'senha': senha});
      final at = res.data['access_token'];
      final rt = res.data['refresh_token'];
      if (at is String && rt is String) {
        await _tokens.save(accessToken: at, refreshToken: rt);
        return AppUser.fromJson((res.data['user'] ?? {}) as Map<String, dynamic>);
      }
      // signup criou o usuário mas não devolveu sessão -> faz login
      return login(email, senha);
    } catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  /// Bootstrap: valida o token salvo chamando /perfil (Bearer). Limpa se inválido.
  Future<AppUser?> currentUser() async {
    if (!await _tokens.hasSession()) return null;
    try {
      final res = await _api.dio.get('/perfil');
      return AppUser.fromJson(res.data['perfil'] as Map<String, dynamic>);
    } catch (_) {
      await _tokens.clear();
      return null;
    }
  }

  Future<void> logout() => _tokens.clear();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider), ref.read(tokenStorageProvider)),
);
