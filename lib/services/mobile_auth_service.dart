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
  });

  final String challengeId;
  final String deliveryHint;
  final int expiresInSeconds;
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
    final tokens = await _postJson('/auth/login', {
      'tenantId': tenantId,
      'email': email,
      'password': password,
      'deviceInfo': deviceInfo,
    });

    final accessToken = _requireString(tokens, 'accessToken');
    final me = await _getJson('/auth/me', authorization: 'Bearer $accessToken');

    return MobileAuthSession(
      accessToken: accessToken,
      refreshToken: _requireString(tokens, 'refreshToken'),
      tokenType: _stringOrDefault(tokens, 'tokenType', 'Bearer'),
      expiresInSeconds: _intOrDefault(tokens, 'expiresInSeconds', 0),
      userId: _intOrDefault(me, 'userId', 0),
      tenantId: _requireString(me, 'tenantId'),
      email: _requireString(me, 'email'),
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
    final tokens = await _postJson('/auth/refresh', {
      'refreshToken': refreshToken,
    });
    return _tokensFromJson(tokens);
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    await _postJson('/auth/logout', {'refreshToken': refreshToken});
  }

  Future<MobileFirstAccessChallenge> startFirstAccess({
    required String tenantId,
    required String cpf,
    required String birthDate,
    required String identifier,
  }) async {
    final response = await _postJson('/auth/first-access/start', {
      'tenantId': tenantId,
      'cpf': cpf,
      'birthDate': birthDate,
      'identifier': identifier,
    });
    return MobileFirstAccessChallenge(
      challengeId: _requireString(response, 'challengeId'),
      deliveryHint: _stringOrDefault(
        response,
        'deliveryHint',
        'Se os dados estiverem corretos, enviaremos um codigo ao contato cadastrado.',
      ),
      expiresInSeconds: _intOrDefault(response, 'expiresInSeconds', 600),
    );
  }

  Future<MobileAuthSession> completeFirstAccess({
    required String tenantId,
    required String challengeId,
    required String otp,
    required String newPassword,
    required String deviceInfo,
  }) async {
    final tokens = await _postJson('/auth/first-access/complete', {
      'tenantId': tenantId,
      'challengeId': challengeId,
      'otp': otp,
      'newPassword': newPassword,
      'deviceInfo': deviceInfo,
    });

    final accessToken = _requireString(tokens, 'accessToken');
    final me = await _getJson('/auth/me', authorization: 'Bearer $accessToken');

    return MobileAuthSession(
      accessToken: accessToken,
      refreshToken: _requireString(tokens, 'refreshToken'),
      tokenType: _stringOrDefault(tokens, 'tokenType', 'Bearer'),
      expiresInSeconds: _intOrDefault(tokens, 'expiresInSeconds', 0),
      userId: _intOrDefault(me, 'userId', 0),
      tenantId: _requireString(me, 'tenantId'),
      email: _requireString(me, 'email'),
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
    final decoded =
        raw.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(raw) as Map<String, dynamic>;

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

  MobileAuthTokens _tokensFromJson(Map<String, dynamic> map) {
    return MobileAuthTokens(
      accessToken: _requireString(map, 'accessToken'),
      refreshToken: _requireString(map, 'refreshToken'),
      tokenType: _stringOrDefault(map, 'tokenType', 'Bearer'),
      expiresInSeconds: _intOrDefault(map, 'expiresInSeconds', 0),
    );
  }
}

class MobileAuthException implements Exception {
  const MobileAuthException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
