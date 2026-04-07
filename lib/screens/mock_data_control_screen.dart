import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/agenda_item.dart';
import '../models/app_message.dart';
import '../models/job_status.dart';
import '../services/checkin_dynamic_config_service.dart';
import '../services/inspection_menu_service.dart';
import '../services/inspection_sync_service.dart';
import '../state/app_state.dart';

class MockDataControlScreen extends StatefulWidget {
  const MockDataControlScreen({super.key});

  @override
  State<MockDataControlScreen> createState() => _MockDataControlScreenState();
}

class _MockDataControlScreenState extends State<MockDataControlScreen> {
  final TextEditingController _activeController = TextEditingController(
    text: '1',
  );
  final TextEditingController _completedController = TextEditingController(
    text: '1',
  );
  final TextEditingController _checkinConfigController =
      TextEditingController();
  final TextEditingController _syncResponseController = TextEditingController();
  final TextEditingController _messagesController = TextEditingController();
  final TextEditingController _agendaController = TextEditingController();
  final CheckinDynamicConfigService _checkinConfigService =
      CheckinDynamicConfigService.instance;
  final InspectionMenuService _inspectionMenuService =
      InspectionMenuService.instance;
  final InspectionSyncService _syncService = const InspectionSyncService();

  bool _checkinConfigMockEnabled = false;
  bool _syncMockEnabled = false;
  bool _busy = false;

  String _defaultOperationalConfigMock() {
    return const JsonEncoder.withIndent('  ').convert({
      'meta': {
        'packageVersion': 1,
        'packageName': 'hub_operational_unified_mock_v1',
      },
      'step1': {
        'tipos': ['Urbano', 'Rural', 'Comercial'],
        'contextos': ['Rua', 'Área externa', 'Área interna'],
        'levels': [
          {
            'id': 'contexto',
            'label': 'Contexto inicial',
            'required': true,
            'options': ['Rua', 'Área externa', 'Área interna'],
          },
          {
            'id': 'area_foto',
            'label': 'Área da foto',
            'required': true,
            'dependsOn': 'contexto',
            'options': ['Frontal', 'Lateral', 'Fundos'],
          },
        ],
        'subtiposPorTipo': {
          'Urbano': ['Apartamento', 'Casa'],
          'Rural': ['Sítio'],
          'Comercial': ['Loja'],
        },
        'levelsBySubtipo': {
          'Urbano': {
            'Apartamento': [
              {
                'id': 'torre',
                'label': 'Torre',
                'required': false,
                'options': ['Torre A', 'Torre B'],
              },
              {
                'id': 'piso',
                'label': 'Piso',
                'required': true,
                'dependsOn': 'torre',
                'options': ['Térreo', '1º', '2º', '3º'],
              },
              {
                'id': 'contexto',
                'label': 'Contexto inicial',
                'required': true,
                'options': ['Rua', 'Área externa', 'Área interna'],
              },
            ],
          },
        },
      },
      'step2': {
        'photoFieldOrder': {
          'urbano': ['fachada', 'logradouro', 'acesso_imovel'],
          'rural': ['acesso_principal', 'entrada_propriedade'],
          'comercial': ['fachada_comercial', 'acesso_comercial'],
        },
        'byTipo': {
          'urbano': {
            'tituloTela': 'Check-in etapa 2 (mock HUB)',
            'subtituloTela':
                'Menus do check-in configurados no modo desenvolvedor',
            'minFotos': 3,
            'maxFotos': 8,
            'camposFotos': [
              {
                'id': 'fachada',
                'titulo': 'Fachada',
                'icon': 'home_work_outlined',
                'obrigatorio': true,
                'cameraMacroLocal': 'Rua',
                'cameraAmbiente': 'Fachada',
                'cameraElementoInicial': 'Visão geral',
              },
              {
                'id': 'acesso_imovel',
                'titulo': 'Acesso ao imóvel',
                'icon': 'door_front_door_outlined',
                'obrigatorio': true,
                'cameraMacroLocal': 'Rua',
                'cameraAmbiente': 'Acesso ao imóvel',
                'cameraElementoInicial': 'Portão',
              },
            ],
            'gruposOpcoes': [
              {
                'id': 'infra',
                'titulo': 'Infraestrutura',
                'multiplaEscolha': true,
                'permiteObservacao': true,
                'opcoes': [
                  {'id': 'agua', 'label': 'Rede de água'},
                  {'id': 'energia', 'label': 'Energia elétrica'},
                ],
              },
            ],
          },
        },
      },
      'camera': {
        'levels': [
          {'id': 'macroLocal', 'label': 'Área da foto'},
          {'id': 'ambiente', 'label': 'Local da foto'},
          {'id': 'elemento', 'label': 'Elemento'},
          {'id': 'material', 'label': 'Material'},
          {'id': 'estado', 'label': 'Estado'},
        ],
        'byTipo': {
          'urbano': {
            'levels': [
              {'id': 'macroLocal', 'label': 'Área da foto'},
              {'id': 'ambiente', 'label': 'Local da foto'},
              {'id': 'elemento', 'label': 'Elemento'},
              {'id': 'material', 'label': 'Material'},
              {'id': 'estado', 'label': 'Estado'},
            ],
            'levelsBySubtipo': {
              'Apartamento': [
                {'id': 'torre', 'label': 'Torre', 'required': false},
                {
                  'id': 'piso',
                  'label': 'Piso',
                  'required': true,
                  'dependsOn': 'torre',
                },
                {'id': 'ambiente', 'label': 'Local da foto'},
                {'id': 'elemento', 'label': 'Elemento'},
                {'id': 'material', 'label': 'Material'},
                {'id': 'estado', 'label': 'Estado'},
              ],
            },
            'macroLocals': [
              {
                'label': 'Rua',
                'baseScore': 100,
                'pinnedTop': true,
                'ambientes': [
                  {
                    'label': 'Fachada',
                    'baseScore': 100,
                    'pinnedTop': true,
                    'elements': [
                      {
                        'label': 'Visão geral',
                        'baseScore': 100,
                        'pinnedTop': true,
                        'states': [
                          {'label': 'Novo', 'baseScore': 100},
                          {'label': 'Bom', 'baseScore': 90},
                          {'label': 'Regular', 'baseScore': 75},
                        ],
                      },
                      {
                        'label': 'Portão',
                        'baseScore': 92,
                        'materials': [
                          {'label': 'Metal', 'baseScore': 100},
                          {'label': 'Madeira', 'baseScore': 80},
                        ],
                        'states': [
                          {'label': 'Bom', 'baseScore': 100},
                          {'label': 'Regular', 'baseScore': 80},
                          {'label': 'Ruim', 'baseScore': 60},
                        ],
                      },
                    ],
                  },
                  {
                    'label': 'Acesso ao imóvel',
                    'baseScore': 92,
                    'elements': [
                      {
                        'label': 'Porta',
                        'baseScore': 100,
                        'materials': [
                          {'label': 'Madeira', 'baseScore': 100},
                          {'label': 'Metal', 'baseScore': 90},
                        ],
                        'states': [
                          {'label': 'Novo', 'baseScore': 100},
                          {'label': 'Bom', 'baseScore': 90},
                          {'label': 'Regular', 'baseScore': 75},
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        },
      },
    });
  }

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

  static const String _defaultMessagesMock =
      '[\n'
      '  {"id":"msg-dev-1","titulo":"Push mock","corpo":"Mensagem simulada pelo painel dev","jobId":"job-001","timestamp":"2026-03-30T12:00:00Z","lida":false}\n'
      ']';

  static const String _defaultAgendaMock =
      '[\n'
      '  {"id":"ag-dev-1","titulo":"Agenda mock","endereco":"Rua de Teste, 123","jobId":"job-001","data":"2026-03-31T09:00:00","status":"agendado"}\n'
      ']';

  @override
  void initState() {
    super.initState();
    _loadDeveloperMockSettings();
  }

  Future<void> _loadDeveloperMockSettings() async {
    final checkinSettings =
        await _checkinConfigService.loadDeveloperMockSettings();
    final syncSettings = await _syncService.loadDeveloperMockSettings();

    if (!mounted) return;
    setState(() {
      _checkinConfigMockEnabled = checkinSettings['enabled'] == true;
      _syncMockEnabled = syncSettings['enabled'] == true;
      _checkinConfigController.text =
          (checkinSettings['documentJson'] as String?)?.trim().isNotEmpty ==
                  true
              ? checkinSettings['documentJson'] as String
              : _defaultOperationalConfigMock();
      _syncResponseController.text =
          (syncSettings['responseJson'] as String?)?.trim().isNotEmpty == true
              ? syncSettings['responseJson'] as String
              : _defaultSyncResponseMock;
      _messagesController.text = _defaultMessagesMock;
      _agendaController.text = _defaultAgendaMock;
    });
  }

  @override
  void dispose() {
    _activeController.dispose();
    _completedController.dispose();
    _checkinConfigController.dispose();
    _syncResponseController.dispose();
    _messagesController.dispose();
    _agendaController.dispose();
    super.dispose();
  }

  Future<void> _applyPreset(int active, int completed) async {
    _activeController.text = '$active';
    _completedController.text = '$completed';
    await _applyPlan(append: false);
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
      await _inspectionMenuService.reload();
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

  Future<void> _applyAdvancedMockData() async {
    setState(() => _busy = true);
    try {
      final appState = context.read<AppState>();
      final rawMessages = jsonDecode(_messagesController.text);
      final rawAgenda = jsonDecode(_agendaController.text);

      if (rawMessages is! List || rawAgenda is! List) {
        throw const FormatException('JSON deve ser lista.');
      }

      final messages =
          rawMessages
              .map(
                (item) => _parseMessage(Map<String, dynamic>.from(item as Map)),
              )
              .toList();
      final agenda =
          rawAgenda
              .map(
                (item) =>
                    _parseAgendaItem(Map<String, dynamic>.from(item as Map)),
              )
              .toList();

      appState.setMockMensagens(messages);
      appState.setMockAgendaItems(agenda);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensagens e agenda mock aplicadas.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao aplicar JSON avançado: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  AppMessage _parseMessage(Map<String, dynamic> map) {
    return AppMessage(
      id:
          map['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: map['titulo']?.toString() ?? 'Mensagem',
      corpo: map['corpo']?.toString() ?? '',
      jobId: map['jobId']?.toString(),
      timestamp:
          DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      lida: map['lida'] == true,
    );
  }

  AgendaItem _parseAgendaItem(Map<String, dynamic> map) {
    final statusName = map['status']?.toString() ?? 'agendado';
    final status = AgendaItemStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => AgendaItemStatus.agendado,
    );

    return AgendaItem(
      id:
          map['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: map['titulo']?.toString() ?? 'Job agenda',
      endereco: map['endereco']?.toString() ?? '',
      jobId: map['jobId']?.toString(),
      data: DateTime.tryParse(map['data']?.toString() ?? '') ?? DateTime.now(),
      status: status,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.devAccessAllowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Parametrização operacional')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Acesso bloqueado. Recursos dev não ficam disponíveis sem desbloqueio autorizado.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final total = appState.jobs.length;
    final active =
        appState.jobs.where((job) => job.status != JobStatus.finalizado).length;
    final completed =
        appState.jobs.where((job) => job.status == JobStatus.finalizado).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Parametrização operacional')),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _busy ? null : () => _applyPreset(1, 0),
                child: const Text('Preset QA: 1 ativa'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : () => _applyPreset(3, 1),
                child: const Text('Preset QA: 3+1'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : () => _applyPreset(10, 5),
                child: const Text('Preset QA: 10+5'),
              ),
            ],
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
            'Pacote unificado do HUB operacional (BL-012, BL-006 e BL-051)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _checkinConfigMockEnabled,
            onChanged:
                _busy
                    ? null
                    : (value) =>
                        setState(() => _checkinConfigMockEnabled = value),
            title: const Text('Ativar config dinâmica mock (BL-012)'),
            subtitle: const Text(
              'Quando ativo, Check-in e Câmera usam o mesmo JSON local salvo no HUB operacional.',
            ),
          ),
          const Text(
            'Seções do pacote unificado:\n'
            '- step1: menus e dependências da Etapa 1\n'
            '- step2.byTipo: cards, obrigatoriedade e vínculo com captura\n'
            '- camera.byTipo: níveis da câmera (macro local, ambiente, elemento, material, estado)',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _checkinConfigController,
            minLines: 6,
            maxLines: 14,
            decoration: const InputDecoration(
              labelText: 'JSON unificado do HUB operacional',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _syncMockEnabled,
            onChanged:
                _busy
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
            label: Text(_busy ? 'Salvando...' : 'Salvar pacote operacional'),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Editor completo de cenários (BL-006)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messagesController,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'JSON de mensagens mock (BL-030)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _agendaController,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'JSON de agenda mock (BL-029)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _applyAdvancedMockData,
            icon: const Icon(Icons.data_array_outlined),
            label: const Text('Aplicar mock avançado'),
          ),
        ],
      ),
    );
  }
}
