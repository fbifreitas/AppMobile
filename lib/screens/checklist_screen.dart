import 'package:flutter/material.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist da Vistoria')),
      body: const Center(
        child: Text(
          'Checklist placeholder',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}