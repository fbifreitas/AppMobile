import 'package:appmobile/models/proposal_offer.dart';
import 'package:appmobile/widgets/home/proposals_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder findRichTextContaining(String text) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is RichText &&
        widget.text.toPlainText().contains(text),
  );
}

void main() {
  testWidgets('renders enriched proposal card fields', (tester) async {
    final proposta = ProposalOffer(
      id: '1',
      valor: 'R\$ 180,00',
      expiraEm: const Duration(minutes: 50),
      distanciaKm: 3.2,
      endereco: 'Rua Teste, 100 - São Paulo/SP',
      proprietario: 'João Silva',
      dataHoraAgendamento: DateTime(2026, 3, 28, 15, 45),
      tipoImovel: 'Urbano',
      subtipoImovel: 'Casa',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProposalsSection(
            propostas: [proposta],
          ),
        ),
      ),
    );

    expect(find.text('NOVAS PROPOSTAS'), findsOneWidget);
    expect(find.text('R\$ 180,00'), findsOneWidget);
    expect(find.text('Expira em 00:50'), findsOneWidget);
    expect(find.text('3.2 km de distância'), findsOneWidget);
    expect(findRichTextContaining('Rua Teste, 100 - São Paulo/SP'), findsOneWidget);
    expect(findRichTextContaining('João Silva'), findsOneWidget);
    expect(findRichTextContaining('28/03/2026 às 15:45'), findsOneWidget);
    expect(find.text('DESLIZE PARA ACEITAR'), findsOneWidget);
  });

  testWidgets('calls callback when swiping to accept', (tester) async {
    final proposta = ProposalOffer(
      id: '1',
      valor: 'R\$ 180,00',
      expiraEm: const Duration(minutes: 50),
      distanciaKm: 3.2,
      endereco: 'Rua Teste, 100 - São Paulo/SP',
      proprietario: 'João Silva',
      dataHoraAgendamento: DateTime(2026, 3, 28, 15, 45),
    );

    ProposalOffer? accepted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProposalsSection(
            propostas: [proposta],
            onAcceptProposal: (item) => accepted = item,
          ),
        ),
      ),
    );

    final dismissible = find.byType(Dismissible).first;
    await tester.drag(dismissible, const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(accepted?.id, '1');
  });
}
