import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/job.dart';
import '../services/inspection_export_service.dart';
import '../theme/app_colors.dart';

class CompletedInspectionDetailScreen extends StatefulWidget {
  const CompletedInspectionDetailScreen({super.key, required this.job});

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
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('Detalhes da vistoria', 'Inspection details')),
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
                title: strings.tr('Identificacao', 'Identification'),
                lines: [
                  'JOB #${widget.job.id}',
                  widget.job.titulo,
                  widget.job.endereco,
                  if (_nonEmptyText(widget.job.idExterno) != null)
                    '${strings.tr('ID externo', 'External ID')}: ${_nonEmptyText(widget.job.idExterno)}',
                  if (_nonEmptyText(widget.job.protocoloExterno) != null)
                    '${strings.tr('Protocolo', 'Protocol')}: ${_nonEmptyText(widget.job.protocoloExterno)}',
                  if (widget.job.nomeCliente.trim().isNotEmpty)
                    '${strings.tr('Cliente', 'Client')}: ${widget.job.nomeCliente}',
                ],
              ),
              const SizedBox(height: 12),
              if (payload == null)
                _InfoBlock(
                  title: strings.tr('Detalhes tecnicos', 'Technical details'),
                  lines: [
                    strings.tr(
                      'Nenhum JSON exportado encontrado para este job.',
                      'No exported JSON found for this job.',
                    ),
                    strings.tr(
                      'A vistoria continua disponivel apenas no resumo da lista.',
                      'The inspection is still available only in the list summary.',
                    ),
                  ],
                )
              else ...[
                _InfoBlock(
                  title: strings.tr('Resumo da exportacao', 'Export summary'),
                  lines: [
                    '${strings.tr('Exportado em', 'Exported at')}: ${_text(payload['exportedAt'])}',
                    '${strings.tr('Tipo de imovel', 'Property type')}: ${_text(_firstValue(_map(payload['review']), ['assetType', 'tipoImovel']))}',
                    '${strings.tr('Capturas', 'Captures')}: ${_list(_firstValue(_map(payload['review']), ['captures', 'capturas'])).length}',
                    '${strings.tr('Capturas revisadas', 'Reviewed captures')}: ${_list(_firstValue(_map(payload['review']), ['reviewedCaptures', 'capturasRevisadas'])).length}',
                  ],
                ),
                const SizedBox(height: 12),
                _InfoBlock(
                  title: strings.tr('Check-in etapa 1', 'Check-in step 1'),
                  lines: [
                    '${strings.tr('Cliente presente', 'Client present')}: ${_yesNo(_firstValue(_map(payload['step1']), ['contactPresent', 'clientePresente']))}',
                    '${strings.tr('Tipo', 'Type')}: ${_text(_firstValue(_map(payload['step1']), ['assetType', 'tipoImovel']))}',
                    '${strings.tr('Subtipo', 'Subtype')}: ${_text(_firstValue(_map(payload['step1']), ['assetSubtype', 'subtipoImovel']))}',
                    '${strings.tr('Inicio em', 'Started at')}: ${_text(_firstValue(_map(payload['step1']), ['entryPoint', 'porOndeComecar']))}',
                  ],
                ),
                const SizedBox(height: 12),
                _Step2PhotosBlock(step2: _map(payload['step2'])),
                const SizedBox(height: 12),
                _InfoBlock(
                  title: strings.tr('Encerramento', 'Closing'),
                  lines: [
                    '${strings.tr('Observacao', 'Note')}: ${_text(_firstValue(_map(payload['review']), ['note', 'observacao']))}',
                    '${strings.tr('Justificativa tecnica', 'Technical justification')}: ${_text(_firstValue(_map(payload['review']), ['technicalJustification', 'justificativaTecnica']))}',
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
                  title: Text(
                    strings.tr(
                      'JSON completo (somente leitura)',
                      'Full JSON (read-only)',
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
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

  Object? _firstValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key)) {
        return map[key];
      }
    }
    return null;
  }

  String _text(Object? value) {
    final strings = AppStrings.of(context);
    final text = value == null ? '' : '$value'.trim();
    return text.isEmpty ? strings.tr('Nao informado', 'Not provided') : text;
  }

  String _yesNo(Object? value) {
    final strings = AppStrings.of(context);
    if (value == true) return strings.tr('Sim', 'Yes');
    if (value == false) return strings.tr('Nao', 'No');
    return strings.tr('Nao informado', 'Not provided');
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
  const _InfoBlock({required this.title, required this.lines});

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
    final strings = AppStrings.of(context);
    final fotos = _map(step2['fotos']);
    final entries = fotos.entries.toList();

    if (entries.isEmpty) {
      return _InfoBlock(
        title: strings.tr('Check-in etapa 2', 'Check-in step 2'),
        lines: [
          strings.tr(
            'Sem registros de foto no payload da etapa 2.',
            'No photo records in the step 2 payload.',
          ),
        ],
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
          Text(
            strings.tr('Check-in etapa 2', 'Check-in step 2'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...entries.map((entry) {
            final answer = _map(entry.value);
            final title = _text(context, answer['titulo']);
            final hasImage =
                _text(context, answer['imagePath']) !=
                strings.tr('Nao informado', 'Not provided');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    hasImage
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
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

  String _text(BuildContext context, Object? value) {
    final strings = AppStrings.of(context);
    final text = value == null ? '' : '$value'.trim();
    return text.isEmpty ? strings.tr('Nao informado', 'Not provided') : text;
  }
}
