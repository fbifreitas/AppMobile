class AppMessage {
  final String id;
  final String titulo;
  final String corpo;
  final String? jobId;
  final DateTime timestamp;
  bool lida;

  AppMessage({
    required this.id,
    required this.titulo,
    required this.corpo,
    this.jobId,
    required this.timestamp,
    this.lida = false,
  });
}
