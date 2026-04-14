import 'dart:async';
import 'dart:convert';
import 'dart:io';

class MobileAuthSession {
  const MobileAuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresInSeconds,
    required this.userId,
    required this.tenantId,
    required this.email,
    this.nome,
    this.tipo,
    this.cpf,
    this.cnpj,
    required this.userStatus,
    required this.membershipRole,
    required this.membershipStatus,
    required this.permissions,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInSeconds;
  final int userId;
  final String tenantId;
  final String email;
  final String? nome;
  final String? tipo;
  final String? cpf;
  final String? cnpj;
  final String userStatus;
  final String membershipRole;
  final String membershipStatus;
  final List<String> permissions;
}

class MobileAuthTokens {
  const MobileAuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresInSeconds,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInSeconds;
}

class MobileFirstAccessChallenge {
  const MobileFirstAccessChallenge({
    required this.challengeId,
    required this.deliveryHint,
    required this.expiresInSeconds,
    this.debugOtp,
  });

  final String challengeId;
  final String deliveryHint;
  final int expiresInSeconds;
  final String? debugOtp;
}

abstract class MobileAuthGateway {
  bool get isConfigured;

  Future<MobileAuthSession> login({
    required String tenantId,
    required String email,
    required String password,
    required String deviceInfo,
  });

  Future<MobileAuthTokens> refresh({required String refreshToken});

  Future<void> logout({required String refreshToken});
}

class MobileBackendAuthService implements MobileAuthGateway {
  const MobileBackendAuthService({
    String? baseUrl,
    HttpClient Function()? httpClientFactory,
  }) : _baseUrlOverride = baseUrl,
       _httpClientFactory = httpClientFactory;

  static const String _baseUrl = String.fromEnvironment('APP_API_BASE_URL');

  final String? _baseUrlOverride;
  final HttpClient Function()? _httpClientFactory;
  static const Duration _requestTimeout = Duration(seconds: 8);

  String get _resolvedBaseUrl => (_baseUrlOverride ?? _baseUrl).trim();

  @override
  bool get isConfigured => _resolvedBaseUrl.isNotEmpty;

  @override
  Future<MobileAuthSession> login({
    required String tenantId,
    required String email,
    required String password,
    required String deviceInfo,
  }) async {
    final tokens = await _withTimeout(_postJson('/auth/login', {
      'tenantId': tenantId,
      'email': email,
      'password': password,
      'deviceInfo': deviceInfo,
    }));

    final accessToken = _requireString(tokens, 'accessToken');
    final me = await _withTimeout(
      _getJson('/auth/me', authorization: 'Bearer $accessToken'),
    );

    return MobileAuthSession(
      accessToken: accessToken,
      refreshToken: _requireString(tokens, 'refreshToken'),
      tokenType: _stringOrDefault(tokens, 'tokenType', 'Bearer'),
      expiresInSeconds: _intOrDefault(tokens, 'expiresInSeconds', 0),
      userId: _intOrDefault(me, 'userId', 0),
      tenantId: _requireString(me, 'tenantId'),
      email: _requireString(me, 'email'),
      nome: _nullableString(me, 'nome'),
      tipo: _nullableString(me, 'tipo'),
      cpf: _nullableString(me, 'cpf'),
      cnpj: _nullableString(me, 'cnpj'),
      userStatus: _stringOrDefault(me, 'userStatus', 'APPROVED'),
      membershipRole: _stringOrDefault(me, 'membershipRole', 'FIELD_OPERATOR'),
      membershipStatus: _stringOrDefault(me, 'membershipStatus', 'ACTIVE'),
      permissions: (me['permissions'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(growable: false),
    );
  }

  @override
  Future<MobileAuthTokens> refresh({required String refreshToken}) async {
    final tokens = await _withTimeout(_postJson('/auth/refresh', {
      'refreshToken': refreshToken,
    }));
    return _tokensFromJson(tokens);
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    await _withTimeout(_postJson('/auth/logout', {'refreshToken': refreshToken}));
  }

  Future<MobileFirstAccessChallenge> startFirstAccess({
    required String tenantId,
    required String cpf,
    required String birthDate,
    required String identifier,
  }) async {
    final response = await _withTimeout(_postJson('/auth/first-access/start', {
      'tenantId': tenantId,
      'cpf': cpf,
      'birthDate': birthDate,
      'identifier': identifier,
    }));
    return MobileFirstAccessChallenge(
      challengeId: _requireString(response, 'challengeId'),
      deliveryHint: _stringOrDefault(
        response,
        'deliveryHint',
        'Se os dados estiverem corretos, enviaremos um codigo ao contato cadastrado.',
      ),
      expiresInSeconds: _intOrDefault(response, 'expiresInSeconds', 600),
      debugOtp: _nullableString(response, 'debugOtp'),
    );
  }

  Future<MobileAuthSession> completeFirstAccess({
    required String tenantId,
    required String challengeId,
    required String otp,
    required String newPassword,
    required String deviceInfo,
  }) async {
    final tokens = await _withTimeout(_postJson('/auth/first-access/complete', {
      'tenantId': tenantId,
      'challengeId': challengeId,
      'otp': otp,
      'newPassword': newPassword,
      'deviceInfo': deviceInfo,
    }));

    final accessToken = _requireString(tokens, 'accessToken');
    final me = await _withTimeout(
      _getJson('/auth/me', authorization: 'Bearer $accessToken'),
    );

    return MobileAuthSession(
      accessToken: accessToken,
      refreshToken: _requireString(tokens, 'refreshToken'),
      tokenType: _stringOrDefault(tokens, 'tokenType', 'Bearer'),
      expiresInSeconds: _intOrDefault(tokens, 'expiresInSeconds', 0),
      userId: _intOrDefault(me, 'userId', 0),
      tenantId: _requireString(me, 'tenantId'),
      email: _requireString(me, 'email'),
      nome: _nullableString(me, 'nome'),
      tipo: _nullableString(me, 'tipo'),
      cpf: _nullableString(me, 'cpf'),
      cnpj: _nullableString(me, 'cnpj'),
      userStatus: _stringOrDefault(me, 'userStatus', 'APPROVED'),
      membershipRole: _stringOrDefault(me, 'membershipRole', 'FIELD_OPERATOR'),
      membershipStatus: _stringOrDefault(me, 'membershipStatus', 'ACTIVE'),
      permissions: (me['permissions'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(growable: false),
    );
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final client = (_httpClientFactory ?? HttpClient.new)();
    try {
      final request = await client.postUrl(_uri(path));
      request.headers.contentType = ContentType.json;
      request.headers.set('X-Correlation-Id', _correlationId('mobile-login'));
      request.write(jsonEncode(body));
      final response = await request.close();
      return _decodeResponse(response);
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    required String authorization,
  }) async {
    final client = (_httpClientFactory ?? HttpClient.new)();
    try {
      final request = await client.getUrl(_uri(path));
      request.headers.set('Authorization', authorization);
      request.headers.set('X-Correlation-Id', _correlationId('mobile-me'));
      final response = await request.close();
      return _decodeResponse(response);
    } finally {
      client.close(force: true);
    }
  }

  Uri _uri(String path) {
    final normalizedBase =
        _resolvedBaseUrl.endsWith('/')
            ? _resolvedBaseUrl.substring(0, _resolvedBaseUrl.length - 1)
            : _resolvedBaseUrl;
    return Uri.parse('$normalizedBase$path');
  }

  Future<Map<String, dynamic>> _decodeResponse(
    HttpClientResponse response,
  ) async {
    final raw = await utf8.decoder.bind(response).join();
    final contentType = response.headers.contentType?.mimeType ?? '';
    final decoded = _tryDecodeJson(raw);

    if (decoded == null) {
      final looksLikeHtml =
          contentType.contains('text/html') ||
          raw.trimLeft().startsWith('<!DOCTYPE html') ||
          raw.trimLeft().startsWith('<html');
      if (looksLikeHtml) {
        throw MobileAuthException(
          'Resposta inesperada do servidor. Verifique a URL da API do app ou o proxy local.',
          response.statusCode >= 400 ? response.statusCode : 502,
        );
      }
      throw MobileAuthException(
        'Resposta invalida do servidor durante autenticacao.',
        response.statusCode >= 400 ? response.statusCode : 502,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded['message'] ?? decoded['error'] ?? 'Falha de autenticacao';
      throw MobileAuthException(message.toString(), response.statusCode);
    }

    return decoded;
  }

  String _correlationId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}';

  String _requireString(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      throw MobileAuthException('Resposta de autenticacao sem campo $key', 502);
    }
    return value;
  }

  String _stringOrDefault(
    Map<String, dynamic> map,
    String key,
    String defaultValue,
  ) {
    final value = map[key]?.toString().trim();
    return value == null || value.isEmpty ? defaultValue : value;
  }

  int _intOrDefault(Map<String, dynamic> map, String key, int defaultValue) {
    final value = map[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? defaultValue;
  }

  String? _nullableString(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  Map<String, dynamic>? _tryDecodeJson(String raw) {
    if (raw.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{'data': decoded};
    } on FormatException {
      return null;
    }
  }

  MobileAuthTokens _tokensFromJson(Map<String, dynamic> map) {
    return MobileAuthTokens(
      accessToken: _requireString(map, 'accessToken'),
      refreshToken: _requireString(map, 'refreshToken'),
      tokenType: _stringOrDefault(map, 'tokenType', 'Bearer'),
      expiresInSeconds: _intOrDefault(map, 'expiresInSeconds', 0),
    );
  }

  Future<T> _withTimeout<T>(Future<T> future) async {
    try {
      return await future.timeout(_requestTimeout);
    } on HandshakeException {
      throw const MobileAuthException(
        'Nao foi possivel estabelecer conexao segura com o servidor. Tente novamente em alguns instantes.',
        502,
      );
    } on TimeoutException {
      throw const MobileAuthException(
        'Tempo de resposta excedido ao falar com o servidor.',
        504,
      );
    } on SocketException {
      throw const MobileAuthException(
        'Nao foi possivel conectar ao servidor.',
        503,
      );
    } on HttpException {
      throw const MobileAuthException(
        'Falha de comunicacao com o servidor.',
        502,
      );
    }
  }
}

class MobileAuthException implements Exception {
  const MobileAuthException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
