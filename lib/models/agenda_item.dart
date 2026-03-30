enum AgendaItemStatus { agendado, confirmado, concluido, cancelado }

extension AgendaItemStatusLabel on AgendaItemStatus {
  String get label {
    switch (this) {
      case AgendaItemStatus.agendado:
        return 'Agendado';
      case AgendaItemStatus.confirmado:
        return 'Confirmado';
      case AgendaItemStatus.concluido:
        return 'Concluído';
      case AgendaItemStatus.cancelado:
        return 'Cancelado';
    }
  }
}

class AgendaItem {
  final String id;
  final DateTime data;
  final String titulo;
  final String endereco;
  final String? jobId;
  final AgendaItemStatus status;

  const AgendaItem({
    required this.id,
    required this.data,
    required this.titulo,
    required this.endereco,
    this.jobId,
    this.status = AgendaItemStatus.agendado,
  });

  AgendaItem copyWith({AgendaItemStatus? status}) {
    return AgendaItem(
      id: id,
      data: data,
      titulo: titulo,
      endereco: endereco,
      jobId: jobId,
      status: status ?? this.status,
    );
  }
}
