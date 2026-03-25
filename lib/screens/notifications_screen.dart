import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens e Dúvidas')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Feature em construção.\n\nAqui entrarão as conversas sobre os jobs em andamento com o APP WEB.',
        ),
      ),
    );
  }
}