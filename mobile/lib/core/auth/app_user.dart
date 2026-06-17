class AppUser {
  final String email;
  final String nome;
  final String telefone;
  const AppUser({required this.email, required this.nome, required this.telefone});

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        email: (j['email'] ?? '').toString(),
        nome: (j['nome'] ?? '').toString(),
        telefone: (j['telefone'] ?? '').toString(),
      );
}
