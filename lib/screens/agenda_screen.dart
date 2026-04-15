import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/agenda_item.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _focusMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  void _changeMonth(int delta) {
    setState(() {
      _focusMonth = DateTime(_focusMonth.year, _focusMonth.month + delta, 1);
      final maxDay = DateUtils.getDaysInMonth(
        _focusMonth.year,
        _focusMonth.month,
      );
      final day = _selectedDay.day > maxDay ? maxDay : _selectedDay.day;
      _selectedDay = DateTime(_focusMonth.year, _focusMonth.month, day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings.of(context);
    final firstDay = DateTime(_focusMonth.year, _focusMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusMonth.year,
      _focusMonth.month,
    );
    final startWeekday = firstDay.weekday;

    final selectedItems = appState.itemsParaDia(_selectedDay)
      ..sort((a, b) => a.data.compareTo(b.data));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                _monthLabel(strings, _focusMonth),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CalendarGrid(
          year: _focusMonth.year,
          month: _focusMonth.month,
          daysInMonth: daysInMonth,
          startWeekday: startWeekday,
          selectedDay: _selectedDay,
          hasItems: (day) => appState.itemsParaDia(day).isNotEmpty,
          onDayTap: (day) => setState(() => _selectedDay = day),
        ),
        const SizedBox(height: 16),
        Text(
          strings.tr(
            'Jobs em ${_selectedDay.day.toString().padLeft(2, '0')}/${_selectedDay.month.toString().padLeft(2, '0')}',
            'Jobs on ${_selectedDay.day.toString().padLeft(2, '0')}/${_selectedDay.month.toString().padLeft(2, '0')}',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (selectedItems.isEmpty)
          Text(
            strings.tr(
              'Nenhum job agendado para este dia.',
              'No job scheduled for this day.',
            ),
            style: const TextStyle(color: AppColors.textSecondary),
          )
        else
          ...selectedItems.map((item) => _AgendaCard(item: item)),
      ],
    );
  }

  String _monthLabel(AppStrings strings, DateTime date) {
    final months = [
      strings.tr('Janeiro', 'January'),
      strings.tr('Fevereiro', 'February'),
      strings.tr('Marco', 'March'),
      strings.tr('Abril', 'April'),
      strings.tr('Maio', 'May'),
      strings.tr('Junho', 'June'),
      strings.tr('Julho', 'July'),
      strings.tr('Agosto', 'August'),
      strings.tr('Setembro', 'September'),
      strings.tr('Outubro', 'October'),
      strings.tr('Novembro', 'November'),
      strings.tr('Dezembro', 'December'),
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.daysInMonth,
    required this.startWeekday,
    required this.selectedDay,
    required this.hasItems,
    required this.onDayTap,
  });

  final int year;
  final int month;
  final int daysInMonth;
  final int startWeekday;
  final DateTime selectedDay;
  final bool Function(DateTime day) hasItems;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    final strings = AppStrings.of(context);
    final weekdayLabels = [
      strings.tr('S', 'S'),
      strings.tr('T', 'M'),
      strings.tr('Q', 'T'),
      strings.tr('Q', 'W'),
      strings.tr('S', 'T'),
      strings.tr('S', 'F'),
      strings.tr('D', 'S'),
    ];

    for (final label in weekdayLabels) {
      cells.add(
        Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    for (var i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final selected =
          selectedDay.year == year &&
          selectedDay.month == month &&
          selectedDay.day == day;
      final withItems = hasItems(date);

      cells.add(
        GestureDetector(
          onTap: () => onDayTap(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    selected
                        ? AppColors.primary
                        : withItems
                        ? AppColors.success
                        : AppColors.border,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (withItems)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: cells,
    );
  }
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({required this.item});

  final AgendaItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.titulo,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.endereco,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${item.data.hour.toString().padLeft(2, '0')}:${item.data.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  item.status.label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
