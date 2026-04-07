class ProposalOffer {
  const ProposalOffer({
    required this.id,
    required this.valor,
    required this.expiraEm,
    required this.distanciaKm,
    required this.endereco,
    required this.proprietario,
    required this.dataHoraAgendamento,
    this.tipoImovel,
    this.subtipoImovel,
  });

  final String id;
  final String valor;
  final Duration expiraEm;
  final double distanciaKm;
  final String endereco;
  final String proprietario;
  final DateTime dataHoraAgendamento;
  final String? tipoImovel;
  final String? subtipoImovel;
}
