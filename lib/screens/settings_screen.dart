import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
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
  String _appVersion = 'vloading...';

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
        _appVersion = AppStrings.of(
          context,
        ).tr('Versao indisponivel', 'Version unavailable');
      });
    }
  }

  Future<void> _handleDeveloperModeHiddenTap() async {
    final strings = AppStrings.of(context);
    final appState = context.read<AppState>();

    if (kReleaseMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.tr(
              'Recursos de desenvolvedor bloqueados em release.',
              'Developer features are blocked in release.',
            ),
          ),
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
                strings.tr(
                  'Mais $remaining toque${remaining == 1 ? '' : 's'} para habilitar a ferramenta do desenvolvedor.',
                  '$remaining more tap${remaining == 1 ? '' : 's'} to enable the developer tool.',
                ),
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
        SnackBar(
          content: Text(
            strings.tr(
              'Ferramenta do desenvolvedor habilitada.',
              'Developer tool enabled.',
            ),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.tr(
            'A ferramenta do desenvolvedor ja esta habilitada.',
            'The developer tool is already enabled.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final appState = context.watch<AppState>();
    final authState = Provider.of<AuthState?>(context);
    final displayName = authState?.userNome?.trim().isNotEmpty == true
        ? authState!.userNome!.trim()
        : appState.usuarioNomeCompleto.trim();

    return Scaffold(
      appBar: AppBar(title: Text(strings.tr('Configuracoes', 'Settings'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            strings.tr('Meus dados', 'My data'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
              label: strings.tr('Nome completo', 'Full name'),
              value: displayName.isEmpty
                  ? strings.tr('Nao informado', 'Not provided')
                  : displayName,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.email_outlined,
              label: strings.tr('E-mail', 'Email'),
              value: authState!.userEmail!,
            ),
          ],
          if ((authState?.tenantId?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.apartment_outlined,
              label: strings.tr('Empresa', 'Company'),
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
            label: Text(
              strings.tr(
                'Atualizar dados cadastrais',
                'Update profile information',
              ),
            ),
          ),
          if (appState.developerToolsUnlocked &&
              appState.developerModeEnabled) ...[
            const Divider(height: 28),
            Text(
              strings.tr('Ferramentas do desenvolvedor', 'Developer tools'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                strings.tr(
                  'Habilitar ferramenta do desenvolvedor',
                  'Enable developer tool',
                ),
              ),
              subtitle: Text(
                strings.tr(
                  'Controla a exibicao do icone do hub tecnico na Home.',
                  'Controls whether the technical hub icon is shown on Home.',
                ),
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
              title: Text(
                strings.tr(
                  'Permitir iniciar longe do local',
                  'Allow starting far from the site',
                ),
              ),
              subtitle: Text(
                strings.tr(
                  'Quando desligado, o botao de vistoria depende da distancia real ate o imovel.',
                  'When disabled, the inspection button depends on the real distance to the property.',
                ),
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
            label: Text(strings.tr('Sair da conta', 'Sign out')),
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
