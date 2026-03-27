enum FieldOperationSyncStatus {
  draft,
  queued,
  syncing,
  synced,
  failed,
  conflict,
  paused,
}

extension FieldOperationSyncStatusExtension on FieldOperationSyncStatus {
  String get label {
    switch (this) {
      case FieldOperationSyncStatus.draft:
        return 'Rascunho';
      case FieldOperationSyncStatus.queued:
        return 'Na fila';
      case FieldOperationSyncStatus.syncing:
        return 'Sincronizando';
      case FieldOperationSyncStatus.synced:
        return 'Sincronizado';
      case FieldOperationSyncStatus.failed:
        return 'Falhou';
      case FieldOperationSyncStatus.conflict:
        return 'Conflito';
      case FieldOperationSyncStatus.paused:
        return 'Pausado';
    }
  }

  bool get isPending =>
      this == FieldOperationSyncStatus.queued ||
      this == FieldOperationSyncStatus.syncing ||
      this == FieldOperationSyncStatus.failed ||
      this == FieldOperationSyncStatus.conflict ||
      this == FieldOperationSyncStatus.paused;
}
