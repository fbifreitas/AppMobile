import 'package:flutter/material.dart';

import 'overlay_camera_screen.dart';

class InspectionReviewScreen extends StatelessWidget {
  final List<OverlayCameraCaptureResult> captures;
  final String tipoImovel;
  final String subtipoImovel;

  const InspectionReviewScreen({
    super.key,
    this.captures = const [],
    this.tipoImovel = 'Urbano',
    this.subtipoImovel = 'Apartamento',
  });

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<OverlayCameraCaptureResult>>{};
    for (final item in captures) {
      final key = '${item.contextoInicial} > ${item.ambiente}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review da vistoria'),
      ),
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
                  '$tipoImovel > $subtipoImovel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fotos registradas: ${captures.length}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  captures.isEmpty
                      ? 'Nenhuma foto foi enviada para o review ainda.'
                      : 'Tudo que for obrigatório deve aparecer aqui para o usuário revisar, completar ou confirmar.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (captures.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
                ),
              ),
              child: const Text(
                'Review inicial disponível. Quando a câmera finalizar um lote de fotos, elas aparecerão agrupadas aqui.',
                style: TextStyle(fontSize: 12),
              ),
            )
          else
            ...grouped.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...entry.value.map((capture) {
                      final parts = <String>[
                        if (capture.elemento != null) capture.elemento!,
                        if (capture.material != null) capture.material!,
                        if (capture.estado != null) capture.estado!,
                      ];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              child: Icon(
                                Icons.photo_camera_back_outlined,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                parts.isEmpty
                                    ? 'Sem classificação detalhada'
                                    : parts.join(' • '),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${capture.capturedAt.hour.toString().padLeft(2, '0')}:${capture.capturedAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.orange.withValues(alpha: 0.10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pendências para próxima etapa',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                SizedBox(height: 6),
                Text(
                  '• Destacar itens obrigatórios faltantes por ambiente',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  '• Permitir editar classificação de cada foto',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  '• Permitir tirar novas fotos a partir do review',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Concluir review'),
          ),
        ],
      ),
    );
  }
}