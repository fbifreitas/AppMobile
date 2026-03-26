import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/inspection_session_model.dart';
import '../services/inspection_menu_service.dart';
import 'inspection_review_screen.dart';

class OverlayCameraCaptureResult {
  final String filePath;
  final String? macroLocal;
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
    required this.ambiente,
    required this.capturedAt,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.macroLocal,
    this.elemento,
    this.material,
    this.estado,
  });

  GeoPointData toGeoPointData() => GeoPointData(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        capturedAt: capturedAt,
      );
}

class OverlayCameraScreen extends StatefulWidget {
  final String title;
  final String tipoImovel;
  final String subtipoImovel;
  final bool singleCaptureMode;
  final String? preselectedMacroLocal;
  final String? initialAmbiente;
  final String? initialElemento;
  final bool cameFromCheckinStep1;

  const OverlayCameraScreen({
    super.key,
    required this.title,
    required this.tipoImovel,
    required this.subtipoImovel,
    this.singleCaptureMode = false,
    this.preselectedMacroLocal,
    this.initialAmbiente,
    this.initialElemento,
    this.cameFromCheckinStep1 = false,
  });

  @override
  State<OverlayCameraScreen> createState() => _OverlayCameraScreenState();
}

class _OverlayCameraScreenState extends State<OverlayCameraScreen> {
  final InspectionMenuService _menuService = InspectionMenuService.instance;

  CameraController? _controller;
  bool _initializing = true;
  bool _capturing = false;
  bool _loadingMenus = true;
  String? _error;

  String? _macroLocal;
  String? _ambiente;
  String? _elemento;
  String? _material;
  String? _estado;

  List<String> _macroLocais = const [];
  List<String> _ambientesAtuais = const [];
  List<String> _elementosAtuais = const [];
  List<String> _recentAmbientes = const [];
  List<String> _recentElementos = const [];
  PredictedSelection? _predictedSelection;
  String? _contextSuggestionSummary;

  final List<OverlayCameraCaptureResult> _captures = [];

  static const Map<String, List<String>> _materiaisPorElemento = {
    'Piso': ['Cerâmico', 'Porcelanato', 'Madeira', 'Concreto'],
    'Parede': ['Pintura', 'Azulejo', 'Concreto'],
    'Teto': ['Pintura', 'Gesso', 'Concreto'],
    'Porta': ['Madeira', 'Metal', 'Vidro'],
    'Janela': ['Vidro', 'Alumínio', 'Madeira'],
    'Bancada': ['Granito', 'Mármore', 'Concreto'],
    'Louças e metais': ['Cerâmica', 'Metal'],
    'Portão': ['Metal', 'Madeira'],
    'Número': ['Metal', 'Pintura'],
    'Calçada': ['Concreto', 'Cerâmico'],
    'Rua / via': ['Asfalto', 'Concreto'],
    'Acesso': ['Metal', 'Concreto'],
    'Interfone': ['Metal', 'Plástico'],
    'Cobertura': ['Telha', 'Concreto'],
    'Guarda-corpo': ['Metal', 'Vidro'],
    'Tanque': ['Cerâmica', 'Concreto'],
  };

  static const List<String> _estados = ['Novo', 'Bom', 'Regular', 'Ruim', 'Péssimo'];

  List<String> get _materiaisAtuais {
    if (_elemento == null) return const [];
    return _materiaisPorElemento[_elemento] ?? const [];
  }

  List<String> _materiaisForElement(String? elemento) {
    if (elemento == null) return const [];
    return _materiaisPorElemento[elemento] ?? const [];
  }

  String? get _predictionSummary {
    final prediction = _predictedSelection;
    if (prediction == null || !prediction.hasAnyValue) return null;
    final parts = <String>[];
    if (prediction.elemento != null) parts.add(prediction.elemento!);
    if (prediction.material != null) parts.add(prediction.material!);
    if (prediction.estado != null) parts.add(prediction.estado!);
    if (parts.isEmpty) return null;
    return 'Sugestão com base em ${prediction.captures} captura(s): ${parts.join(' • ')}';
  }

  bool get _showMacroLocalSelector => widget.preselectedMacroLocal == null;

  @override
  void initState() {
    super.initState();
    _macroLocal = widget.preselectedMacroLocal;
    _ambiente = widget.initialAmbiente;
    _elemento = widget.initialElemento;
    _setup();
  }

  Future<void> _setup() async {
    try {
      await _menuService.ensureLoaded();
      await _reloadMenus(initialLoad: true);
      await _ensureLocationReady();

      final cameras = await availableCameras();
      final back = cameras.where((c) => c.lensDirection == CameraLensDirection.back);
      final selected = back.isNotEmpty ? back.first : cameras.first;

      final controller = CameraController(
        selected,
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

  Future<void> _reloadMenus({bool initialLoad = false}) async {
    if (mounted) {
      setState(() => _loadingMenus = true);
    }

    final macroLocals = await _menuService.getMacroLocals(
      propertyType: widget.tipoImovel,
    );

    String? macroLocal = _macroLocal;
    String? contextSuggestionSummary;

    if (macroLocal == null && !_showMacroLocalSelector && widget.preselectedMacroLocal != null) {
      macroLocal = widget.preselectedMacroLocal;
    }

    if ((macroLocal == null || macroLocal.trim().isEmpty) && _showMacroLocalSelector) {
      final suggestedContext = await _menuService.getSuggestedContext(
        propertyType: widget.tipoImovel,
        availableMacroLocals: macroLocals,
      );

      if (suggestedContext?.macroLocal != null) {
        macroLocal = suggestedContext!.macroLocal!;
        contextSuggestionSummary = 'Área da foto sugerida com base no histórico: $macroLocal';
      }
    }

    if (macroLocal != null && !macroLocals.contains(macroLocal)) {
      macroLocal = macroLocals.isNotEmpty ? macroLocals.first : null;
    }

    final ambientes = macroLocal == null
        ? const <String>[]
        : await _menuService.getAmbientes(
            propertyType: widget.tipoImovel,
            macroLocal: macroLocal,
          );

    final recentAmbientes = macroLocal == null
        ? const <String>[]
        : await _menuService.getRecentAmbienteSuggestions(
            propertyType: widget.tipoImovel,
            macroLocal: macroLocal,
            availableAmbientes: ambientes,
          );

    String? ambiente = _ambiente;
    if (ambiente != null && !ambientes.contains(ambiente)) {
      ambiente = null;
    }

    if ((ambiente == null || ambiente.trim().isEmpty) && macroLocal != null) {
      final suggestedContext = await _menuService.getSuggestedContext(
        propertyType: widget.tipoImovel,
        macroLocal: macroLocal,
        availableAmbientes: ambientes,
      );

      if (widget.initialAmbiente == null && suggestedContext?.ambiente != null) {
        ambiente = suggestedContext!.ambiente!;
        contextSuggestionSummary =
            'Contexto sugerido com base no histórico: ${macroLocal}${ambiente == null ? '' : ' • $ambiente'}';
      }
    }

    if (initialLoad && ambiente == null && ambientes.isNotEmpty && !_showMacroLocalSelector) {
      ambiente = ambientes.first;
    }

    final elementos = (macroLocal == null || ambiente == null)
        ? const <String>[]
        : await _menuService.getElementos(
            propertyType: widget.tipoImovel,
            macroLocal: macroLocal,
            ambiente: ambiente,
          );

    final recentElementos = (macroLocal == null || ambiente == null)
        ? const <String>[]
        : await _menuService.getRecentElementSuggestions(
            propertyType: widget.tipoImovel,
            macroLocal: macroLocal,
            ambiente: ambiente,
            availableElementos: elementos,
          );

    String? elemento = _elemento;
    if (elemento != null && !elementos.contains(elemento)) {
      elemento = elementos.isNotEmpty ? elementos.first : null;
    }

    PredictedSelection? prediction;
    if (macroLocal != null && ambiente != null) {
      prediction = await _menuService.getPrediction(
        propertyType: widget.tipoImovel,
        macroLocal: macroLocal,
        ambiente: ambiente,
        availableElementos: elementos,
        availableMateriais: _materiaisForElement(elemento),
        availableEstados: _estados,
      );
    }

    if (elemento == null && widget.initialElemento == null && prediction?.elemento != null) {
      final candidate = prediction!.elemento!;
      if (elementos.contains(candidate)) {
        elemento = candidate;
      }
    }

    String? material = _material;
    final materiaisDisponiveis = _materiaisForElement(elemento);
    if (material != null && !materiaisDisponiveis.contains(material)) {
      material = null;
    }
    if (material == null && prediction?.material != null) {
      final candidate = prediction!.material!;
      if (materiaisDisponiveis.contains(candidate)) {
        material = candidate;
      }
    }

    String? estado = _estado;
    if (estado != null && !_estados.contains(estado)) {
      estado = null;
    }
    if (estado == null && prediction?.estado != null) {
      final candidate = prediction!.estado!;
      if (_estados.contains(candidate)) {
        estado = candidate;
      }
    }

    if (!mounted) return;

    setState(() {
      _macroLocais = macroLocals;
      _ambientesAtuais = ambientes;
      _elementosAtuais = elementos;
      _recentAmbientes = recentAmbientes;
      _recentElementos = recentElementos;
      _predictedSelection = prediction;
      _contextSuggestionSummary = contextSuggestionSummary;
      _macroLocal = macroLocal;
      _ambiente = ambiente;
      _elemento = elemento;
      _material = material;
      _estado = estado;
      _loadingMenus = false;
    });
  }

  Future<void> _ensureLocationReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
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

  Future<void> _selectMacroLocal(String value) async {
    await _menuService.registerUsage(
      scope: 'camera.${widget.tipoImovel.toLowerCase()}.macro',
      value: value,
    );

    setState(() {
      _macroLocal = value;
      _ambiente = null;
      _elemento = null;
      _material = null;
      _estado = null;
    });

    await _reloadMenus();
  }

  Future<void> _selectAmbiente(String value) async {
    await _menuService.registerUsage(
      scope: 'camera.${widget.tipoImovel.toLowerCase()}.$_macroLocal.ambiente',
      value: value,
    );

    setState(() {
      _ambiente = value;
      _elemento = null;
      _material = null;
      _estado = null;
    });

    await _reloadMenus();
  }

  Future<void> _selectElemento(String value) async {
    await _menuService.registerUsage(
      scope: 'camera.${widget.tipoImovel.toLowerCase()}.$_macroLocal.$_ambiente.elemento',
      value: value,
    );

    setState(() {
      _elemento = value;
      _material = null;
      _estado = null;
    });
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_ambiente == null || _ambiente!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o local da foto antes de capturar.')),
      );
      return;
    }

    try {
      setState(() => _capturing = true);

      await _ensureLocationReady();
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final file = await _controller!.takePicture();

      if (!mounted) return;

      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      final result = OverlayCameraCaptureResult(
        filePath: file.path,
        macroLocal: _macroLocal,
        ambiente: _ambiente!,
        elemento: _elemento,
        material: _material,
        estado: _estado,
        capturedAt: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      await _menuService.registerCaptureProfile(
        propertyType: widget.tipoImovel,
        macroLocal: _macroLocal,
        ambiente: _ambiente!,
        elemento: _elemento,
        material: _material,
        estado: _estado,
      );

      if (widget.singleCaptureMode) {
        navigator.pop(result);
        return;
      }

      if (!mounted) return;

      setState(() => _captures.add(result));

      messenger.showSnackBar(
        const SnackBar(content: Text('Foto adicionada ao lote.')),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _finalizeBatch() {
    if (_captures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture pelo menos uma foto antes de finalizar.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionReviewScreen(
          captures: _captures,
          tipoImovel: '${widget.tipoImovel} • ${widget.subtipoImovel}',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing || _loadingMenus) {
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

    final resumo = [
      if (_macroLocal != null) _macroLocal!,
      if (_ambiente != null) _ambiente!,
      if (_elemento != null) _elemento!,
      if (_material != null) _material!,
      if (_estado != null) _estado!,
    ].join(' > ');

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
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Column(
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
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            widget.title,
                            style: const TextStyle(
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
                    if (_showMacroLocalSelector) ...[
                      const SizedBox(height: 8),
                      _carouselCard(
                        title: 'Área da foto',
                        values: _macroLocais,
                        selected: _macroLocal,
                        onSelect: _selectMacroLocal,
                      ),
                    ],
                    if (_macroLocal != null) ...[
                      const SizedBox(height: 8),
                      _carouselCard(
                        title: 'Local da foto',
                        values: _ambientesAtuais,
                        selected: _ambiente,
                        onSelect: _selectAmbiente,
                      ),
                    ],
                    if (_contextSuggestionSummary != null) ...[
                      const SizedBox(height: 8),
                      _hintCard(_contextSuggestionSummary!),
                    ],
                    if (_recentAmbientes.isNotEmpty && _macroLocal != null) ...[
                      const SizedBox(height: 8),
                      _quickSuggestionCard(
                        title: 'Locais mais usados nesta área',
                        values: _recentAmbientes,
                        selected: _ambiente,
                        onSelect: _selectAmbiente,
                      ),
                    ],
                    if (_ambiente != null && _elementosAtuais.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _carouselCard(
                        title: 'Elemento fotografado',
                        values: _elementosAtuais,
                        selected: _elemento,
                        onSelect: _selectElemento,
                      ),
                    ],
                    if (_predictionSummary != null) ...[
                      const SizedBox(height: 8),
                      _hintCard(_predictionSummary!),
                    ],
                    if (_recentElementos.isNotEmpty && _ambiente != null) ...[
                      const SizedBox(height: 8),
                      _quickSuggestionCard(
                        title: 'Mais usados neste contexto',
                        values: _recentElementos,
                        selected: _elemento,
                        onSelect: _selectElemento,
                      ),
                    ],
                    if (_elemento != null && _materiaisAtuais.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _carouselCard(
                        title: 'Material',
                        values: _materiaisAtuais,
                        selected: _material,
                        onSelect: (value) async {
                          setState(() {
                            _material = value;
                            _estado = null;
                          });
                        },
                      ),
                    ],
                    if (_elemento != null &&
                        (_materiaisAtuais.isEmpty || _material != null)) ...[
                      const SizedBox(height: 8),
                      _carouselCard(
                        title: 'Estado',
                        values: _estados,
                        selected: _estado,
                        onSelect: (value) async {
                          setState(() => _estado = value);
                        },
                      ),
                    ],
                  ],
                ),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Capturas no lote: ${_captures.length}${resumo.isEmpty ? '' : ' • $resumo'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _circleAction(
                          icon: Icons.photo_library_outlined,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Galeria permanece no fluxo atual.')),
                            );
                          },
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
                                color: Colors.black.withValues(alpha: 0.18),
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
                          onTap: widget.singleCaptureMode
                              ? () => Navigator.of(context).pop()
                              : _finalizeBatch,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.black.withValues(alpha: 0.20)
              : Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _hintCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _quickSuggestionCard({
    required String title,
    required List<String> values,
    required String? selected,
    required Future<void> Function(String value) onSelect,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            ...values.map(
              (value) {
                final active = value == selected;
                return GestureDetector(
                  onTap: () => onSelect(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: active ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _carouselCard({
    required String title,
    required List<String> values,
    required String? selected,
    required Future<void> Function(String value) onSelect,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                scrollDirection: Axis.horizontal,
                itemCount: values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final value = values[index];
                  final active = value == selected;
                  return GestureDetector(
                    onTap: () => onSelect(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          value,
                          style: TextStyle(
                            color: active ? Colors.black87 : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
