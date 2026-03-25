import 'package:flutter/material.dart';
import 'camera_screen.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {

  List<String> selecionados = [];

  final List<String> itens = [
    'Fachada',
    'Garagem',
    'Sala',
    'Cozinha',
    'Quarto',
    'Banheiro',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist da Vistoria'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Selecione os ambientes:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: itens.map((item) {
                final selecionado = selecionados.contains(item);

                return ChoiceChip(
                  label: Text(item),
                  selected: selecionado,
                  onSelected: (value) {
                    setState(() {
                      if (selecionado) {
                        selecionados.remove(item);
                      } else {
                        selecionados.add(item);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CameraScreen(),
                    ),
                  );
                },
                child: const Text('Ir para Coleta'),
              ),
            )
          ],
        ),
      ),
    );
  }
}