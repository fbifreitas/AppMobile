import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class OverlayCameraCaptureResult {
  final String filePath;
  final String ambiente;
  final DateTime capturedAt;
  final double latitude;
  final double longitude;
  final double accuracy;

  const OverlayCameraCaptureResult({
    required this.filePath,
    required this.ambiente,
    required this.capturedAt,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });
}

class OverlayCameraScreen extends StatefulWidget {
  final String title;
  final List<String> ambientes;
  final String? initialAmbiente;

  const OverlayCameraScreen({
    super.key,
    required this.title,
    required this.ambientes,
    this.initialAmbiente,
  });

  @override
  State<OverlayCameraScreen> createState() => _OverlayCameraScreenState();
}

class _OverlayCameraScreenState extends State<OverlayCameraScreen> {
  CameraController? _controller;
  bool _initializing = true;
  bool _capturing = false;
  String? _selectedAmbiente;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedAmbiente = widget.initialAmbiente ??
        (widget.ambientes.isNotEmpty ? widget.ambientes.first : null);
    _setup();
  }

  Future<void> _setup() async {
    try {
      await _ensureLocationReady();
      final cameras = await availableCameras();
      final backCameras =
          cameras.where((c) => c.lensDirection == CameraLensDirection.back);
      final selectedCamera =
          backCameras.isNotEmpty ? backCameras.first : cameras.first;

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Falha ao inicializar a câmera: $e';
      });
    }
  }

  Future<void> _ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Ative o GPS do aparelho.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Permissão de localização negada.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização negada permanentemente.');
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_selectedAmbiente == null || _selectedAmbiente!.trim().isEmpty) {
      _showSnack('Selecione o ambiente em "Onde estou?" antes de capturar.');
      return;
    }

    try {
      setState(() => _capturing = true);

      await _ensureLocationReady();
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final file = await _controller!.takePicture();

      if (!mounted) return;

      Navigator.of(context).pop(
        OverlayCameraCaptureResult(
          filePath: file.path,
          ambiente: _selectedAmbiente!,
          capturedAt: DateTime.now(),
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Falha ao capturar imagem: $e');
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_initializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _controller == null
                ? const SizedBox.shrink()
                : CameraPreview(_controller!),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _buildTopOverlay(theme),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildBottomOverlay(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            _glassButton(
              icon: Icons.arrow_back_ios_new,
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            _glassButton(
              icon: Icons.cameraswitch_outlined,
              onTap: null,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Onde estou?',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.ambientes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final ambiente = widget.ambientes[index];
                    final selected = ambiente == _selectedAmbiente;
                    return ChoiceChip(
                      label: Text(ambiente),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedAmbiente = ambiente);
                      },
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      selectedColor: const Color(0xFF16A34A),
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF16A34A)
                            : Colors.white.withValues(alpha: 0.18),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomOverlay(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            _selectedAmbiente == null
                ? 'Selecione o ambiente antes de capturar.'
                : 'Ambiente selecionado: $_selectedAmbiente',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _circleAction(
              icon: Icons.photo_library_outlined,
              onTap: () => _showSnack('Galeria permanece no fluxo atual.'),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _capturing ? null : _capture,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.96),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.15),
                    width: 3,
                  ),
                ),
                alignment: Alignment.center,
                child: _capturing
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.black12, width: 2),
                        ),
                      ),
              ),
            ),
            const Spacer(),
            _circleAction(
              icon: Icons.list_alt_outlined,
              onTap: () => _showSnack('Classificação detalhada continua no fluxo de vistoria.'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _glassButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.40),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.38),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}