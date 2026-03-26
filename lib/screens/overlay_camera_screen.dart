import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/inspection_session_model.dart';
import 'inspection_review_screen.dart';

class OverlayCameraCaptureResult {
  final String filePath;
  final String contextoInicial;
  final String ambiente;
  final String? elemento;
  final String? material;
  final String? estado;
  final DateTime capturedAt;
  final double latitude;
  final double longitude;
  final double accuracy;

  const OverlayCameraCaptureResult({
    required this.filePath,
    required this.contextoInicial,
    required this.ambiente,
    required this.capturedAt,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.elemento,
    this.material,
    this.estado,
  });

  GeoPointData toGeoPointData() {
    return GeoPointData(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      capturedAt: capturedAt,
    );
  }
}

class OverlayCameraScreen extends StatefulWidget {
  final String title;
  final String tipoImovel;
  final String subtipoImovel;
  final bool singleCaptureMode;
  final String? contextoInicial;
  final String? initialAmbiente;
  final String? initialElemento;

  const OverlayCameraScreen({
    super.key,
    required this.title,
    required this.tipoImovel,
    required this.subtipoImovel,
    this.singleCaptureMode = false,
    this.contextoInicial,
    this.initialAmbiente,
    this.initialElemento,
  });

  @override
  State<OverlayCameraScreen> createState() => _OverlayCameraScreenState();
}

class _OverlayCameraScreenState extends State<OverlayCameraScreen> {
  CameraController? _controller;
  bool _initializing = true;
  bool _capturing = false;
  String? _error;

  late String _contextoInicial;
  String? _ambiente;
  String? _elemento;
  String? _material;
  String? _estado;

  final List<OverlayCameraCaptureResult> _captures = [];

  static const List<String> _contextos = [
    'Rua',
    'Área externa',
    'Área interna',
  ];

  static const Map<String, List<String>> _ambientesPorContexto = {
    'Rua': [
      'Fachada',
      'Logradouro',
      'Número',
      'Portão / acesso',
      'Entorno',
    ],
    'Área externa': [
      'Garagem',
      'Quintal',
      'Jardim',
      'Condomínio',
      'Área comum externa',
      'Corredor externo',
    ],
    'Área interna': [
      'Sala',
      'Quarto',
      'Cozinha',
      'Banheiro',
      'Área de serviço',
      'Corredor',
      'Sacada',
      'Garagem interna',
    ],
  };

  static const Map<String, List<String>> _elementosPorAmbiente = {
    'Fachada': ['Visão geral', 'Porta', 'Portão', 'Número'],
    'Logradouro': ['Visão geral', 'Calçada', 'Rua', 'Acesso'],
    'Número': ['Identificação', 'Detalhe'],
    'Portão / acesso': ['Portão', 'Interfone', 'Acesso'],
    'Entorno': ['Visão geral', 'Rua', 'Vizinho'],
    'Garagem': ['Piso', 'Parede', 'Portão', 'Teto'],
    'Quintal': ['Piso', 'Parede', 'Cobertura'],
    'Jardim': ['Piso', 'Paisagismo'],
    'Condomínio': ['Entrada', 'Portaria', 'Área comum'],
    'Área comum externa': ['Piso', 'Parede', 'Cobertura'],
    'Corredor externo': ['Piso', 'Parede', 'Teto'],
    'Sala': ['Piso', 'Parede', 'Teto', 'Janela', 'Porta'],
    'Quarto': ['Piso', 'Parede', 'Teto', 'Janela', 'Porta'],
    'Cozinha': ['Piso', 'Parede', 'Teto', 'Bancada'],
    'Banheiro': ['Piso', 'Parede', 'Teto', 'Louças e metais'],
    'Área de serviço': ['Piso', 'Parede', 'Teto', 'Tanque'],
    'Corredor': ['Piso', 'Parede', 'Teto'],
    'Sacada': ['Piso', 'Parede', 'Guarda-corpo'],
    'Garagem interna': ['Piso', 'Parede', 'Teto', 'Portão'],
  };

  static const List<String> _materiais = [
    'Cerâmico',
    'Porcelanato',
    'Pintura',
    'Azulejo',
    'Madeira',
    'Metal',
    'Vidro',
    'Concreto',
  ];

  static const List<String> _estados = [
    'Novo',
    'Bom',
    'Regular',
    'Ruim',
    'Péssimo',
  ];

  @override
  void initState() {
    super.initState();
    _contextoInicial = widget.contextoInicial ?? _contextos.first;
    _ambiente = widget.initialAmbiente ??
        (_ambientesPorContexto[_contextoInicial]?.isNotEmpty == true
            ? _ambientesPorContexto[_contextoInicial]!.first
            : null);
    _elemento = widget.initialElemento;
    _setup();
  }

  Future<void> _setup() async {
    try {
      await _ensureLocationReady();
      final cameras = await availableCameras();
      final backCamera = cameras.where((c) => c.lensDirection == CameraLensDirection.back);
      final selectedCamera = backCamera.isNotEmpty ? backCamera.first : cameras.first;

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

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização não concedida.');
    }
  }

  List<String> get _ambientesAtuais =>
      _ambientesPorContexto[_contextoInicial] ?? const [];

  List<String> get _elementosAtuais =>
      _elementosPorAmbiente[_ambiente] ?? const [];

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_ambiente == null || _ambiente!.trim().isEmpty) {
      _showSnack('Selecione o ambiente em "Onde estou?" antes de capturar.');
      return;
    }

    try {
      setState(() => _capturing = true);

      await _ensureLocationReady();
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final file = await _controller!.takePicture();

      final result = OverlayCameraCaptureResult(
        filePath: file.path,
        contextoInicial: _contextoInicial,
        ambiente: _ambiente!,
        elemento: _elemento,
        material: _material,
        estado: _estado,
        capturedAt: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      if (!mounted) return;

      if (widget.singleCaptureMode) {
        Navigator.of(context).pop(result);
        return;
      }

      setState(() {
        _captures.add(result);
      });

      _showSnack('Foto adicionada ao lote. Toque em Finalizar para revisar.');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Falha ao capturar imagem: $e');
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  void _finalizeBatch() {
    if (_captures.isEmpty) {
      _showSnack('Capture pelo menos uma foto antes de finalizar.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InspectionReviewScreen(
          captures: _captures,
          tipoImovel: widget.tipoImovel,
          subtipoImovel: widget.subtipoImovel,
        ),
      ),
    );
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
            child: _controller == null ? const SizedBox.shrink() : CameraPreview(_controller!),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
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
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                widget.title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const Spacer(),
            _glassButton(
              icon: Icons.checklist_outlined,
              onTap: widget.singleCaptureMode ? null : _finalizeBatch,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _carouselCard(
          theme,
          title: 'Contexto inicial',
          values: _contextos,
          selected: _contextoInicial,
          onSelect: (value) {
            setState(() {
              _contextoInicial = value;
              final novosAmbientes = _ambientesPorContexto[_contextoInicial] ?? const [];
              _ambiente = novosAmbientes.isNotEmpty ? novosAmbientes.first : null;
              _elemento = null;
            });
          },
        ),
        const SizedBox(height: 8),
        _carouselCard(
          theme,
          title: 'Onde estou?',
          values: _ambientesAtuais,
          selected: _ambiente,
          onSelect: (value) {
            setState(() {
              _ambiente = value;
              _elemento = null;
            });
          },
        ),
        const SizedBox(height: 8),
        _carouselCard(
          theme,
          title: 'Elemento',
          values: _elementosAtuais,
          selected: _elemento,
          onSelect: (value) {
            setState(() {
              _elemento = value;
            });
          },
        ),
        const SizedBox(height: 8),
        _carouselCard(
          theme,
          title: 'Material',
          values: _materiais,
          selected: _material,
          onSelect: (value) {
            setState(() {
              _material = value;
            });
          },
        ),
        const SizedBox(height: 8),
        _carouselCard(
          theme,
          title: 'Estado',
          values: _estados,
          selected: _estado,
          onSelect: (value) {
            setState(() {
              _estado = value;
            });
          },
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Capturas no lote: ${_captures.length} • ${_contextoInicial} > ${_ambiente ?? '-'}${_elemento != null ? ' > ${_elemento!}' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
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
                width: 82,
                height: 82,
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
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : Container(
                        width: 60,
                        height: 60,
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
              icon: Icons.fact_check_outlined,
              onTap: widget.singleCaptureMode ? () => Navigator.of(context).pop() : _finalizeBatch,
            ),
          ],
        ),
      ],
    );
  }

  Widget _carouselCard(
    ThemeData theme, {
    required String title,
    required List<String> values,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final value = values[index];
                final isSelected = value == selected;
                return ChoiceChip(
                  label: Text(value),
                  selected: isSelected,
                  onSelected: (_) => onSelect(value),
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  selectedColor: const Color(0xFF16A34A),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF16A34A)
                        : Colors.white.withValues(alpha: 0.18),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
        width: 42,
        height: 42,
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
        width: 50,
        height: 50,
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