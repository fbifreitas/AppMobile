import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job_status.dart';
import '../state/app_state.dart';

class MockDataControlScreen extends StatefulWidget {
  const MockDataControlScreen({super.key});

  @override
  State<MockDataControlScreen> createState() => _MockDataControlScreenState();
}

class _MockDataControlScreenState extends State<MockDataControlScreen> {
  final TextEditingController _activeController = TextEditingController(text: '1');
  final TextEditingController _completedController = TextEditingController(text: '1');
  bool _busy = false;

  @override
  void dispose() {
    _activeController.dispose();
    _completedController.dispose();
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
        ],
      ),
    );
  }
}
