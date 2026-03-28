import '../models/clean_code_maturity_item.dart';

class CleanCodeMaturityService {
  const CleanCodeMaturityService();

  List<CleanCodeMaturityItem> items() {
    return const <CleanCodeMaturityItem>[
      CleanCodeMaturityItem(
        id: 'screens',
        title: 'Telas críticas',
        currentLevel: 'Boa',
        targetLevel: 'Excelente',
        action: 'Continuar extraindo responsabilidades de telas pesadas para services e widgets.',
      ),
      CleanCodeMaturityItem(
        id: 'navigation',
        title: 'Navegação operacional',
        currentLevel: 'Boa',
        targetLevel: 'Excelente',
        action: 'Consolidar entradas reais das centrais e reduzir caminhos paralelos.',
      ),
      CleanCodeMaturityItem(
        id: 'tests',
        title: 'Cobertura de testes',
        currentLevel: 'Moderada',
        targetLevel: 'Forte',
        action: 'Expandir testes de service, widget e smoke tests dos fluxos principais.',
      ),
      CleanCodeMaturityItem(
        id: 'platform',
        title: 'Plataforma e release',
        currentLevel: 'Boa',
        targetLevel: 'Excelente',
        action: 'Manter identidade, permissões e checklist de release consistentes.',
      ),
      CleanCodeMaturityItem(
        id: 'ux',
        title: 'Polimento final',
        currentLevel: 'Boa',
        targetLevel: 'Excelente',
        action: 'Refinar estados vazios, feedback de erro e acessibilidade básica.',
      ),
    ];
  }
}
