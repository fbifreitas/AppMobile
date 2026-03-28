import '../models/inspection_radius_rule.dart';

class InspectionRadiusInfo {
  const InspectionRadiusInfo({
    required this.radiusMeters,
    required this.label,
  });

  final double radiusMeters;
  final String label;
}

class InspectionRadiusService {
  const InspectionRadiusService();

  static const List<InspectionRadiusRule> _rules = [
    InspectionRadiusRule(
      tipoImovel: 'Urbano',
      subtipoImovel: 'Casa',
      radiusMeters: 500,
      label: 'Raio Casa: 500m',
    ),
    InspectionRadiusRule(
      tipoImovel: 'Urbano',
      subtipoImovel: 'Apartamento',
      radiusMeters: 150,
      label: 'Raio Apartamento: 150m',
    ),
    InspectionRadiusRule(
      tipoImovel: 'Urbano',
      subtipoImovel: 'Terreno',
      radiusMeters: 400,
      label: 'Raio Terreno: 400m',
    ),
    InspectionRadiusRule(
      tipoImovel: 'Rural',
      subtipoImovel: 'Sítio',
      radiusMeters: 1000,
      label: 'Raio Sítio: 1000m',
    ),
    InspectionRadiusRule(
      tipoImovel: 'Rural',
      subtipoImovel: 'Chácara',
      radiusMeters: 1500,
      label: 'Raio Chácara: 1500m',
    ),
    InspectionRadiusRule(
      tipoImovel: 'Rural',
      subtipoImovel: 'Fazenda',
      radiusMeters: 5000,
      label: 'Raio Fazenda: 5000m',
    ),
    InspectionRadiusRule(
      tipoImovel: 'Comercial',
      radiusMeters: 250,
      label: 'Raio Comercial: 250m',
    ),
    InspectionRadiusRule(
      tipoImovel: 'Industrial',
      radiusMeters: 600,
      label: 'Raio Industrial: 600m',
    ),
  ];

  InspectionRadiusInfo resolve({
    String? tipoImovel,
    String? subtipoImovel,
  }) {
    final tipo = (tipoImovel ?? '').trim();
    final subtipo = (subtipoImovel ?? '').trim();

    if (tipo.isEmpty) {
      return const InspectionRadiusInfo(
        radiusMeters: 100,
        label: 'Raio padrão: 100m',
      );
    }

    final exact = _rules.where((rule) {
      return rule.tipoImovel.toLowerCase() == tipo.toLowerCase() &&
          (rule.subtipoImovel ?? '').toLowerCase() == subtipo.toLowerCase();
    });

    if (exact.isNotEmpty) {
      final match = exact.first;
      return InspectionRadiusInfo(
        radiusMeters: match.radiusMeters,
        label: match.label,
      );
    }

    final byType = _rules.where(
      (rule) =>
          rule.tipoImovel.toLowerCase() == tipo.toLowerCase() &&
          rule.subtipoImovel == null,
    );

    if (byType.isNotEmpty) {
      final match = byType.first;
      return InspectionRadiusInfo(
        radiusMeters: match.radiusMeters,
        label: match.label,
      );
    }

    return const InspectionRadiusInfo(
      radiusMeters: 100,
      label: 'Raio padrão: 100m',
    );
  }

  bool isWithinRadius({
    required double distanceMeters,
    required String? tipoImovel,
    required String? subtipoImovel,
  }) {
    final info = resolve(
      tipoImovel: tipoImovel,
      subtipoImovel: subtipoImovel,
    );
    return distanceMeters <= info.radiusMeters;
  }
}
