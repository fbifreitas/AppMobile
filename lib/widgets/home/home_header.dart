import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../branding/brand_provider.dart';
import '../../branding/brand_tokens.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.firstName,
    required this.unreadMessages,
    required this.photoPath,
    required this.onNotificationsTap,
    required this.onSettingsTap,
    required this.onHubTap,
    required this.showHubButton,
    this.subtitle,
  });

  final String firstName;
  final int unreadMessages;
  final String? photoPath;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onHubTap;
  final bool showHubButton;

  /// Subtitle shown below the greeting.
  /// When provided, uses this value directly.
  /// When null, reads 'home_header_subtitle' from [BrandProvider].
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final config = BrandProvider.configOf(context);
    final tokens = config.tokens;
    final greetingPrefix = config.copyText('home_greeting_prefix', defaultValue: 'Olá,');
    final resolvedSubtitle =
        subtitle?.isNotEmpty == true
            ? subtitle!
            : config.copyText(
                'home_header_subtitle',
                defaultValue: 'Seu painel operacional de hoje',
              );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderAvatar(photoPath: photoPath, tokens: tokens),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greetingPrefix $firstName!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BrandTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                resolvedSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: BrandTokens.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderIconButton(
              icon: Icons.notifications_none,
              onTap: onNotificationsTap,
              badge: unreadMessages > 0 ? '$unreadMessages' : null,
              semanticLabel: 'Abrir notificacoes',
              automationKey: 'home_header_notifications_button',
              tokens: tokens,
            ),
            const SizedBox(width: 8),
            _HeaderIconButton(
              icon: Icons.settings_outlined,
              onTap: onSettingsTap,
              semanticLabel: 'Abrir configuracoes',
              automationKey: 'home_header_settings_button',
              tokens: tokens,
            ),
            if (showHubButton) ...[
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.dashboard_customize_outlined,
                onTap: onHubTap,
                semanticLabel: 'Abrir hub operacional',
                automationKey: 'home_header_hub_button',
                tokens: tokens,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({this.photoPath, required this.tokens});

  static const _avatarUrl = 'https://i.pravatar.cc/150?img=3';
  final String? photoPath;
  final BrandTokens tokens;

  @override
  Widget build(BuildContext context) {
    final hasLocal = photoPath != null && photoPath!.trim().isNotEmpty;
    return ClipOval(
      child: SizedBox(
        width: 42,
        height: 42,
        child:
            hasLocal && !kIsWeb
                ? Image.file(
                  File(photoPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackAvatar(),
                )
                : Image.network(
                  _avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackAvatar(),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: tokens.primaryLight,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: tokens.primaryLight,
      alignment: Alignment.center,
      child: Icon(Icons.person, color: tokens.primary, size: 22),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    required this.automationKey,
    required this.tokens,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final String automationKey;
  final BrandTokens tokens;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        key: ValueKey(automationKey),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: BrandTokens.surface,
                shape: BoxShape.circle,
                border: Border.all(color: BrandTokens.border),
              ),
              child: Icon(icon, color: tokens.primary, size: 18),
            ),
            if (badge != null)
              Positioned(
                top: -4,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: BrandTokens.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
