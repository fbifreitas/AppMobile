import 'dart:ui' as ui;

import '../models/smart_execution_plan.dart';

class SmartExecutionPlanMenuOverlayService {
  const SmartExecutionPlanMenuOverlayService();

  static const SmartExecutionPlanMenuOverlayService instance =
      SmartExecutionPlanMenuOverlayService();

  static const Map<String, String> _canonicalKeys = <String, String>{
    'street': 'street',
    'rua': 'street',
    'outdoor': 'outdoor',
    'área externa': 'outdoor',
    'area externa': 'outdoor',
    'indoor': 'indoor',
    'área interna': 'indoor',
    'area interna': 'indoor',
    'front elevation': 'front_elevation',
    'fachada': 'front_elevation',
    'access': 'access',
    'acesso': 'access',
    'primary facade': 'primary_facade',
    'fachada principal': 'primary_facade',
    'entry gate': 'entry_gate',
    'portão de acesso': 'entry_gate',
    'portao de acesso': 'entry_gate',
    'overview': 'overview',
    'visão geral': 'overview',
    'visao geral': 'overview',
    'kitchen': 'kitchen',
    'cozinha': 'kitchen',
    'dining room': 'dining_room',
    'sala de jantar': 'dining_room',
    'living room': 'living_room',
    'sala de estar': 'living_room',
    'bedroom': 'bedroom',
    'dormitório': 'bedroom',
    'dormitorio': 'bedroom',
    'suite': 'suite',
    'suíte': 'suite',
    'bathroom': 'bathroom',
    'banheiro': 'bathroom',
    'laundry': 'laundry',
    'lavanderia': 'laundry',
    'balcony': 'balcony',
    'varanda': 'balcony',
    'garage space': 'garage_space',
    'vaga de garagem': 'garage_space',
    'pool': 'pool',
    'piscina': 'pool',
    'party room': 'party_room',
    'salão de festas': 'party_room',
    'salao de festas': 'party_room',
    'barbecue area': 'barbecue_area',
    'churrasqueira': 'barbecue_area',
    'playground': 'playground',
    'door': 'door',
    'porta': 'door',
    'window': 'window',
    'janela': 'window',
    'glass': 'glass',
    'vidro': 'glass',
    'floor': 'floor',
    'piso': 'floor',
    'wall': 'wall',
    'parede': 'wall',
    'ceiling': 'ceiling',
    'teto': 'ceiling',
    'paint': 'paint',
    'pintura': 'paint',
    'metal': 'metal',
    'wood': 'wood',
    'madeira': 'wood',
    'aluminum': 'aluminum',
    'alumínio': 'aluminum',
    'aluminio': 'aluminum',
    'ceramic': 'ceramic',
    'cerâmica': 'ceramic',
    'ceramica': 'ceramic',
    'concrete': 'concrete',
    'concreto': 'concrete',
    'new': 'new',
    'novo': 'new',
    'good': 'good',
    'bom': 'good',
    'regular': 'regular',
    'poor': 'poor',
    'ruim': 'poor',
    'very poor': 'very_poor',
    'péssimo': 'very_poor',
    'pessimo': 'very_poor',
  };

  static const Map<String, String> _displayPt = <String, String>{
    'street': 'Rua',
    'outdoor': 'Área externa',
    'indoor': 'Área interna',
    'front_elevation': 'Fachada',
    'access': 'Acesso',
    'primary_facade': 'Fachada principal',
    'entry_gate': 'Portão de acesso',
    'overview': 'Visão geral',
    'kitchen': 'Cozinha',
    'dining_room': 'Sala de jantar',
    'living_room': 'Sala de estar',
    'bedroom': 'Dormitório',
    'suite': 'Suíte',
    'bathroom': 'Banheiro',
    'laundry': 'Lavanderia',
    'balcony': 'Varanda',
    'garage_space': 'Vaga de garagem',
    'pool': 'Piscina',
    'party_room': 'Salão de festas',
    'barbecue_area': 'Churrasqueira',
    'playground': 'Playground',
    'door': 'Porta',
    'window': 'Janela',
    'glass': 'Vidro',
    'floor': 'Piso',
    'wall': 'Parede',
    'ceiling': 'Teto',
    'paint': 'Pintura',
    'metal': 'Metal',
    'wood': 'Madeira',
    'aluminum': 'Alumínio',
    'ceramic': 'Cerâmica',
    'concrete': 'Concreto',
    'new': 'Novo',
    'good': 'Bom',
    'regular': 'Regular',
    'poor': 'Ruim',
    'very_poor': 'Péssimo',
  };

  static const Map<String, String> _displayEn = <String, String>{
    'street': 'Street',
    'outdoor': 'Outdoor',
    'indoor': 'Indoor',
    'front_elevation': 'Front elevation',
    'access': 'Access',
    'primary_facade': 'Primary facade',
    'entry_gate': 'Entry gate',
    'overview': 'Overview',
    'kitchen': 'Kitchen',
    'dining_room': 'Dining room',
    'living_room': 'Living room',
    'bedroom': 'Bedroom',
    'suite': 'Suite',
    'bathroom': 'Bathroom',
    'laundry': 'Laundry',
    'balcony': 'Balcony',
    'garage_space': 'Garage space',
    'pool': 'Pool',
    'party_room': 'Party room',
    'barbecue_area': 'Barbecue area',
    'playground': 'Playground',
    'door': 'Door',
    'window': 'Window',
    'glass': 'Glass',
    'floor': 'Floor',
    'wall': 'Wall',
    'ceiling': 'Ceiling',
    'paint': 'Paint',
    'metal': 'Metal',
    'wood': 'Wood',
    'aluminum': 'Aluminum',
    'ceramic': 'Ceramic',
    'concrete': 'Concrete',
    'new': 'New',
    'good': 'Good',
    'regular': 'Regular',
    'poor': 'Poor',
    'very_poor': 'Very poor',
  };

  List<String> macroLocals(
    SmartExecutionPlan? plan, {
    required List<String> fallback,
  }) {
    final configuredMacroLocals = plan?.availableMacroLocations ?? const [];
    if (configuredMacroLocals.isNotEmpty) {
      final values = <String>[];
      for (final raw in configuredMacroLocals) {
        final displayValue = _display(raw);
        if (!values.contains(displayValue)) {
          values.add(displayValue);
        }
      }
      if (values.isNotEmpty) {
        return values;
      }
    }
    final composition = _safeProfiles(plan);
    if (composition.isEmpty) return fallback;
    final values = <String>[];
    for (final profile in composition) {
      if (profile.macroLocal.trim().isEmpty) continue;
      final displayValue = _display(profile.macroLocal);
      if (!values.contains(displayValue)) {
        values.add(displayValue);
      }
    }
    return values.isNotEmpty ? values : fallback;
  }

  List<String> environments(
    SmartExecutionPlan? plan, {
    required String macroLocal,
    required List<String> fallback,
  }) {
    final scoped = _profilesForMacro(plan, macroLocal);
    if (scoped.isEmpty) return fallback;
    return scoped
        .map((item) => _display(item.photoLocation))
        .toList(growable: false);
  }

  List<String> elements(
    SmartExecutionPlan? plan, {
    required String macroLocal,
    required String environment,
    required List<String> fallback,
  }) {
    final profile = _profile(plan, macroLocal: macroLocal, environment: environment);
    if (profile == null) return fallback;
    final values =
        profile.elements
            .map((item) => _display(item.element))
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false);
    return values.isNotEmpty ? values : fallback;
  }

  List<String> materials(
    SmartExecutionPlan? plan, {
    required String macroLocal,
    required String environment,
    required String element,
    required List<String> fallback,
  }) {
    final elementProfile = _element(
      plan,
      macroLocal: macroLocal,
      environment: environment,
      element: element,
    );
    if (elementProfile == null) return fallback;
    return elementProfile.materials.map(_display).toList(growable: false);
  }

  List<String> states(
    SmartExecutionPlan? plan, {
    required String macroLocal,
    required String environment,
    required String element,
    required List<String> fallback,
  }) {
    final elementProfile = _element(
      plan,
      macroLocal: macroLocal,
      environment: environment,
      element: element,
    );
    if (elementProfile == null) return fallback;
    return elementProfile.states.isNotEmpty
        ? elementProfile.states.map(_display).toList(growable: false)
        : fallback;
  }

  List<SmartExecutionCameraEnvironmentProfile> _profilesForMacro(
    SmartExecutionPlan? plan,
    String macroLocal,
  ) {
    final normalizedMacro = _normalize(macroLocal);
    return _safeProfiles(plan)
        .where((item) => _normalize(item.macroLocal) == normalizedMacro)
        .toList(growable: false);
  }

  SmartExecutionCameraEnvironmentProfile? _profile(
    SmartExecutionPlan? plan, {
    required String macroLocal,
    required String environment,
  }) {
    final normalizedEnvironment = _normalize(environment);
    for (final profile in _profilesForMacro(plan, macroLocal)) {
      if (_normalize(profile.photoLocation) == normalizedEnvironment) {
        return profile;
      }
    }
    return null;
  }

  SmartExecutionCameraElementProfile? _element(
    SmartExecutionPlan? plan, {
    required String macroLocal,
    required String environment,
    required String element,
  }) {
    final normalizedElement = _normalize(element);
    final profile = _profile(
      plan,
      macroLocal: macroLocal,
      environment: environment,
    );
    if (profile == null) return null;
    for (final item in _safeElements(profile)) {
      if (_normalize(item.element) == normalizedElement) {
        return item;
      }
    }
    return null;
  }

  List<SmartExecutionCameraEnvironmentProfile> _safeProfiles(
    SmartExecutionPlan? plan,
  ) {
    final profiles = plan?.compositionProfiles;
    if (profiles == null || profiles.isEmpty) {
      return const <SmartExecutionCameraEnvironmentProfile>[];
    }
    return profiles.whereType<SmartExecutionCameraEnvironmentProfile>().toList(
      growable: false,
    );
  }

  List<SmartExecutionCameraElementProfile> _safeElements(
    SmartExecutionCameraEnvironmentProfile profile,
  ) {
    final elements = profile.elements;
    if (elements.isEmpty) {
      return const <SmartExecutionCameraElementProfile>[];
    }
    return elements.whereType<SmartExecutionCameraElementProfile>().toList(
      growable: false,
    );
  }

  String _normalize(String value) {
    final normalized = value.trim().toLowerCase();
    return _canonicalKeys[normalized] ?? normalized;
  }

  String _display(String value) {
    final canonical = _normalize(value);
    final isPortuguese =
        ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase() == 'pt';
    final dictionary = isPortuguese ? _displayPt : _displayEn;
    return dictionary[canonical] ?? value.trim();
  }
}
