class ReleaseBrandingPlanService {
  const ReleaseBrandingPlanService();

  List<String> steps() {
    return const <String>[
      'Padronizar o nome do pacote no pubspec.',
      'Padronizar o label do Android.',
      'Padronizar CFBundleName e CFBundleDisplayName no iOS.',
      'Revisar textos de permissões para produção.',
      'Manter coerência entre nome técnico e nome exibido ao usuário.',
    ];
  }
}
