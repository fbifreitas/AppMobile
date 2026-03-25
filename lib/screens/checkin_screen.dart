import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'checklist_screen.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  bool? clientePresente;
  String? tipoImovel;

  final List<String> tipos = [
    'Urbano',
    'Rural',
    'Comercial',
    'Industrial',
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Vistoria'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 📍 GPS (simulado por enquanto)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Você está no local da vistoria'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 👤 CLIENTE PRESENTE?
            const Text(
              'Cliente está presente?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            Row(
              children: [
                ChoiceChip(
                  label: const Text('Sim'),
                  selected: clientePresente == true,
                  onSelected: (_) {
                    setState(() {
                      clientePresente = true;
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Não'),
                  selected: clientePresente == false,
                  onSelected: (_) {
                    setState(() {
                      clientePresente = false;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔥 MOSTRAR APENAS SE CLIENTE PRESENTE
            if (clientePresente == true) ...[

              /// 🏠 TIPO DE IMÓVEL (NBR 14653)
              const Text(
                'Tipo de imóvel',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: tipos.map((tipo) {
                  return ChoiceChip(
                    label: Text(tipo),
                    selected: tipoImovel == tipo,
                    onSelected: (_) {
                      setState(() {
                        tipoImovel = tipo;
                      });
                    },
                  );
                }).toList(),
              ),
            ],

            const Spacer(),

            /// 🔘 BOTÃO PRINCIPAL
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (clientePresente == null) {
                    _showErro('Selecione se o cliente está presente');
                    return;
                  }

                  /// ❌ CLIENTE AUSENTE
                  if (clientePresente == false) {
                    _showClienteAusente(appState);
                    return;
                  }

                  /// ✅ CLIENTE PRESENTE
                  if (tipoImovel == null) {
                    _showErro('Selecione o tipo de imóvel');
                    return;
                  }

                  appState.fazerCheckin(
                    clientePresente: true,
                    tipoImovel: tipoImovel,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChecklistScreen(),
                    ),
                  );
                },
                child: Text(
                  clientePresente == false
                      ? 'Encerrar / Reagendar'
                      : 'Confirmar e abrir vistoria',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⚠️ ALERTA DE ERRO
  void _showErro(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Atenção'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// ❌ CLIENTE AUSENTE (REAGENDAR)
  void _showClienteAusente(AppState appState) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cliente ausente'),
        content: const Text('Deseja solicitar reagendamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              appState.recusarJob();

              Navigator.of(context).pop(); // fecha popup
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Reagendar'),
          ),
        ],
      ),
    );
  }
}