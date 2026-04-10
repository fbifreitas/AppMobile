import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/checkin_step2_model.dart';
import '../config/checkin_step2_config.dart';
import '../config/inspection_menu_package.dart';
import 'integration_context_service.dart';
import 'inspection_requirement_policy_service.dart';

class CheckinStep1DynamicConfig {
  final List<String> tipos;
  final Map<String, List<String>> subtiposPorTipo;
  final List<String> contextos;
  final List<ConfigLevelDefinition> levels;
  final Map<String, List<ConfigLevelDefinition>> levelsByTipoSubtipo;

  const CheckinStep1DynamicConfig({
    required this.tipos,
    required this.subtiposPorTipo,
    required this.contextos,
    required this.levels,
    required this.levelsByTipoSubtipo,
  });

  List<ConfigLevelDefinition> levelsFor({
    required String tipo,
    required String subtipo,
  }) {
    final typedKey =
        '${tipo.trim().toLowerCase()}::${subtipo.trim().toLowerCase()}';
    final bySubtype = levelsByTipoSubtipo[typedKey];
    if (bySubtype != null && bySubtype.isNotEmpty) {
      return bySubtype;
    }
    return levels;
  }
}

class CheckinDynamicConfigService {
  CheckinDynamicConfigService({
    String? baseUrl,
    String? authToken,
    String? checkinConfigEndpoint,
    String? configSigningHmacKey,
    HttpClient Function()? httpClientFactory,
    IntegrationContextService? integrationContextService,
  }) : _baseUrlOverride = baseUrl,
       _authTokenOverride = authToken,
       _checkinConfigEndpointOverride = checkinConfigEndpoint,
       _configSigningHmacKeyOverride = configSigningHmacKey,
       _httpClientFactory = httpClientFactory,
       _integrationContextService =
           integrationContextService ?? const IntegrationContextService();

  static final CheckinDynamicConfigService instance =
      CheckinDynamicConfigService();
  static const InspectionRequirementPolicyService _requirementPolicy =
      InspectionRequirementPolicyService.instance;

  static const String _baseUrl = String.fromEnvironment('APP_API_BASE_URL');
  static const String _authToken = String.fromEnvironment('APP_API_TOKEN');
  static const String _checkinConfigEndpoint = String.fromEnvironment(
    'APP_CHECKIN_CONFIG_ENDPOINT',
    defaultValue: '/api/mobile/checkin-config',
  );
  static const String _configSigningHmacKey = String.fromEnvironment(
    'APP_CHECKIN_CONFIG_SIGNING_HMAC_KEY',
    defaultValue: '',
  );

  static const String _step1CacheKey = 'checkin_dynamic_step1_config_v1';
  static const String _step1VersionKey = 'checkin_dynamic_step1_version_v1';
  static const String _devMockEnabledKey = 'dev_mock_checkin_config_enabled_v1';
  static const String _devMockDocumentKey =
      'dev_mock_checkin_config_document_v1';
  static const String _versionFallback = 'v1-default';

  final String? _baseUrlOverride;
  final String? _authTokenOverride;
  final String? _checkinConfigEndpointOverride;
  final String? _configSigningHmacKeyOverride;
  final HttpClient Function()? _httpClientFactory;
  final IntegrationContextService _integrationContextService;

  String get _resolvedBaseUrl => (_baseUrlOverride ?? _baseUrl).trim();
  String get _resolvedAuthToken => (_authTokenOverride ?? _authToken).trim();
  String get _resolvedCheckinConfigEndpoint =>
      (_checkinConfigEndpointOverride ?? _checkinConfigEndpoint).trim();
  String get _resolvedConfigSigningHmacKey =>
      (_configSigningHmacKeyOverride ?? _configSigningHmacKey).trim();

  Future<void> configureDeveloperMock({
    required bool enabled,
    String? documentJson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devMockEnabledKey, enabled);

    final normalized = documentJson?.trim() ?? '';
    if (normalized.isEmpty) {
      await prefs.remove(_devMockDocumentKey);
      return;
    }

    try {
      final decoded = jsonDecode(normalized);
      final map = _extractMap(decoded);
      if (map == null) {
        await prefs.remove(_devMockDocumentKey);
        return;
      }
      await prefs.setString(_devMockDocumentKey, jsonEncode(map));
    } catch (_) {
      await prefs.remove(_devMockDocumentKey);
    }
  }

  Future<Map<String, dynamic>> loadDeveloperMockSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_devMockEnabledKey) ?? false,
      'documentJson': prefs.getString(_devMockDocumentKey) ?? '',
    };
  }

  Future<Map<String, dynamic>?> loadDeveloperMockDocument() async {
    final document = await _readDeveloperMockDocument();
    return document == null ? null : Map<String, dynamic>.from(document);
  }

  Future<CheckinStep1DynamicConfig> loadStep1Config({
    required List<String> fallbackTipos,
    required Map<String, List<String>> fallbackSubtiposPorTipo,
    required List<String> fallbackContextos,
  }) async {
    final fallbackLevels = <ConfigLevelDefinition>[
      ConfigLevelDefinition(
        id: 'contexto',
        label: 'Por onde deseja começar?',
        required: true,
        dependsOn: null,
        options: List<String>.from(fallbackContextos),
      ),
    ];

    final fallback = CheckinStep1DynamicConfig(
      tipos: List<String>.from(fallbackTipos),
      subtiposPorTipo: Map<String, List<String>>.fromEntries(
        fallbackSubtiposPorTipo.entries.map(
          (entry) => MapEntry(entry.key, List<String>.from(entry.value)),
        ),
      ),
      contextos: List<String>.from(fallbackContextos),
      levels: fallbackLevels,
      levelsByTipoSubtipo: const {},
    );

    Map<String, dynamic>? document = await _readDeveloperMockDocument();
    if (document == null) {
      if (_resolvedBaseUrl.isNotEmpty) {
        final fetched = await _fetchDocument();
        if (fetched != null) {
          final fetchedVersion = _resolveDocumentVersion(fetched);
          final currentVersion = await _readCachedVersion(_step1VersionKey);
          if (fetchedVersion != null &&
              currentVersion != null &&
              fetchedVersion == currentVersion) {
            document = await _readCache(_step1CacheKey) ?? fetched;
          } else {
            document = fetched;
          }
          await _writeCache(_step1CacheKey, document);
          await _writeCachedVersion(_step1VersionKey, fetchedVersion);
        }
      }

      document ??= await _readCache(_step1CacheKey);
    }

    if (document == null) {
      return fallback;
    }

    final package = InspectionMenuPackage.fromJson(document);
    final step1Config = package.step1Config;
    if (step1Config == null || !step1Config.isValid) return fallback;

    return CheckinStep1DynamicConfig(
      tipos: List<String>.from(step1Config.tipos),
      subtiposPorTipo: Map<String, List<String>>.fromEntries(
        step1Config.subtiposPorTipo.entries.map(
          (entry) => MapEntry(entry.key, List<String>.from(entry.value)),
        ),
      ),
      contextos: List<String>.from(step1Config.contextos),
      levels:
          step1Config.levels.isNotEmpty
              ? List<ConfigLevelDefinition>.from(step1Config.levels)
              : fallbackLevels,
      levelsByTipoSubtipo: Map<String, List<ConfigLevelDefinition>>.fromEntries(
        step1Config.levelsBySubtipo.entries.map(
          (entry) => MapEntry(
            entry.key,
            List<ConfigLevelDefinition>.from(entry.value),
          ),
        ),
      ),
    );
  }

  Future<CheckinStep2Config> loadStep2Config({
    required TipoImovel tipo,
    required CheckinStep2Config fallback,
  }) async {
    final cacheKey = _step2CacheKey(tipo);
    final versionKey = _step2VersionKey(tipo);
    Map<String, dynamic>? document = await _readDeveloperMockDocument();

    if (document == null) {
      if (_resolvedBaseUrl.isNotEmpty) {
        final fetched = await _fetchDocument(tipo: tipo.name);
        if (fetched != null) {
          final fetchedVersion = _resolveDocumentVersion(fetched);
          final currentVersion = await _readCachedVersion(versionKey);
          if (fetchedVersion != null &&
              currentVersion != null &&
              fetchedVersion == currentVersion) {
            document = await _readCache(cacheKey) ?? fetched;
          } else {
            document = fetched;
          }
          await _writeCache(cacheKey, document);
          await _writeCachedVersion(versionKey, fetchedVersion);
        }
      }

      document ??= await _readCache(cacheKey);
    }

    final step2Node =
        document == null
            ? null
            : InspectionMenuPackage.fromJson(document).step2For(tipo.name);
    if (step2Node == null) return fallback;

    return parseStep2ConfigMap(tipo: tipo, raw: step2Node, fallback: fallback);
  }

  CheckinStep2Config resolveStoredStep2Config({
    required TipoImovel tipo,
    required Map<String, dynamic> inspectionRecoveryPayload,
  }) {
    final fallback = CheckinStep2Configs.byTipo(tipo);
    final dynamicStep2Raw = inspectionRecoveryPayload['step2Config'];
    if (dynamicStep2Raw is! Map) {
      return fallback;
    }

    return parseStep2ConfigMap(
      tipo: tipo,
      raw: Map<String, dynamic>.from(
        dynamicStep2Raw.map((key, value) => MapEntry('$key', value)),
      ),
      fallback: fallback,
    );
  }

  CheckinStep2Model restoreStep2Model({
    required TipoImovel tipo,
    required Map<String, dynamic> step2Payload,
  }) {
    if (step2Payload.isEmpty) {
      return CheckinStep2Model.empty(tipo);
    }

    try {
      return CheckinStep2Model.fromMap(step2Payload);
    } catch (_) {
      return CheckinStep2Model.empty(tipo);
    }
  }

  int countCompletedMandatoryFields({
    required TipoImovel tipo,
    required Map<String, dynamic> inspectionRecoveryPayload,
    required Map<String, dynamic> step2Payload,
  }) {
    final config = resolveStoredStep2Config(
      tipo: tipo,
      inspectionRecoveryPayload: inspectionRecoveryPayload,
    );
    final model = restoreStep2Model(tipo: tipo, step2Payload: step2Payload);

    return _requirementPolicy.countCompletedMandatoryFields(
      fields: config.camposFotos,
      persistedModel: model,
    );
  }

  CheckinStep2Config parseStep2ConfigMap({
    required TipoImovel tipo,
    required Map<String, dynamic> raw,
    required CheckinStep2Config fallback,
  }) {
    final camposRaw = (raw['camposFotos'] as List?) ?? const [];
    final gruposRaw = (raw['gruposOpcoes'] as List?) ?? const [];

    final campos = <CheckinStep2PhotoFieldConfig>[];
    for (final value in camposRaw) {
      final map = _extractMap(value);
      if (map == null) continue;

      final id = '${map['id'] ?? ''}'.trim();
      final titulo = '${map['titulo'] ?? ''}'.trim();
      final cameraMacroLocal = '${map['cameraMacroLocal'] ?? ''}'.trim();
      final cameraAmbiente = '${map['cameraAmbiente'] ?? ''}'.trim();

      if (id.isEmpty ||
          titulo.isEmpty ||
          cameraMacroLocal.isEmpty ||
          cameraAmbiente.isEmpty) {
        continue;
      }

      campos.add(
        CheckinStep2PhotoFieldConfig(
          id: id,
          titulo: titulo,
          icon: _iconFromName('${map['icon'] ?? ''}'),
          obrigatorio: (map['obrigatorio'] as bool?) ?? false,
          cameraMacroLocal: cameraMacroLocal,
          cameraAmbiente: cameraAmbiente,
          cameraElementoInicial: _optionalString(map['cameraElementoInicial']),
        ),
      );
    }

    final grupos = <CheckinStep2OptionGroupConfig>[];
    for (final value in gruposRaw) {
      final map = _extractMap(value);
      if (map == null) continue;

      final id = '${map['id'] ?? ''}'.trim();
      final titulo = '${map['titulo'] ?? ''}'.trim();
      if (id.isEmpty || titulo.isEmpty) continue;

      final opcoesRaw = (map['opcoes'] as List?) ?? const [];
      final opcoes = <CheckinStep2OptionItemConfig>[];
      for (final item in opcoesRaw) {
        final optMap = _extractMap(item);
        if (optMap == null) continue;

        final optId = '${optMap['id'] ?? ''}'.trim();
        final label = '${optMap['label'] ?? ''}'.trim();
        if (optId.isEmpty || label.isEmpty) continue;

        opcoes.add(CheckinStep2OptionItemConfig(id: optId, label: label));
      }

      if (opcoes.isEmpty) continue;

      grupos.add(
        CheckinStep2OptionGroupConfig(
          id: id,
          titulo: titulo,
          opcoes: opcoes,
          multiplaEscolha: (map['multiplaEscolha'] as bool?) ?? true,
          permiteObservacao: (map['permiteObservacao'] as bool?) ?? false,
        ),
      );
    }

    if (campos.isEmpty) return fallback;

    final minFotos = _parseNonNegativeInt(raw['minFotos']) ?? fallback.minFotos;
    final maxFotos = _parseNonNegativeInt(raw['maxFotos']) ?? fallback.maxFotos;
    final normalizedMaxFotos =
        maxFotos != null && maxFotos > 0 && maxFotos < minFotos
            ? minFotos
            : maxFotos;

    return CheckinStep2Config(
      tipoImovel: tipo,
      tituloTela: _optionalString(raw['tituloTela']) ?? fallback.tituloTela,
      subtituloTela:
          _optionalString(raw['subtituloTela']) ?? fallback.subtituloTela,
      minFotos: minFotos,
      maxFotos: normalizedMaxFotos,
      visivelNoFluxo:
          _parseBoolean(
            raw['visivel'] ?? raw['visible'] ?? raw['exibir'] ?? raw['enabled'],
          ) ??
          fallback.visivelNoFluxo,
      obrigatoriaNoFluxo:
          _parseBoolean(
            raw['obrigatoria'] ?? raw['obrigatorio'] ?? raw['required'],
          ) ??
          fallback.obrigatoriaNoFluxo,
      camposFotos: campos,
      gruposOpcoes: grupos.isNotEmpty ? grupos : fallback.gruposOpcoes,
    );
  }

  Map<String, dynamic> serializeStep2Config(CheckinStep2Config config) {
    return {
      'tipoImovel': config.tipoImovel.name,
      'tituloTela': config.tituloTela,
      'subtituloTela': config.subtituloTela,
      'minFotos': config.minFotos,
      'maxFotos': config.maxFotos,
      'visivel': config.visivelNoFluxo,
      'obrigatoria': config.obrigatoriaNoFluxo,
      'camposFotos':
          config.camposFotos
              .map(
                (field) => {
                  'id': field.id,
                  'titulo': field.titulo,
                  'icon': _iconToName(field.icon),
                  'obrigatorio': field.obrigatorio,
                  'cameraMacroLocal': field.cameraMacroLocal,
                  'cameraAmbiente': field.cameraAmbiente,
                  'cameraElementoInicial': field.cameraElementoInicial,
                },
              )
              .toList(),
      'gruposOpcoes':
          config.gruposOpcoes
              .map(
                (group) => {
                  'id': group.id,
                  'titulo': group.titulo,
                  'multiplaEscolha': group.multiplaEscolha,
                  'permiteObservacao': group.permiteObservacao,
                  'opcoes':
                      group.opcoes
                          .map(
                            (option) => {
                              'id': option.id,
                              'label': option.label,
                            },
                          )
                          .toList(),
                },
              )
              .toList(),
    };
  }

  Future<Map<String, dynamic>?> _fetchDocument({String? tipo}) async {
    try {
      final context = await _integrationContextService.buildContext();
      final normalizedBase =
          _resolvedBaseUrl.endsWith('/')
              ? _resolvedBaseUrl.substring(0, _resolvedBaseUrl.length - 1)
              : _resolvedBaseUrl;
      final normalizedPath =
          _resolvedCheckinConfigEndpoint.startsWith('/')
              ? _resolvedCheckinConfigEndpoint
              : '/$_resolvedCheckinConfigEndpoint';
      final uri = Uri.parse('$normalizedBase$normalizedPath').replace(
        queryParameters: {
          if (tipo != null && tipo.trim().isNotEmpty) 'tipoImovel': tipo,
        },
      );

      final client = (_httpClientFactory ?? HttpClient.new)();
      try {
        final request = await client.getUrl(uri);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        request.headers.set('X-Tenant-Id', context.tenantId);
        request.headers.set('X-Correlation-Id', context.correlationId);
        request.headers.set('X-Actor-Id', context.actorId);
        request.headers.set('X-Api-Version', context.apiVersion);
        final authToken =
            _resolvedAuthToken.isNotEmpty
                ? _resolvedAuthToken
                : context.authToken;
        if (authToken.isNotEmpty) {
          request.headers.set(
            HttpHeaders.authorizationHeader,
            'Bearer $authToken',
          );
        }

        final response = await request.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }

        final body = await response.transform(utf8.decoder).join();
        if (!_isRemoteSignatureValid(response: response, payload: body)) {
          return null;
        }
        final decoded = jsonDecode(body);
        return _extractMap(decoded);
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, Map<String, dynamic> value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(value));
    } catch (_) {
      // Keep working with in-memory fallback when cache write fails.
    }
  }

  Future<Map<String, dynamic>?> _readCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      return _extractMap(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedVersion(String key, String? version) async {
    try {
      if (version == null || version.trim().isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, version.trim());
    } catch (_) {
      // Keep flow resilient when cache write fails.
    }
  }

  Future<String?> _readCachedVersion(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  String _step2CacheKey(TipoImovel tipo) {
    return 'checkin_dynamic_step2_${tipo.name}_v1';
  }

  String _step2VersionKey(TipoImovel tipo) {
    return 'checkin_dynamic_step2_${tipo.name}_version_v1';
  }

  String? _resolveDocumentVersion(Map<String, dynamic> document) {
    final fromVersion = _optionalString(document['version']);
    if (fromVersion != null) return fromVersion;
    final packageVersion = document['packageVersion'];
    if (packageVersion is int) return 'pkg-$packageVersion';
    return _versionFallback;
  }

  Future<Map<String, dynamic>?> _readDeveloperMockDocument() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_devMockEnabledKey) ?? false;
      if (!enabled) return null;

      final raw = prefs.getString(_devMockDocumentKey);
      if (raw == null || raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      return _extractMap(decoded);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _extractMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry('$key', item));
    }
    return null;
  }

  String? _optionalString(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  int? _parseNonNegativeInt(Object? value) {
    if (value is int) {
      return value < 0 ? 0 : value;
    }
    if (value is num) {
      final parsed = value.toInt();
      return parsed < 0 ? 0 : parsed;
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed == null) return null;
      return parsed < 0 ? 0 : parsed;
    }
    return null;
  }

  bool? _parseBoolean(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return null;
  }

  bool _isRemoteSignatureValid({
    required HttpClientResponse response,
    required String payload,
  }) {
    final signingKey = _resolvedConfigSigningHmacKey;
    if (signingKey.isEmpty) {
      return true;
    }

    final signatureHeader =
        response.headers.value('X-Config-Signature')?.trim() ?? '';
    final algorithmHeader =
        response.headers
            .value('X-Config-Signature-Alg')
            ?.trim()
            .toLowerCase() ??
        '';

    if (signatureHeader.isEmpty || algorithmHeader != 'hmac-sha256') {
      return false;
    }

    final expectedSignature = base64Encode(
      Hmac(sha256, utf8.encode(signingKey)).convert(utf8.encode(payload)).bytes,
    );

    return _constantTimeEquals(signatureHeader, expectedSignature);
  }

  bool _constantTimeEquals(String left, String right) {
    final leftBytes = utf8.encode(left);
    final rightBytes = utf8.encode(right);
    if (leftBytes.length != rightBytes.length) {
      return false;
    }

    var diff = 0;
    for (var i = 0; i < leftBytes.length; i++) {
      diff |= leftBytes[i] ^ rightBytes[i];
    }
    return diff == 0;
  }

  IconData _iconFromName(String rawIcon) {
    switch (rawIcon.trim().toLowerCase()) {
      case 'home_work_outlined':
        return Icons.home_work_outlined;
      case 'map_outlined':
        return Icons.map_outlined;
      case 'door_front_door_outlined':
        return Icons.door_front_door_outlined;
      case 'agriculture_outlined':
        return Icons.agriculture_outlined;
      case 'login_outlined':
        return Icons.login_outlined;
      case 'place_outlined':
        return Icons.place_outlined;
      case 'storefront_outlined':
        return Icons.storefront_outlined;
      case 'apartment_outlined':
        return Icons.apartment_outlined;
      case 'warehouse_outlined':
        return Icons.warehouse_outlined;
      default:
        return Icons.photo_camera_outlined;
    }
  }

  String _iconToName(IconData icon) {
    if (icon == Icons.home_work_outlined) return 'home_work_outlined';
    if (icon == Icons.map_outlined) return 'map_outlined';
    if (icon == Icons.door_front_door_outlined) {
      return 'door_front_door_outlined';
    }
    if (icon == Icons.agriculture_outlined) return 'agriculture_outlined';
    if (icon == Icons.login_outlined) return 'login_outlined';
    if (icon == Icons.place_outlined) return 'place_outlined';
    if (icon == Icons.storefront_outlined) return 'storefront_outlined';
    if (icon == Icons.apartment_outlined) return 'apartment_outlined';
    if (icon == Icons.warehouse_outlined) return 'warehouse_outlined';
    return 'photo_camera_outlined';
  }
}
