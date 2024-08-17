import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:tic_tac_online/client/client.dart';

class LoginState extends StatefulWidget {
  final Client client;

  const LoginState({
    required this.client,
    super.key,
  });

  @override
  State<LoginState> createState() => _LoginStateState();
}

class _LoginStateState extends State<LoginState> {
  Future<void> onConnectPressed() async {
    try {
      await widget.client.connect("127.0.0.1", 30000);
    } catch (ex) {
      log(ex.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: onConnectPressed,
            child: const Text('Conectar ao servidor'),
          ),
        ],
      ),
    );
  }
}
