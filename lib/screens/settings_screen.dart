import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../services/inspection_export_service.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const int _developerModeTapThreshold = 7;

  late TextEditingController _nomeController;
  late TextEditingController _exportFolderController;

  final InspectionExportService _exportService = InspectionExportService();

  InspectionExportDirectoryMode _exportMode =
      InspectionExportDirectoryMode.internal;
  bool _loadingExportSettings = true;
  bool _usingExternalExportBase = false;

  int _versionTapCount = 0;
  String _appVersion = 'vcarregando...';

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _nomeController = TextEditingController(text: appState.usuarioNomeCompleto);
    _exportFolderController = TextEditingController(text: 'inspection_exports');
    _loadAppVersion();
    _loadExportSettings();
  }

  Future<void> _loadExportSettings() async {
    final settings = await _exportService.resolveEffectiveSettings();
    if (!mounted) return;

    setState(() {
      _exportMode = settings.mode;
      _usingExternalExportBase = settings.usingExternalBase;
      _exportFolderController.text = settings.folderName;
      _loadingExportSettings = false;
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        final versionLabel = packageInfo.buildNumber.isNotEmpty
            ? 'v${packageInfo.version}+${packageInfo.buildNumber}'
            : 'v${packageInfo.version}';
        _appVersion = versionLabel;
      });

    } catch (_) {
      if (!mounted) return;
      setState(() {
        _appVersion = 'Versão indisponível';
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _exportFolderController.dispose();
    super.dispose();
  }

  Future<void> _handleDeveloperModeHiddenTap() async {
    final appState = context.read<AppState>();

    if (!appState.developerToolsUnlocked) {
      _versionTapCount += 1;

      final remaining = _developerModeTapThreshold - _versionTapCount;
      if (remaining > 0) {
        if (remaining <= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Mais $remaining toque${remaining == 1 ? '' : 's'} para habilitar a ferramenta do desenvolvedor.',
              ),
            ),
          );
        }
        return;
      }

      _versionTapCount = 0;
      await appState.unlockDeveloperTools();
      await appState.setDeveloperModeEnabled(true);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ferramenta do desenvolvedor habilitada.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A ferramenta do desenvolvedor já está habilitada.',
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    final appState = context.read<AppState>();
    appState.setUsuarioNomeCompleto(_nomeController.text.trim());
    await _exportService.configureExportDirectory(
      mode: _exportMode,
      folderName: _exportFolderController.text,
    );

    final effectiveSettings = await _exportService.resolveEffectiveSettings();

    if (!mounted) return;
    setState(() {
      _usingExternalExportBase = effectiveSettings.usingExternalBase;
    });

    final exportTargetMessage =
        effectiveSettings.mode == InspectionExportDirectoryMode.external &&
                !effectiveSettings.usingExternalBase
            ? 'Configuração salva. Diretório externo indisponível neste dispositivo; usando interno automaticamente.'
            : 'Configurações atualizadas.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(exportTargetMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Meus dados',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nomeController,
            decoration: const InputDecoration(
              labelText: 'Nome completo do usuário',
              border: OutlineInputBorder(),
            ),
          ),
          const Divider(height: 28),
          const Text(
            'Exportação da vistoria',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingExportSettings)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          else ...[
            DropdownButtonFormField<InspectionExportDirectoryMode>(
              initialValue: _exportMode,
              decoration: const InputDecoration(
                labelText: 'Destino da exportação JSON',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: InspectionExportDirectoryMode.internal,
                  child: Text('Interno (recomendado)'),
                ),
                DropdownMenuItem(
                  value: InspectionExportDirectoryMode.external,
                  child: Text('Externo (quando disponível)'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _exportMode = value;
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _exportFolderController,
              decoration: const InputDecoration(
                labelText: 'Subdiretório de exportação',
                border: OutlineInputBorder(),
                helperText:
                    'Exemplo: inspection_exports ou operacao/json/vistorias',
              ),
            ),
            if (_exportMode == InspectionExportDirectoryMode.external &&
                !_usingExternalExportBase)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Neste dispositivo, o diretório externo pode não estar disponível. O app fará fallback automático para o diretório interno.',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
          if (appState.developerToolsUnlocked &&
              appState.developerModeEnabled) ...[
            const Divider(height: 28),
            const Text(
              'Ferramentas do desenvolvedor',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Habilitar ferramenta do desenvolvedor'),
              subtitle: const Text(
                'Controla a exibição do ícone do hub técnico na Home.',
              ),
              value: appState.developerModeEnabled,
              onChanged: (value) async {
                if (!value) {
                  await appState.lockDeveloperTools();
                  return;
                }
                await appState.setDeveloperModeEnabled(true);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Permitir iniciar longe do local'),
              subtitle: const Text(
                'Quando desligado, o botão de vistoria depende da distância real até o imóvel.',
              ),
              value: appState.permitirIniciarLonge,
              onChanged: (value) async {
                await appState.setPermitirIniciarLonge(value);
              },
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _saveSettings,
            child: const Text('Salvar configurações'),
          ),
          const SizedBox(height: 24),
          Center(
            child: InkWell(
              onTap: _handleDeveloperModeHiddenTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  _appVersion,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
