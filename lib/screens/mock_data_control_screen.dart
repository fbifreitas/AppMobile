import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job_status.dart';
import '../services/checkin_dynamic_config_service.dart';
import '../services/inspection_sync_service.dart';
import '../state/app_state.dart';

class MockDataControlScreen extends StatefulWidget {
  const MockDataControlScreen({super.key});

  @override
  State<MockDataControlScreen> createState() => _MockDataControlScreenState();
}

class _MockDataControlScreenState extends State<MockDataControlScreen> {
  final TextEditingController _activeController = TextEditingController(text: '1');
  final TextEditingController _completedController = TextEditingController(text: '1');
  final TextEditingController _checkinConfigController = TextEditingController();
  final TextEditingController _syncResponseController = TextEditingController();
  final CheckinDynamicConfigService _checkinConfigService =
      CheckinDynamicConfigService.instance;
  final InspectionSyncService _syncService = const InspectionSyncService();

  bool _checkinConfigMockEnabled = false;
  bool _syncMockEnabled = false;
  bool _busy = false;

  static const String _defaultCheckinConfigMock =
      '{\n'
      '  "step1": {\n'
      '    "tipos": ["Urbano", "Rural"],\n'
      '    "contextos": ["Rua", "Área externa", "Área interna"],\n'
      '    "subtiposPorTipo": {\n'
      '      "Urbano": ["Apartamento", "Casa"],\n'
      '      "Rural": ["Sítio"]\n'
      '    }\n'
      '  },\n'
      '  "step2": {\n'
      '    "byTipo": {\n'
      '      "urbano": {\n'
      '        "tituloTela": "Check-in etapa 2 (mock)",\n'
      '        "subtituloTela": "Menus dinâmicos do modo desenvolvedor",\n'
      '        "camposFotos": [\n'
      '          {\n'
      '            "id": "fachada",\n'
      '            "titulo": "Fachada",\n'
      '            "icon": "home_work_outlined",\n'
      '            "obrigatorio": true,\n'
      '            "cameraMacroLocal": "Rua",\n'
      '            "cameraAmbiente": "Fachada",\n'
      '            "cameraElementoInicial": "Visão geral"\n'
      '          }\n'
      '        ],\n'
      '        "gruposOpcoes": [\n'
      '          {\n'
      '            "id": "infra",\n'
      '            "titulo": "Infraestrutura",\n'
      '            "multiplaEscolha": true,\n'
      '            "permiteObservacao": true,\n'
      '            "opcoes": [\n'
      '              {"id": "agua", "label": "Rede de água"}\n'
      '            ]\n'
      '          }\n'
      '        ]\n'
      '      }\n'
      '    }\n'
      '  }\n'
      '}';

  static const String _defaultSyncResponseMock =
      '{\n'
      '  "success": true,\n'
      '  "message": "Processo criado com sucesso",\n'
      '  "process_id": "mock-process-001",\n'
      '  "process_number": "190108",\n'
      '  "data": {\n'
      '    "id": "mock-process-001",\n'
      '    "process_number": "190108",\n'
      '    "status": "Em Andamento",\n'
      '    "updated_date": "2026-03-30T18:00:00Z"\n'
      '  }\n'
      '}';

  @override
  void initState() {
    super.initState();
    _loadDeveloperMockSettings();
  }

  Future<void> _loadDeveloperMockSettings() async {
    final checkinSettings = await _checkinConfigService.loadDeveloperMockSettings();
    final syncSettings = await _syncService.loadDeveloperMockSettings();

    if (!mounted) return;
    setState(() {
      _checkinConfigMockEnabled = checkinSettings['enabled'] == true;
      _syncMockEnabled = syncSettings['enabled'] == true;
      _checkinConfigController.text =
          (checkinSettings['documentJson'] as String?)?.trim().isNotEmpty == true
              ? checkinSettings['documentJson'] as String
              : _defaultCheckinConfigMock;
      _syncResponseController.text =
          (syncSettings['responseJson'] as String?)?.trim().isNotEmpty == true
              ? syncSettings['responseJson'] as String
              : _defaultSyncResponseMock;
    });
  }

  @override
  void dispose() {
    _activeController.dispose();
    _completedController.dispose();
    _checkinConfigController.dispose();
    _syncResponseController.dispose();
    super.dispose();
  }

  int _parseCount(String value) {
    final parsed = int.tryParse(value.trim()) ?? 0;
    return parsed < 0 ? 0 : parsed;
  }

  Future<void> _applyPlan({required bool append}) async {
    final appState = context.read<AppState>();
    final active = _parseCount(_activeController.text);
    final completed = _parseCount(_completedController.text);

    setState(() => _busy = true);
    try {
      await appState.generateMockJobs(
        activeCount: active,
        completedCount: completed,
        append: append,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            append
                ? 'Cenário mock adicionado com sucesso.'
                : 'Cenário mock aplicado com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao aplicar cenário mock: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetDefaults() async {
    final appState = context.read<AppState>();
    setState(() => _busy = true);
    try {
      await appState.resetMockJobsToDefault();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados mock resetados para o padrão.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveDeveloperIntegrationMocks() async {
    setState(() => _busy = true);
    try {
      await _checkinConfigService.configureDeveloperMock(
        enabled: _checkinConfigMockEnabled,
        documentJson: _checkinConfigController.text,
      );
      await _syncService.configureDeveloperMock(
        enabled: _syncMockEnabled,
        responseJson: _syncResponseController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuração mock de integração salva com sucesso.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final total = appState.jobs.length;
    final active = appState.jobs
        .where((job) => job.status != JobStatus.finalizado)
        .length;
    final completed = appState.jobs
        .where((job) => job.status == JobStatus.finalizado)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Painel de dados mock')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Controle de cenários para QA',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Total atual: $total | Ativas: $active | Concluídas: $completed',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _activeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantidade de vistorias ativas',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _completedController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantidade de vistorias concluídas',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _busy ? null : () => _applyPlan(append: false),
            icon: const Icon(Icons.auto_fix_high),
            label: Text(_busy ? 'Aplicando...' : 'Aplicar cenário'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _applyPlan(append: true),
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Adicionar ao cenário atual'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _resetDefaults,
            icon: const Icon(Icons.restore_outlined),
            label: const Text('Resetar para mock padrão'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Regras:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            '- Deve existir no mínimo 1 vistoria mock.\n'
            '- Ativas aparecem na Home.\n'
            '- Concluídas aparecem na aba Vistorias (somente leitura).',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Mock de integração (BL-012 e BL-001)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _checkinConfigMockEnabled,
            onChanged: _busy
                ? null
                : (value) => setState(() => _checkinConfigMockEnabled = value),
            title: const Text('Ativar config dinâmica mock (BL-012)'),
            subtitle: const Text(
              'Quando ativo, Step 1/Step 2 usam JSON local do modo desenvolvedor.',
            ),
          ),
          TextField(
            controller: _checkinConfigController,
            minLines: 6,
            maxLines: 14,
            decoration: const InputDecoration(
              labelText: 'JSON da configuração dinâmica de check-in',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _syncMockEnabled,
            onChanged: _busy
                ? null
                : (value) => setState(() => _syncMockEnabled = value),
            title: const Text('Ativar resposta mock de sync final (BL-001)'),
            subtitle: const Text(
              'Quando ativo, o envio final usa resposta local simulada.',
            ),
          ),
          TextField(
            controller: _syncResponseController,
            minLines: 6,
            maxLines: 14,
            decoration: const InputDecoration(
              labelText: 'JSON de resposta mock da sincronização final',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _saveDeveloperIntegrationMocks,
            icon: const Icon(Icons.save_outlined),
            label: Text(_busy ? 'Salvando...' : 'Salvar mocks de integração'),
          ),
        ],
      ),
    );
  }
}
