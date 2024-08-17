import 'package:flutter/material.dart';

class ConnectingGameState extends StatelessWidget {
  const ConnectingGameState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator.adaptive(),
            SizedBox(height: 16),
            Text('Conectando ao servidor...'),
          ],
        ),
      ),
    );
  }
}
