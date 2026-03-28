import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.firstName,
    required this.onNotificationsTap,
    required this.onSettingsTap,
    required this.onHubTap,
    required this.showHubButton,
  });

  final String firstName;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onHubTap;
  final bool showHubButton;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeaderAvatar(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $firstName!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'Seu painel operacional de hoje',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
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
              badge: '3',
            ),
            const SizedBox(width: 8),
            _HeaderIconButton(
              icon: Icons.settings_outlined,
              onTap: onSettingsTap,
            ),
            if (showHubButton) ...[
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.dashboard_customize_outlined,
                onTap: onHubTap,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar();

  static const _avatarUrl = 'https://i.pravatar.cc/150?img=3';

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 42,
        height: 42,
        child: Image.network(
          _avatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              color: AppColors.primaryLight,
              alignment: Alignment.center,
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 22,
              ),
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: AppColors.primaryLight,
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
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger,
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
    );
  }
}
