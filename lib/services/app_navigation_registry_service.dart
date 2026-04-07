import '../models/app_navigation_entry.dart';

class AppNavigationRegistryService {
  const AppNavigationRegistryService();

  List<AppNavigationEntry> entries() {
    return const <AppNavigationEntry>[
      AppNavigationEntry(
        id: 'checkin',
        title: 'Fluxo principal',
        description: 'Abrir check-in e seguir para a vistoria.',
        routeKey: 'checkin',
        primary: true,
      ),
      AppNavigationEntry(
        id: 'hub',
        title: 'Hub operacional',
        description: 'Acessar todas as centrais integradas.',
        routeKey: 'hub',
        primary: true,
      ),
      AppNavigationEntry(
        id: 'snapshot',
        title: 'Saída operacional',
        description: 'Gerar snapshot resumido para acompanhamento.',
        routeKey: 'snapshot',
      ),
    ];
  }
}
