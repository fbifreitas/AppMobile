import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/auth_state.dart';
import 'profile_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const int _developerModeTapThreshold = 7;

  int _versionTapCount = 0;
  String _appVersion = 'vcarregando...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        final versionLabel =
            packageInfo.buildNumber.isNotEmpty
                ? 'v${packageInfo.version}+${packageInfo.buildNumber}'
                : 'v${packageInfo.version}';
        _appVersion = versionLabel;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _appVersion = 'Versao indisponivel';
      });
    }
  }

  Future<void> _handleDeveloperModeHiddenTap() async {
    final appState = context.read<AppState>();

    if (kReleaseMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recursos de desenvolvedor bloqueados em release.'),
        ),
      );
      return;
    }

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
          content: Text('Ferramenta do desenvolvedor habilitada.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A ferramenta do desenvolvedor ja esta habilitada.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final authState = Provider.of<AuthState?>(context);
    final displayName = authState?.userNome?.trim().isNotEmpty == true
        ? authState!.userNome!.trim()
        : appState.usuarioNomeCompleto.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Configuracoes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Meus dados',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: _handleDeveloperModeHiddenTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                _appVersion,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if ((authState?.userEmail?.trim().isNotEmpty ?? false)) ...[
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Nome completo',
              value: displayName.isEmpty ? 'Nao informado' : displayName,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'E-mail',
              value: authState!.userEmail!,
            ),
          ],
          if ((authState?.tenantId?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.apartment_outlined,
              label: 'Empresa',
              value: authState!.tenantId!,
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileSettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.manage_accounts_outlined),
            label: const Text('Atualizar dados cadastrais'),
          ),
          if (appState.developerToolsUnlocked &&
              appState.developerModeEnabled) ...[
            const Divider(height: 28),
            const Text(
              'Ferramentas do desenvolvedor',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Habilitar ferramenta do desenvolvedor'),
              subtitle: const Text(
                'Controla a exibicao do icone do hub tecnico na Home.',
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
                'Quando desligado, o botao de vistoria depende da distancia real ate o imovel.',
              ),
              value: appState.permitirIniciarLonge,
              onChanged: (value) async {
                await appState.setPermitirIniciarLonge(value);
              },
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final authState = Provider.of<AuthState?>(context, listen: false);
              final appState = context.read<AppState>();
              final navigator = Navigator.of(context);
              await appState.resetSessionAfterLogout();
              await authState?.logout();
              if (!mounted) return;
              navigator.popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sair da conta'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
