import 'package:flutter/material.dart';

import '../../branding/brand_provider.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';

class LocationStatusCard extends StatelessWidget {
  const LocationStatusCard({
    super.key,
    required this.loading,
    required this.errorMessage,
    required this.lastSyncAt,
    required this.latitude,
    required this.longitude,
    required this.onRefresh,
  });

  final bool loading;
  final String? errorMessage;
  final DateTime? lastSyncAt;
  final double? latitude;
  final double? longitude;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final tokens = BrandProvider.configOf(context).tokens;
    final strings = AppStrings.of(context);
    final hasLocation = latitude != null && longitude != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.my_location_outlined,
                color: tokens.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.tr('Localização operacional', 'Operational location'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                width: 118,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onRefresh,
                  icon: loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    loading
                        ? strings.tr('Atualizando', 'Updating')
                        : strings.tr('Atualizar', 'Refresh'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasLocation) ...[
            Text(
              strings.tr(
                'Latitude: ${latitude!.toStringAsFixed(6)}',
                'Latitude: ${latitude!.toStringAsFixed(6)}',
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.tr(
                'Longitude: ${longitude!.toStringAsFixed(6)}',
                'Longitude: ${longitude!.toStringAsFixed(6)}',
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ] else
            Text(
              strings.tr(
                'Nenhuma localização capturada ainda.',
                'No location captured yet.',
              ),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          if (lastSyncAt != null) ...[
            const SizedBox(height: 8),
            Text(
              strings.tr(
                'Última atualização: ${_formatDateTime(lastSyncAt!)}',
                'Last update: ${_formatDateTime(lastSyncAt!)}',
              ),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
