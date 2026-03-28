import 'package:flutter/material.dart';

import '../services/clean_code_maturity_service.dart';
import '../widgets/clean_code_maturity_card.dart';

class CleanCodeMaturityScreen extends StatelessWidget {
  const CleanCodeMaturityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const CleanCodeMaturityService().items();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maturidade de clean code'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CleanCodeMaturityCard(items: items),
        ],
      ),
    );
  }
}
