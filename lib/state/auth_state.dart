import 'package:flutter/foundation.dart';

import '../repositories/preferences_repository.dart';
import '../services/mobile_auth_service.dart';

enum AppAuthStatus { unauthenticated, onboarding, awaitingApproval, active }

class AuthState extends ChangeNotifier {
  AuthState(
    this._preferencesRepository, [
    MobileAuthGateway? authGateway,
    String? tenantId,
  ]) : _authGateway = authGateway ?? const MobileBackendAuthService(),
       _tenantIdOverride = tenantId,
       _loadFuture = Future<void>.value() {
    _loadFuture = _load();
  }

  final PreferencesRepository _preferencesRepository;
  final MobileAuthGateway _authGateway;
  final String? _tenantIdOverride;
  Future<void> _loadFuture;

  static const String _defaultTenantId = String.fromEnvironment(
    'APP_TENANT_ID',
    defaultValue: 'tenant-default',
  );

  static const _statusKey = 'auth_status';
  static const _userEmailKey = 'auth_user_email';
  static const _userNomeKey = 'auth_user_nome';
  static const _userTipoKey = 'auth_user_tipo';
  static const _userCpfKey = 'auth_user_cpf';
  static const _userCnpjKey = 'auth_user_cnpj';
  static const _tenantIdKey = 'auth_tenant_id';
  static const _userIdKey = 'auth_user_id';
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _accessTokenExpiresAtKey = 'auth_access_token_expires_at';
  static const _membershipRoleKey = 'auth_membership_role';
  static const _membershipStatusKey = 'auth_membership_status';
  static const _permissionsOnboardingCompletedKey =
      'auth_permissions_onboarding_completed';

  AppAuthStatus _status = AppAuthStatus.unauthenticated;
  String? _userEmail;
  String? _userNome;
  String? _userTipo;
  String? _userCpf;
  String? _userCnpj;
  String? _tenantId;
  String? _userId;
  String? _accessToken;
  String? _refreshToken;
  String? _accessTokenExpiresAt;
  String? _membershipRole;
  String? _membershipStatus;
  bool _loading = true;
  bool _permissionsOnboardingCompleted = false;

  AppAuthStatus get status => _status;
  String? get userEmail => _userEmail;
  String? get userNome => _userNome;
  String? get userTipo => _userTipo;
  String? get userCpf => _userCpf;
  String? get userCnpj => _userCnpj;
  String? get tenantId => _tenantId;
  String? get userId => _userId;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get accessTokenExpiresAt => _accessTokenExpiresAt;
  String? get membershipRole => _membershipRole;
  String? get membershipStatus => _membershipStatus;
  bool get loading => _loading;
  bool get isAuthenticated => _status != AppAuthStatus.unauthenticated;
  bool get permissionsOnboardingCompleted => _permissionsOnboardingCompleted;
  bool get requiresPermissionsOnboarding =>
      !_permissionsOnboardingCompleted && _status == AppAuthStatus.active;

  Future<void> _load() async {
    final statusStr = await _preferencesRepository.getString(_statusKey);
    if (statusStr != null) {
      _status = AppAuthStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => AppAuthStatus.unauthenticated,
      );
    }
    _userEmail = await _preferencesRepository.getString(_userEmailKey);
    _userNome = await _preferencesRepository.getString(_userNomeKey);
    _userTipo = await _preferencesRepository.getString(_userTipoKey);
    _userCpf = await _preferencesRepository.getString(_userCpfKey);
    _userCnpj = await _preferencesRepository.getString(_userCnpjKey);
    _tenantId = await _preferencesRepository.getString(_tenantIdKey);
    _userId = await _preferencesRepository.getString(_userIdKey);
    _accessToken = await _preferencesRepository.getString(_accessTokenKey);
    _refreshToken = await _preferencesRepository.getString(_refreshTokenKey);
    _accessTokenExpiresAt = await _preferencesRepository.getString(
      _accessTokenExpiresAtKey,
    );
    _membershipRole = await _preferencesRepository.getString(
      _membershipRoleKey,
    );
    _membershipStatus = await _preferencesRepository.getString(
      _membershipStatusKey,
    );
    _permissionsOnboardingCompleted =
        await _preferencesRepository.getBool(
          _permissionsOnboardingCompletedKey,
        ) ??
        false;
    if (_authGateway.isConfigured && _shouldRefreshAccessToken()) {
      try {
        await _refreshBackendSession();
      } catch (_) {
        await _clearSessionLocally();
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _ensureLoaded() async {
    if (_loading) {
      await _loadFuture;
    }
  }

  Future<void> login(String email, {String? password}) async {
    await _ensureLoaded();
    final trimmed = email.trim();
    if (trimmed.isEmpty) return;

    if (_authGateway.isConfigured) {
      await _loginWithBackend(trimmed, password?.trim() ?? '');
      notifyListeners();
      return;
    }

    _userEmail = trimmed;
    final hasProfile = _userNome != null && _userNome!.isNotEmpty;
    if (!hasProfile) {
      _status = AppAuthStatus.onboarding;
    } else if (_status == AppAuthStatus.unauthenticated) {
      _status = AppAuthStatus.active;
    }
    await _preferencesRepository.setString(_statusKey, _status.name);
    await _preferencesRepository.setString(_userEmailKey, _userEmail!);
    notifyListeners();
  }

  Future<void> _loginWithBackend(String email, String password) async {
    if (password.isEmpty) {
      throw const MobileAuthException('Informe a senha', 400);
    }

    final session = await _authGateway.login(
      tenantId: (_tenantIdOverride ?? _defaultTenantId).trim(),
      email: email,
      password: password,
      deviceInfo: 'mobile-app',
    );

    _userEmail = session.email;
    await applyBackendSession(session);
  }

  Future<void> applyBackendSession(MobileAuthSession session) async {
    await _ensureLoaded();
    _userEmail = session.email;
    _tenantId = session.tenantId;
    _userId = session.userId.toString();
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _accessTokenExpiresAt = _expiresAtFromSeconds(session.expiresInSeconds);
    _membershipRole = session.membershipRole;
    _membershipStatus = session.membershipStatus;
    _status = _statusFromBackend(session.userStatus);

    await _preferencesRepository.setString(_statusKey, _status.name);
    await _preferencesRepository.setString(_userEmailKey, _userEmail!);
    await _preferencesRepository.setString(_tenantIdKey, _tenantId!);
    await _preferencesRepository.setString(_userIdKey, _userId!);
    await _preferencesRepository.setString(_accessTokenKey, _accessToken!);
    await _preferencesRepository.setString(_refreshTokenKey, _refreshToken!);
    await _preferencesRepository.setString(
      _accessTokenExpiresAtKey,
      _accessTokenExpiresAt!,
    );
    await _preferencesRepository.setString(
      _membershipRoleKey,
      _membershipRole!,
    );
    await _preferencesRepository.setString(
      _membershipStatusKey,
      _membershipStatus!,
    );
  }

  bool _shouldRefreshAccessToken() {
    if (_status == AppAuthStatus.unauthenticated) return false;
    if ((_refreshToken ?? '').trim().isEmpty) return false;
    final expiresAt = DateTime.tryParse(_accessTokenExpiresAt ?? '');
    return expiresAt == null || !expiresAt.isAfter(DateTime.now().toUtc());
  }

  Future<void> _refreshBackendSession() async {
    final tokens = await _authGateway.refresh(refreshToken: _refreshToken!);
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    _accessTokenExpiresAt = _expiresAtFromSeconds(tokens.expiresInSeconds);
    await _preferencesRepository.setString(_accessTokenKey, _accessToken!);
    await _preferencesRepository.setString(_refreshTokenKey, _refreshToken!);
    await _preferencesRepository.setString(
      _accessTokenExpiresAtKey,
      _accessTokenExpiresAt!,
    );
  }

  String _expiresAtFromSeconds(int seconds) {
    final safeSeconds = seconds <= 0 ? 900 : seconds;
    return DateTime.now()
        .toUtc()
        .add(Duration(seconds: safeSeconds))
        .toIso8601String();
  }

  AppAuthStatus _statusFromBackend(String userStatus) {
    switch (userStatus.trim().toUpperCase()) {
      case 'APPROVED':
        return AppAuthStatus.active;
      case 'AWAITING_APPROVAL':
        return AppAuthStatus.awaitingApproval;
      default:
        return AppAuthStatus.onboarding;
    }
  }

  Future<void> completeOnboarding({
    required String nome,
    required String tipo,
    String? cpf,
    String? cnpj,
  }) async {
    await _ensureLoaded();
    _userNome = nome.trim();
    _userTipo = tipo;
    _userCpf = cpf?.trim();
    _userCnpj = cnpj?.trim();
    _status = AppAuthStatus.awaitingApproval;
    await _preferencesRepository.setString(_statusKey, _status.name);
    await _preferencesRepository.setString(_userNomeKey, _userNome!);
    await _preferencesRepository.setString(_userTipoKey, _userTipo!);
    if (_userCpf?.isNotEmpty == true) {
      await _preferencesRepository.setString(_userCpfKey, _userCpf!);
    }
    if (_userCnpj?.isNotEmpty == true) {
      await _preferencesRepository.setString(_userCnpjKey, _userCnpj!);
    }
    notifyListeners();
  }

  Future<void> activateAccount() async {
    await _ensureLoaded();
    _status = AppAuthStatus.active;
    await _preferencesRepository.setString(_statusKey, _status.name);
    notifyListeners();
  }

  Future<void> completePermissionsOnboarding() async {
    await _ensureLoaded();
    _permissionsOnboardingCompleted = true;
    await _preferencesRepository.setBool(
      _permissionsOnboardingCompletedKey,
      true,
    );
    notifyListeners();
  }

  Future<void> updateProfile({
    required String nome,
    String? cpf,
    String? cnpj,
  }) async {
    await _ensureLoaded();
    final trimmedNome = nome.trim();
    if (trimmedNome.isNotEmpty) {
      _userNome = trimmedNome;
      await _preferencesRepository.setString(_userNomeKey, _userNome!);
    }
    if (cpf != null && cpf.trim().isNotEmpty) {
      _userCpf = cpf.trim();
      await _preferencesRepository.setString(_userCpfKey, _userCpf!);
    }
    if (cnpj != null && cnpj.trim().isNotEmpty) {
      _userCnpj = cnpj.trim();
      await _preferencesRepository.setString(_userCnpjKey, _userCnpj!);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _ensureLoaded();
    final refreshToken = _refreshToken;
    if (_authGateway.isConfigured &&
        refreshToken != null &&
        refreshToken.trim().isNotEmpty) {
      try {
        await _authGateway.logout(refreshToken: refreshToken);
      } catch (_) {
        // Local logout must still clear the session if backend revocation fails.
      }
    }
    await _clearSessionLocally();
    notifyListeners();
  }

  Future<void> _clearSessionLocally() async {
    _status = AppAuthStatus.unauthenticated;
    _userEmail = null;
    _userNome = null;
    _userTipo = null;
    _userCpf = null;
    _userCnpj = null;
    _tenantId = null;
    _userId = null;
    _accessToken = null;
    _refreshToken = null;
    _accessTokenExpiresAt = null;
    _membershipRole = null;
    _membershipStatus = null;
    _permissionsOnboardingCompleted = false;
    await _preferencesRepository.setString(_statusKey, _status.name);
    await _preferencesRepository.remove(_userEmailKey);
    await _preferencesRepository.remove(_userNomeKey);
    await _preferencesRepository.remove(_userTipoKey);
    await _preferencesRepository.remove(_userCpfKey);
    await _preferencesRepository.remove(_userCnpjKey);
    await _preferencesRepository.remove(_tenantIdKey);
    await _preferencesRepository.remove(_userIdKey);
    await _preferencesRepository.remove(_accessTokenKey);
    await _preferencesRepository.remove(_refreshTokenKey);
    await _preferencesRepository.remove(_accessTokenExpiresAtKey);
    await _preferencesRepository.remove(_membershipRoleKey);
    await _preferencesRepository.remove(_membershipStatusKey);
    await _preferencesRepository.remove(_permissionsOnboardingCompletedKey);
  }

  Future<void> resetOnboardingForMock() async {
    await _ensureLoaded();
    _userNome = null;
    _userTipo = null;
    _userCpf = null;
    _userCnpj = null;
    _permissionsOnboardingCompleted = false;

    _status =
        (_userEmail?.trim().isNotEmpty ?? false)
            ? AppAuthStatus.onboarding
            : AppAuthStatus.unauthenticated;

    await _preferencesRepository.setString(_statusKey, _status.name);
    await _preferencesRepository.remove(_userNomeKey);
    await _preferencesRepository.remove(_userTipoKey);
    await _preferencesRepository.remove(_userCpfKey);
    await _preferencesRepository.remove(_userCnpjKey);
    await _preferencesRepository.remove(_permissionsOnboardingCompletedKey);

    notifyListeners();
  }
}
