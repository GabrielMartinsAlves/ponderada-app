import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_user.dart';
import '../../features/auth/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  const AuthState(this.status, {this.user});
}

/// Estado de autenticação real (token em secure storage) que dirige o redirect.
class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    _bootstrap();
    return const AuthState(AuthStatus.unknown);
  }

  // Na partida: valida o token salvo (chama /perfil); define autenticado ou não.
  Future<void> _bootstrap() async {
    final user = await _repo.currentUser();
    state = user != null
        ? AuthState(AuthStatus.authenticated, user: user)
        : const AuthState(AuthStatus.unauthenticated);
  }

  // login/signup lançam ApiException em falha (a tela trata loading/erro).
  Future<void> login(String email, String senha) async {
    final user = await _repo.login(email, senha);
    state = AuthState(AuthStatus.authenticated, user: user);
  }

  Future<void> signup({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    final user = await _repo.signup(nome: nome, email: email, telefone: telefone, senha: senha);
    state = AuthState(AuthStatus.authenticated, user: user);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
