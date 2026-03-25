import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

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
    final job = appState.jobAtual;

    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Check-in Vistoria')),
        body: const Center(
          child: Text('Nenhum job selecionado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Vistoria'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.endereco,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

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
                  Text('GPS confirmado no local'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('WhatsApp'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Ligar'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              'Cliente está presente?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

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

            if (clientePresente == true) ...[
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

            if (clientePresente == true) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _mostrarInfo(context, 'Etapa 2 ainda será implementada.');
                  },
                  child: const Text('Ir para etapa 2 do check-in'),
                ),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (clientePresente == null) {
                    _mostrarInfo(
                      context,
                      'Selecione se o cliente está presente.',
                    );
                    return;
                  }

                  if (clientePresente == false) {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Cliente ausente'),
                        content: const Text(
                          'Deseja solicitar reagendamento da vistoria?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Confirmar'),
                          ),
                        ],
                      ),
                    );

                    if (confirmar == true) {
                      appState.recusarJob();
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    }
                    return;
                  }

                  if (tipoImovel == null) {
                    _mostrarInfo(context, 'Selecione o tipo de imóvel.');
                    return;
                  }

                  appState.fazerCheckin(
                    clientePresente: true,
                    tipoImovel: tipoImovel,
                  );

                  _mostrarInfo(
                    context,
                    'Próximo passo: abrir câmera.',
                  );
                },
                child: Text(
                  clientePresente == false
                      ? 'Solicitar reagendamento'
                      : 'Confirmar e abrir a câmera',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarInfo(BuildContext context, String msg) {
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
}