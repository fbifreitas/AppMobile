import 'package:flutter/material.dart';

import '../models/inspection_session_model.dart';
import '../services/checkin_photo_capture_service.dart';
import 'inspection_menu_screen.dart';

class CheckinCaptureScreen extends StatefulWidget {
  final String titulo;
  final String descricao;

  const CheckinCaptureScreen({
    super.key,
    required this.titulo,
    required this.descricao,
  });

  @override
  State<CheckinCaptureScreen> createState() => _CheckinCaptureScreenState();
}

class _CheckinCaptureScreenState extends State<CheckinCaptureScreen> {
  final CheckinPhotoCaptureService _captureService = CheckinPhotoCaptureService();

  bool _busy = false;
  final List<({String path, GeoPointData geoPoint, bool fromGallery})> _captures = [];

  Future<void> _captureCamera() async {
    try {
      setState(() => _busy = true);
      final result = await _captureService.captureFromCamera();
      if (!mounted) return;

      setState(() {
        _captures.add((path: result.path, geoPoint: result.geoPoint, fromGallery: false));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto capturada com sucesso.')),
      );
    } on CheckinPhotoCaptureException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao abrir a câmera: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _captureGallery() async {
    try {
      setState(() => _busy = true);
      final result = await _captureService.captureFromGallery();
      if (!mounted) return;

      setState(() {
        _captures.add((path: result.path, geoPoint: result.geoPoint, fromGallery: true));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagem da galeria vinculada com sucesso.')),
      );
    } on CheckinPhotoCaptureException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao abrir a galeria: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueToInspection() async {
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const InspectionMenuScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.descricao,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _captureCamera,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Abrir câmera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _captureGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galeria'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Registros desta etapa',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _captures.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.dividerColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Text(
                              'Nenhuma evidência registrada nesta etapa.',
                            ),
                          )
                        : ListView.separated(
                            itemCount: _captures.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _captures[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.dividerColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      child: Icon(Icons.image_outlined),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.fromGallery ? 'Galeria' : 'Câmera',
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Lat ${item.geoPoint.latitude.toStringAsFixed(5)} • '
                                            'Lng ${item.geoPoint.longitude.toStringAsFixed(5)}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.geoPoint.capturedAt}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _continueToInspection,
                      child: const Text('Continuar para vistoria'),
                    ),
                  ),
                ],
              ),
            ),
            if (_busy)
              Container(
                color: Colors.black.withValues(alpha: 0.12),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}