import 'package:flutter/foundation.dart';

import '../repositories/preferences_repository.dart';

enum AppAuthStatus { unauthenticated, onboarding, awaitingApproval, active }

class AuthState extends ChangeNotifier {
  AuthState(this._preferencesRepository) : _loadFuture = Future<void>.value() {
    _loadFuture = _load();
  }

  final PreferencesRepository _preferencesRepository;
  Future<void> _loadFuture;

  static const _statusKey = 'auth_status';
  static const _userEmailKey = 'auth_user_email';
  static const _userNomeKey = 'auth_user_nome';
  static const _userTipoKey = 'auth_user_tipo';
  static const _userCpfKey = 'auth_user_cpf';
  static const _userCnpjKey = 'auth_user_cnpj';
  static const _permissionsOnboardingCompletedKey =
      'auth_permissions_onboarding_completed';

  AppAuthStatus _status = AppAuthStatus.unauthenticated;
  String? _userEmail;
  String? _userNome;
  String? _userTipo;
  String? _userCpf;
  String? _userCnpj;
  bool _loading = true;
  bool _permissionsOnboardingCompleted = false;

  AppAuthStatus get status => _status;
  String? get userEmail => _userEmail;
  String? get userNome => _userNome;
  String? get userTipo => _userTipo;
  String? get userCpf => _userCpf;
  String? get userCnpj => _userCnpj;
  bool get loading => _loading;
  bool get isAuthenticated => _status != AppAuthStatus.unauthenticated;
  bool get permissionsOnboardingCompleted => _permissionsOnboardingCompleted;
  bool get requiresPermissionsOnboarding =>
      !_permissionsOnboardingCompleted && _status != AppAuthStatus.awaitingApproval;

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
    _permissionsOnboardingCompleted =
        await _preferencesRepository.getBool(_permissionsOnboardingCompletedKey) ??
        false;
    _loading = false;
    notifyListeners();
  }

  Future<void> _ensureLoaded() async {
    if (_loading) {
      await _loadFuture;
    }
  }

  Future<void> login(String email) async {
    await _ensureLoaded();
    final trimmed = email.trim();
    if (trimmed.isEmpty) return;
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
    _status = AppAuthStatus.unauthenticated;
    _userEmail = null;
    _userNome = null;
    _userTipo = null;
    _userCpf = null;
    _userCnpj = null;
    _permissionsOnboardingCompleted = false;
    await _preferencesRepository.setString(_statusKey, _status.name);
    await _preferencesRepository.remove(_userEmailKey);
    await _preferencesRepository.remove(_userNomeKey);
    await _preferencesRepository.remove(_userTipoKey);
    await _preferencesRepository.remove(_userCpfKey);
    await _preferencesRepository.remove(_userCnpjKey);
    await _preferencesRepository.remove(_permissionsOnboardingCompletedKey);
    notifyListeners();
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
