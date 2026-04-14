enum JobStatus {
  novo,
  aceito,
  aguardandoAgendamento,
  emPreparacao,
  emAndamento,
  finalizado,
  encerrado,
  recusado,
  cancelado,
}

extension JobStatusExtension on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.novo:
        return 'Novo';
      case JobStatus.aceito:
        return 'Aceito';
      case JobStatus.aguardandoAgendamento:
        return 'Aguardando Agendamento';
      case JobStatus.emPreparacao:
        return 'Em Preparação';
      case JobStatus.emAndamento:
        return 'Em Andamento';
      case JobStatus.finalizado:
        return 'Finalizado';
      case JobStatus.encerrado:
        return 'Encerrado';
      case JobStatus.recusado:
        return 'Recusado';
      case JobStatus.cancelado:
        return 'Cancelado';
    }
  }
}
