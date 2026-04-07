class SensitiveDataRegistryService {
  const SensitiveDataRegistryService();

  List<String> items() {
    return const <String>[
      'Histórico de voz',
      'Fila de sincronização',
      'Estado de retomada da vistoria',
      'Aprendizado local da IA assistiva',
      'Logs operacionais com contexto do usuário',
    ];
  }
}
