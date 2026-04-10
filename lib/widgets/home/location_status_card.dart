import 'package:flutter/material.dart';

import '../../branding/brand_provider.dart';
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
              const Expanded(
                child: Text(
                  'Localização operacional',
                  style: TextStyle(
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
                  label: Text(loading ? 'Atualizando' : 'Atualizar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasLocation) ...[
            Text(
              'Latitude: ${latitude!.toStringAsFixed(6)}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Longitude: ${longitude!.toStringAsFixed(6)}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ] else
            const Text(
              'Nenhuma localização capturada ainda.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          if (lastSyncAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Última atualização: ${_formatDateTime(lastSyncAt!)}',
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
