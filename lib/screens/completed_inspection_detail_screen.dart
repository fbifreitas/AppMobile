import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/inspection_export_service.dart';
import '../theme/app_colors.dart';

class CompletedInspectionDetailScreen extends StatefulWidget {
  const CompletedInspectionDetailScreen({
    super.key,
    required this.job,
  });

  final Job job;

  @override
  State<CompletedInspectionDetailScreen> createState() =>
      _CompletedInspectionDetailScreenState();
}

class _CompletedInspectionDetailScreenState
    extends State<CompletedInspectionDetailScreen> {
  final InspectionExportService _exportService = InspectionExportService();

  late Future<Map<String, dynamic>?> _payloadFuture;

  @override
  void initState() {
    super.initState();
    _payloadFuture = _exportService.loadLatestPayloadForJob(widget.job.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da vistoria'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _payloadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final payload = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoBlock(
                title: 'Identificação',
                lines: [
                  'JOB #${widget.job.id}',
                  widget.job.titulo,
                  widget.job.endereco,
                  if (_nonEmptyText(widget.job.idExterno) != null)
                    'ID externo: ${_nonEmptyText(widget.job.idExterno)}',
                  if (_nonEmptyText(widget.job.protocoloExterno) != null)
                    'Protocolo: ${_nonEmptyText(widget.job.protocoloExterno)}',
                  if (widget.job.nomeCliente.trim().isNotEmpty)
                    'Cliente: ${widget.job.nomeCliente}',
                ],
              ),
              const SizedBox(height: 12),
              if (payload == null)
                const _InfoBlock(
                  title: 'Detalhes técnicos',
                  lines: [
                    'Nenhum JSON exportado encontrado para este job.',
                    'A vistoria continua disponível apenas no resumo da lista.',
                  ],
                )
              else ...[
                _InfoBlock(
                  title: 'Resumo da exportação',
                  lines: [
                    'Exportado em: ${_text(payload['exportedAt'])}',
                    'Tipo de imóvel: ${_text(_map(payload['review'])['tipoImovel'])}',
                    'Capturas: ${_list(_map(payload['review'])['capturas']).length}',
                    'Capturas revisadas: ${_list(_map(payload['review'])['capturasRevisadas']).length}',
                  ],
                ),
                const SizedBox(height: 12),
                _InfoBlock(
                  title: 'Check-in etapa 1',
                  lines: [
                    'Cliente presente: ${_yesNo(_map(payload['step1'])['clientePresente'])}',
                    'Tipo: ${_text(_map(payload['step1'])['tipoImovel'])}',
                    'Subtipo: ${_text(_map(payload['step1'])['subtipoImovel'])}',
                    'Início em: ${_text(_map(payload['step1'])['porOndeComecar'])}',
                  ],
                ),
                const SizedBox(height: 12),
                _Step2PhotosBlock(step2: _map(payload['step2'])),
                const SizedBox(height: 12),
                _InfoBlock(
                  title: 'Encerramento',
                  lines: [
                    'Observação: ${_text(_map(payload['review'])['observacao'])}',
                    'Justificativa técnica: ${_text(_map(payload['review'])['justificativaTecnica'])}',
                  ],
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  title: const Text(
                    'JSON completo (somente leitura)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    SelectableText(
                      const JsonEncoder.withIndent('  ').convert(payload),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((key, dynamic item) => MapEntry('$key', item)),
      );
    }
    return const <String, dynamic>{};
  }

  List<dynamic> _list(Object? value) {
    if (value is List) return value;
    return const <dynamic>[];
  }

  String _text(Object? value) {
    final text = value == null ? '' : '$value'.trim();
    return text.isEmpty ? 'Não informado' : text;
  }

  String _yesNo(Object? value) {
    if (value == true) return 'Sim';
    if (value == false) return 'Não';
    return 'Não informado';
  }

  String? _nonEmptyText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step2PhotosBlock extends StatelessWidget {
  const _Step2PhotosBlock({required this.step2});

  final Map<String, dynamic> step2;

  @override
  Widget build(BuildContext context) {
    final fotos = _map(step2['fotos']);
    final entries = fotos.entries.toList();

    if (entries.isEmpty) {
      return const _InfoBlock(
        title: 'Check-in etapa 2',
        lines: ['Sem registros de foto no payload da etapa 2.'],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Check-in etapa 2',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...entries.map((entry) {
            final answer = _map(entry.value);
            final title = _text(answer['titulo']);
            final hasImage = _text(answer['imagePath']) != 'Não informado';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    hasImage ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: hasImage ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((key, dynamic item) => MapEntry('$key', item)),
      );
    }
    return const <String, dynamic>{};
  }

  String _text(Object? value) {
    final text = value == null ? '' : '$value'.trim();
    return text.isEmpty ? 'Não informado' : text;
  }
}
