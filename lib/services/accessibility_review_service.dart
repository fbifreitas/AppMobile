class AccessibilityReviewService {
  const AccessibilityReviewService();

  List<String> basicChecklist() {
    return const <String>[
      'Botões críticos com área de toque adequada.',
      'Textos principais legíveis em contraste e tamanho.',
      'Fluxos principais com mensagens claras de erro e sucesso.',
      'Ações relevantes identificáveis por ícone e texto.',
      'Centrais operacionais com hierarquia visual consistente.',
    ];
  }
}
