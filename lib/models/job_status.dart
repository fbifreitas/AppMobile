enum JobStatus {
  novo,
  aceito,
  aguardandoAgendamento,
  aguardandoSincronizacao,
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
        return 'New';
      case JobStatus.aceito:
        return 'Accepted';
      case JobStatus.aguardandoAgendamento:
        return 'Awaiting scheduling';
      case JobStatus.aguardandoSincronizacao:
        return 'Awaiting synchronization';
      case JobStatus.emPreparacao:
        return 'In preparation';
      case JobStatus.emAndamento:
        return 'In progress';
      case JobStatus.finalizado:
        return 'Completed';
      case JobStatus.encerrado:
        return 'Closed';
      case JobStatus.recusado:
        return 'Rejected';
      case JobStatus.cancelado:
        return 'Canceled';
    }
  }
}
