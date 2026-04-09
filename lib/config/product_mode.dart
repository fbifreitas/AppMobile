/// Modo de produto ativo da marca.
///
/// Define o posicionamento comercial e a linguagem da experiência.
/// Este é um valor de compile-time resolvido pelo flavor — não é alterado
/// por configuração remota em runtime.
///
/// [marketplace]: linguagem de oportunidade/proposta, aceite rápido,
///   narrativa uberizada (ex: Kaptur).
/// [corporate]: linguagem operacional institucional, ordens do dia,
///   sem narrativa de marketplace (ex: Compass Avaliações).
enum ProductMode {
  marketplace,
  corporate;

  bool get isMarketplace => this == ProductMode.marketplace;
  bool get isCorporate => this == ProductMode.corporate;
}
