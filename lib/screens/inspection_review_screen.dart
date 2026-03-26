import 'package:flutter/material.dart';

    import 'inspection_checkout_screen.dart';
    import 'overlay_camera_screen.dart';

    class InspectionReviewScreen extends StatelessWidget {
      final List<OverlayCameraCaptureResult> captures;
      final String tipoImovel;

      const InspectionReviewScreen({
        super.key,
        this.captures = const <OverlayCameraCaptureResult>[],
        this.tipoImovel = 'Urbano',
      });

      @override
      Widget build(BuildContext context) {
        final grouped = <String, List<OverlayCameraCaptureResult>>{};

        for (final item in captures) {
          final keyParts = <String>[
            if (item.macroLocal != null && item.macroLocal!.trim().isNotEmpty)
              item.macroLocal!,
            item.ambiente,
          ];

          final key = keyParts.join(' > ');
          grouped.putIfAbsent(key, () => <OverlayCameraCaptureResult>[]).add(item);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Review da vistoria')),
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
                    Text(
                      'Fotos registradas: ${captures.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      captures.isEmpty
                          ? 'Nenhuma foto foi enviada para o review ainda.'
                          : 'Revise o lote antes de seguir para o checkout.',
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
                    'Review inicial disponível.'
                    'Quando a câmera finalizar um lote de fotos, elas aparecerão agrupadas aqui.',
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
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
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
                            if (capture.elemento != null &&
                                capture.elemento!.trim().isNotEmpty)
                              capture.elemento!,
                            if (capture.material != null &&
                                capture.material!.trim().isNotEmpty)
                              capture.material!,
                            if (capture.estado != null &&
                                capture.estado!.trim().isNotEmpty)
                              capture.estado!,
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
                                  '${capture.capturedAt.hour.toString().padLeft(2, '0')}:'
                                  '${capture.capturedAt.minute.toString().padLeft(2, '0')}',
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
              FilledButton(
                onPressed: captures.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InspectionCheckoutScreen(
                              captures: captures,
                              tipoImovel: tipoImovel,
                            ),
                          ),
                        );
                      },
                child: const Text('Ir para checkout'),
              ),
            ],
          ),
        );
      }
    }
