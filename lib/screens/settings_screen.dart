import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Feature em construção.\n\nAqui entrarão perfil, dados pessoais, dados jurídicos e bancários.',
        ),
      ),
    );
  }
}