import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokens: ref.read(tokenStorageProvider)),
);
