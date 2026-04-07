import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/job.dart';
import '../../models/job_status.dart';
import '../../models/proposal_offer.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';

class ProposalsSection extends StatefulWidget {
  const ProposalsSection({
    super.key,
    this.propostas,
    this.onAcceptProposal,
  });

  final List<ProposalOffer>? propostas;
  final ValueChanged<ProposalOffer>? onAcceptProposal;

  static final List<ProposalOffer> _mockPropostas = [
    ProposalOffer(
      id: 'prop-001',
      valor: 'R\$ 150,00',
      expiraEm: const Duration(minutes: 45),
      distanciaKm: 2.5,
      endereco: 'Rua Serra de Bragança, 123 - Tatuapé, São Paulo/SP',
      proprietario: 'Fabio Freitas',
      dataHoraAgendamento: DateTime(2026, 3, 28, 14, 30),
      tipoImovel: 'Urbano',
      subtipoImovel: 'Apartamento',
    ),
    ProposalOffer(
      id: 'prop-002',
      valor: 'R\$ 220,00',
      expiraEm: const Duration(hours: 1, minutes: 10),
      distanciaKm: 4.1,
      endereco: 'Av. Paes de Barros, 980 - Mooca, São Paulo/SP',
      proprietario: 'Maria Souza',
      dataHoraAgendamento: DateTime(2026, 3, 28, 16, 0),
      tipoImovel: 'Urbano',
      subtipoImovel: 'Casa',
    ),
  ];

  @override
  State<ProposalsSection> createState() => _ProposalsSectionState();
}

class _ProposalsSectionState extends State<ProposalsSection> {
  late List<ProposalOffer> _itens;

  @override
  void initState() {
    super.initState();
    _itens = List.of(widget.propostas ?? ProposalsSection._mockPropostas);
  }

  void _acceptProposal(ProposalOffer proposta) {
    final appState = Provider.of<AppState>(context, listen: false);

    final newJob = Job(
      id: proposta.id,
      titulo: 'Vistoria ${proposta.subtipoImovel ?? proposta.tipoImovel ?? 'Imóvel'}',
      endereco: proposta.endereco,
      status: JobStatus.novo,
      nomeCliente: proposta.proprietario,
      tipoImovel: proposta.tipoImovel,
      subtipoImovel: proposta.subtipoImovel,
    );

    setState(() {
      _itens.removeWhere((p) => p.id == proposta.id);
    });

    appState.adicionarJob(newJob);

    widget.onAcceptProposal?.call(proposta);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Proposta ${proposta.id} aceita! Job adicionado aos seus jobs de hoje.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOVAS PROPOSTAS',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        if (_itens.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Nenhuma proposta disponível no momento.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          )
        else
          ..._itens.map(
            (item) => _ProposalCard(
              key: ValueKey(item.id),
              proposta: item,
              onAccept: () => _acceptProposal(item),
            ),
          ),
      ],
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    super.key,
    required this.proposta,
    required this.onAccept,
  });

  final ProposalOffer proposta;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    proposta.valor,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Expira em ${_formatDuration(proposta.expiraEm)}',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _InfoTag(text: 'ID: ${proposta.id}'),
                _InfoTag(text: '${proposta.distanciaKm.toStringAsFixed(1)} km de distância'),
                if (proposta.tipoImovel != null)
                  _InfoTag(
                    text: proposta.subtipoImovel == null
                        ? proposta.tipoImovel!
                        : '${proposta.tipoImovel} • ${proposta.subtipoImovel}',
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Endereço',
                  value: proposta.endereco,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Proprietário',
                  value: proposta.proprietario,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Agendamento',
                  value: _formatDateTime(proposta.dataHoraAgendamento),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SwipeToAccept(
            onAccept: onAccept,
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String _formatDateTime(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy às $hh:$min';
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11.5,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _SwipeToAccept extends StatelessWidget {
  const _SwipeToAccept({
    required this.onAccept,
  });

  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async => true,
      onDismissed: (_) => onAccept(),
      background: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Row(
          children: [
            Icon(Icons.swipe_right_alt, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'ACEITAR PROPOSTA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.swipe_right_alt,
              color: AppColors.primary,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'DESLIZE PARA ACEITAR',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
