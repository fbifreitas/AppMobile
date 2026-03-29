import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/checkin_step2_config.dart';

class CheckinStep1DynamicConfig {
  final List<String> tipos;
  final Map<String, List<String>> subtiposPorTipo;
  final List<String> contextos;

  const CheckinStep1DynamicConfig({
    required this.tipos,
    required this.subtiposPorTipo,
    required this.contextos,
  });
}

class CheckinDynamicConfigService {
  CheckinDynamicConfigService._();

  static final CheckinDynamicConfigService instance = CheckinDynamicConfigService._();

  static const String _baseUrl = String.fromEnvironment('APP_API_BASE_URL');
  static const String _authToken = String.fromEnvironment('APP_API_TOKEN');
  static const String _checkinConfigEndpoint = String.fromEnvironment(
    'APP_CHECKIN_CONFIG_ENDPOINT',
    defaultValue: '/api/mobile/checkin-config',
  );

  static const String _step1CacheKey = 'checkin_dynamic_step1_config_v1';

  Future<CheckinStep1DynamicConfig> loadStep1Config({
    required List<String> fallbackTipos,
    required Map<String, List<String>> fallbackSubtiposPorTipo,
    required List<String> fallbackContextos,
  }) async {
    final fallback = CheckinStep1DynamicConfig(
      tipos: List<String>.from(fallbackTipos),
      subtiposPorTipo: Map<String, List<String>>.fromEntries(
        fallbackSubtiposPorTipo.entries.map(
          (entry) => MapEntry(entry.key, List<String>.from(entry.value)),
        ),
      ),
      contextos: List<String>.from(fallbackContextos),
    );

    Map<String, dynamic>? document;
    if (_baseUrl.trim().isNotEmpty) {
      document = await _fetchDocument();
      if (document != null) {
        await _writeCache(_step1CacheKey, document);
      }
    }

    document ??= await _readCache(_step1CacheKey);

    final step1Node = _extractMap(document?['step1']) ?? document;
    if (step1Node == null) return fallback;

    final tipos = _extractStringList(step1Node['tipos']);
    final contextos = _extractStringList(step1Node['contextos']);
    final rawSubtipos = _extractMap(step1Node['subtiposPorTipo']);

    if (tipos.isEmpty || contextos.isEmpty || rawSubtipos == null || rawSubtipos.isEmpty) {
      return fallback;
    }

    final subtiposPorTipo = <String, List<String>>{};
    rawSubtipos.forEach((key, value) {
      final list = _extractStringList(value);
      if (list.isNotEmpty) {
        subtiposPorTipo[key.toString()] = list;
      }
    });

    if (subtiposPorTipo.isEmpty) return fallback;

    return CheckinStep1DynamicConfig(
      tipos: tipos,
      subtiposPorTipo: subtiposPorTipo,
      contextos: contextos,
    );
  }

  Future<CheckinStep2Config> loadStep2Config({
    required TipoImovel tipo,
    required CheckinStep2Config fallback,
  }) async {
    final cacheKey = 'checkin_dynamic_step2_${tipo.name}_v1';
    Map<String, dynamic>? document;

    if (_baseUrl.trim().isNotEmpty) {
      document = await _fetchDocument(tipo: tipo.name);
      if (document != null) {
        await _writeCache(cacheKey, document);
      }
    }

    document ??= await _readCache(cacheKey);

    final step2Node = _extractMap(document?['step2']) ?? document;
    if (step2Node == null) return fallback;

    return parseStep2ConfigMap(
      tipo: tipo,
      raw: step2Node,
      fallback: fallback,
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

      if (id.isEmpty || titulo.isEmpty || cameraMacroLocal.isEmpty || cameraAmbiente.isEmpty) {
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

    return CheckinStep2Config(
      tipoImovel: tipo,
      tituloTela: _optionalString(raw['tituloTela']) ?? fallback.tituloTela,
      subtituloTela: _optionalString(raw['subtituloTela']) ?? fallback.subtituloTela,
      camposFotos: campos,
      gruposOpcoes: grupos.isNotEmpty ? grupos : fallback.gruposOpcoes,
    );
  }

  Map<String, dynamic> serializeStep2Config(CheckinStep2Config config) {
    return {
      'tipoImovel': config.tipoImovel.name,
      'tituloTela': config.tituloTela,
      'subtituloTela': config.subtituloTela,
      'camposFotos': config.camposFotos
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
      'gruposOpcoes': config.gruposOpcoes
          .map(
            (group) => {
              'id': group.id,
              'titulo': group.titulo,
              'multiplaEscolha': group.multiplaEscolha,
              'permiteObservacao': group.permiteObservacao,
              'opcoes': group.opcoes
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
      final normalizedBase = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
      final normalizedPath = _checkinConfigEndpoint.startsWith('/')
          ? _checkinConfigEndpoint
          : '/$_checkinConfigEndpoint';
      final uri = Uri.parse('$normalizedBase$normalizedPath').replace(
        queryParameters: {
          if (tipo != null && tipo.trim().isNotEmpty) 'tipoImovel': tipo,
        },
      );

      final client = HttpClient();
      try {
        final request = await client.getUrl(uri);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (_authToken.trim().isNotEmpty) {
          request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_authToken');
        }

        final response = await request.close();
        if (response.statusCode < 200 || response.statusCode >= 300) return null;

        final body = await response.transform(utf8.decoder).join();
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

  Map<String, dynamic>? _extractMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry('$key', item));
    }
    return null;
  }

  List<String> _extractStringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => '$item'.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String? _optionalString(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
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
    if (icon == Icons.door_front_door_outlined) return 'door_front_door_outlined';
    if (icon == Icons.agriculture_outlined) return 'agriculture_outlined';
    if (icon == Icons.login_outlined) return 'login_outlined';
    if (icon == Icons.place_outlined) return 'place_outlined';
    if (icon == Icons.storefront_outlined) return 'storefront_outlined';
    if (icon == Icons.apartment_outlined) return 'apartment_outlined';
    if (icon == Icons.warehouse_outlined) return 'warehouse_outlined';
    return 'photo_camera_outlined';
  }
}
