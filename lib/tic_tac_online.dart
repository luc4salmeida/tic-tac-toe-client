import 'package:flutter/material.dart';
import 'package:tic_tac_online/states/connecting_state.dart';
import 'package:tic_tac_online/states/game_state.dart';

import 'client/client.dart';
import 'states/login_state.dart';

class TicTacOnline extends StatefulWidget {
  const TicTacOnline({super.key});

  @override
  State<TicTacOnline> createState() => _TicTacOnlineState();
}

class _TicTacOnlineState extends State<TicTacOnline> {
  late Client client;
  late ClientState state;

  @override
  void initState() {
    client = Client();
    state = ClientState.disconnected;
    client.onStateChanged.listen(onStateChanged);
    super.initState();
  }

  void onStateChanged(ClientState state) {
    this.state = state;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: _buildState(context)),
    );
  }

  Widget _buildState(BuildContext context) {
    switch (state) {
      case ClientState.disconnected:
        return LoginState(client: client);
      case ClientState.connected:
        return GameState(client: client);
      case ClientState.connecting:
        return const ConnectingGameState();
    }
  }
}
