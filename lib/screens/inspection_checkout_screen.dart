import 'package:flutter/material.dart';

import 'overlay_camera_screen.dart';

class InspectionCheckoutScreen extends StatelessWidget {
  final List<OverlayCameraCaptureResult> captures;
  final String tipoImovel;

  const InspectionCheckoutScreen({
    super.key,
    required this.captures,
    required this.tipoImovel,
  });

  @override
  Widget build(BuildContext context) {
    final total = captures.length;
    final externos = captures.where((c) => c.macroLocal != 'Área interna').length;
    final internos = total - externos;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout da vistoria')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.35),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipoImovel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Total de fotos: $total', style: const TextStyle(fontSize: 12)),
                Text('Externas: $externos', style: const TextStyle(fontSize: 12)),
                Text('Internas: $internos', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Próximas evoluções desta tela',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text('• Exibir pendências obrigatórias',
              style: TextStyle(fontSize: 12)),
          const Text('• Confirmar consistência do lote antes de encerrar',
              style: TextStyle(fontSize: 12)),
          const Text('• Iniciar sincronização / fila pendente',
              style: TextStyle(fontSize: 12)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('Encerrar fluxo'),
          ),
        ],
      ),
    );
  }
}
