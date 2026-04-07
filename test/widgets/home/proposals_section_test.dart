import 'package:appmobile/models/job.dart';
import 'package:appmobile/models/proposal_offer.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:appmobile/widgets/home/proposals_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => [];
}

Finder findRichTextContaining(String text) {
  return find.byWidgetPredicate(
    (widget) => widget is RichText && widget.text.toPlainText().contains(text),
    description: 'RichText containing "$text"',
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

    await tester.pumpAndSettle();

    expect(find.text('NOVAS PROPOSTAS'), findsOneWidget);
    expect(find.text('R\$ 180,00'), findsOneWidget);
    expect(find.text('Expira em 00:50'), findsOneWidget);
    expect(find.text('3.2 km de distância'), findsOneWidget);
    expect(findRichTextContaining('Endereço: Rua Teste, 100 - São Paulo/SP'),
        findsOneWidget);
    expect(findRichTextContaining('Proprietário: João Silva'), findsOneWidget);
    expect(findRichTextContaining('Agendamento: 28/03/2026 às 15:45'),
        findsOneWidget);
    expect(find.text('DESLIZE PARA ACEITAR'), findsOneWidget);
    expect(find.text('ID: 1'), findsOneWidget);
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
      ChangeNotifierProvider<AppState>(
        create: (_) => AppState(_FakeJobRepository()),
        child: MaterialApp(
          home: Scaffold(
            body: ProposalsSection(
              propostas: [proposta],
              onAcceptProposal: (item) => accepted = item,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dismissible = find.byType(Dismissible).first;
    expect(dismissible, findsOneWidget);

    await tester.fling(dismissible, const Offset(1000, 0), 2000);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(accepted, isNotNull);
    expect(accepted!.id, '1');
  });
}
