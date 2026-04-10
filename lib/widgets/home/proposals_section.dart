import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../branding/brand_provider.dart';
import '../../branding/brand_tokens.dart';
import '../../models/job.dart';
import '../../models/job_status.dart';
import '../../models/proposal_offer.dart';
import '../../state/app_state.dart';

class ProposalsSection extends StatefulWidget {
  const ProposalsSection({
    super.key,
    this.propostas,
    this.onAcceptProposal,
    this.sectionTitle,
    this.swipeRequired = true,
    this.financialSummaryEnabled = true,
  });

  final List<ProposalOffer>? propostas;
  final ValueChanged<ProposalOffer>? onAcceptProposal;

  /// Section heading. Falls back to config key 'proposals_section_title'.
  /// Callers pass: config.copyText('proposals_section_title', defaultValue: 'NOVAS PROPOSTAS')
  final String? sectionTitle;

  /// When false (Compass / corporate mode), swipe interaction is replaced
  /// by a standard ElevatedButton to accept the proposal.
  /// This is a structural flag only — does NOT determine copy.
  final bool swipeRequired;

  /// When false, financial values (valor) are hidden from proposal cards.
  final bool financialSummaryEnabled;

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
    final config = BrandProvider.configOf(context);

    final newJob = Job(
      id: proposta.id,
      titulo:
          'Vistoria ${proposta.subtipoImovel ?? proposta.tipoImovel ?? 'Imóvel'}',
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

    final snackbarText = config.copyText(
      'proposal_snackbar_accept_success',
      defaultValue: 'Proposta aceita! Job adicionado ao seu dia.',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(snackbarText)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = BrandProvider.configOf(context);
    final tokens = config.tokens;

    final resolvedTitle =
        widget.sectionTitle?.isNotEmpty == true
            ? widget.sectionTitle!
            : config.copyText(
                'proposals_section_title',
                defaultValue: 'NOVAS PROPOSTAS',
              );

    final swipeLabel = config.copyText(
      'proposal_swipe_label',
      defaultValue: 'DESLIZE PARA ACEITAR',
    );
    final acceptLabel = config.copyText(
      'proposal_accept_label',
      defaultValue: 'ACEITAR PROPOSTA',
    );
    final emptyLabel = config.copyText(
      'proposal_empty_title',
      defaultValue: 'Nenhuma proposta disponível no momento.',
    );
    final expirationPrefix = config.copyText(
      'proposal_expiration_prefix',
      defaultValue: 'Expira em',
    );
    final addressLabel = config.copyText(
      'proposal_address_label',
      defaultValue: 'Endereço',
    );
    final ownerLabel = config.copyText(
      'proposal_owner_label',
      defaultValue: 'Proprietário',
    );
    final scheduleLabel = config.copyText(
      'proposal_schedule_label',
      defaultValue: 'Agendamento',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          resolvedTitle,
          style: const TextStyle(
            color: BrandTokens.textSecondary,
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
              color: BrandTokens.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BrandTokens.border),
            ),
            child: Text(
              emptyLabel,
              style: const TextStyle(
                color: BrandTokens.textSecondary,
                fontSize: 12,
              ),
            ),
          )
        else
          ..._itens.map(
            (item) => _ProposalCard(
              key: ValueKey(item.id),
              proposta: item,
              tokens: tokens,
              swipeRequired: widget.swipeRequired,
              financialSummaryEnabled: widget.financialSummaryEnabled,
              swipeLabel: swipeLabel,
              acceptLabel: acceptLabel,
              expirationPrefix: expirationPrefix,
              addressLabel: addressLabel,
              ownerLabel: ownerLabel,
              scheduleLabel: scheduleLabel,
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
    required this.tokens,
    required this.onAccept,
    required this.swipeRequired,
    required this.financialSummaryEnabled,
    required this.swipeLabel,
    required this.acceptLabel,
    required this.expirationPrefix,
    required this.addressLabel,
    required this.ownerLabel,
    required this.scheduleLabel,
  });

  final ProposalOffer proposta;
  final BrandTokens tokens;
  final VoidCallback onAccept;
  final bool swipeRequired;
  final bool financialSummaryEnabled;

  /// Label shown on the swipe track foreground and button background.
  final String swipeLabel;

  /// Label shown when swiping reveals the accept background, and on the button.
  final String acceptLabel;

  /// Labels for info rows — resolved from brand config.
  final String expirationPrefix;
  final String addressLabel;
  final String ownerLabel;
  final String scheduleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: BrandTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                if (financialSummaryEnabled)
                  Expanded(
                    child: Text(
                      proposta.valor,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: BrandTokens.textPrimary,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: BrandTokens.warningLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$expirationPrefix ${_formatDuration(proposta.expiraEm)}',
                    style: const TextStyle(
                      color: BrandTokens.warning,
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
                _InfoTag(text: 'ID: ${proposta.id}', tokens: tokens),
                _InfoTag(
                  text:
                      '${proposta.distanciaKm.toStringAsFixed(1)} km de distância',
                  tokens: tokens,
                ),
                if (proposta.tipoImovel != null)
                  _InfoTag(
                    text:
                        proposta.subtipoImovel == null
                            ? proposta.tipoImovel!
                            : '${proposta.tipoImovel} • ${proposta.subtipoImovel}',
                    tokens: tokens,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: addressLabel, value: proposta.endereco),
                const SizedBox(height: 6),
                _InfoRow(label: ownerLabel, value: proposta.proprietario),
                const SizedBox(height: 6),
                _InfoRow(
                  label: scheduleLabel,
                  value: _formatDateTime(proposta.dataHoraAgendamento),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (swipeRequired)
            _SwipeToAccept(
              onAccept: onAccept,
              tokens: tokens,
              swipeLabel: swipeLabel,
              acceptBgLabel: acceptLabel,
            )
          else
            _AcceptButton(
              onAccept: onAccept,
              tokens: tokens,
              label: acceptLabel,
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
  const _InfoTag({required this.text, required this.tokens});

  final String text;
  final BrandTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tokens.primary,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: BrandTokens.textSecondary, fontSize: 11.5),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: BrandTokens.textPrimary,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

/// Swipe-to-accept interaction — used in marketplace (Kaptur) mode.
/// Copy comes from [ResolvedBrandConfig] resolved by the parent.
class _SwipeToAccept extends StatelessWidget {
  const _SwipeToAccept({
    required this.onAccept,
    required this.tokens,
    required this.swipeLabel,
    required this.acceptBgLabel,
  });

  final VoidCallback onAccept;
  final BrandTokens tokens;

  /// Label shown on the swipe foreground track (e.g. 'DESLIZE PARA ACEITAR').
  final String swipeLabel;

  /// Label shown when the swipe background is revealed (e.g. 'ACEITAR PROPOSTA').
  final String acceptBgLabel;

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
          color: tokens.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.swipe_right_alt, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              acceptBgLabel,
              style: const TextStyle(
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
          color: BrandTokens.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BrandTokens.border),
        ),
        child: Row(
          children: [
            Icon(Icons.swipe_right_alt, color: tokens.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                swipeLabel,
                style: TextStyle(
                  color: tokens.primary,
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

/// Button-based accept interaction — used in corporate (Compass) mode
/// when swipe interaction is not appropriate.
/// Copy comes from [ResolvedBrandConfig] resolved by the parent.
class _AcceptButton extends StatelessWidget {
  const _AcceptButton({
    required this.onAccept,
    required this.tokens,
    required this.label,
  });

  final VoidCallback onAccept;
  final BrandTokens tokens;

  /// Label resolved from config (e.g. 'ACEITAR PROPOSTA' or 'ACEITAR DEMANDA').
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onAccept,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
