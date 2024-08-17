import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tic_tac_online/client/client.dart';
import 'package:tic_tac_online/client/tcp_message.dart';

class GameState extends StatefulWidget {
  final Client client;

  const GameState({
    required this.client,
    super.key,
  });

  @override
  State<GameState> createState() => _GameStateState();
}

class _GameStateState extends State<GameState> {
  List<int> board = List.filled(9, 0);

  late Ticker ticker;
  late bool isStarted;
  late int winnerId = -1;
  late int turn = 1;
  late int playerId = 0;

  final Map<int, String> values = {
    0: ' ',
    1: 'X',
    2: 'O',
  };

  @override
  void initState() {
    isStarted = false;
    ticker = Ticker(update);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ticker.start();
    });
    super.initState();
  }

  @override
  void dispose() {
    ticker.dispose();
    widget.client.dispose();
    super.dispose();
  }

  Future<void> update(Duration duration) async {
    if (widget.client.messages.isNotEmpty) {
      onMessage(widget.client.messages.removeFirst());
    }
  }

  void sendMovement(int index) {
    final msg = TcpMessage.empty(PackageType.playerMove.index);
    msg.addInt(index);
    widget.client.send(msg);
  }

  void onMessage(TcpMessage msg) async {
    if (msg.header.id == PackageType.startGame.index) {
      _handleGameStart(msg);
    } else if (msg.header.id == PackageType.gameState.index) {
      _handleGameState(msg);
    } else if (msg.header.id == PackageType.endGame.index) {
      _handleGameEnd(msg);
    }

    setState(() {});
  }

  void _handleGameStart(TcpMessage msg) {
    isStarted = true;
    playerId = msg.popInt();
  }

  void _handleGameState(TcpMessage msg) {
    for (var i = 0; i < board.length; i++) {
      board[i] = msg.popInt();
    }
    turn = msg.popInt();
  }

  void _handleGameEnd(TcpMessage msg) {
    winnerId = msg.popInt();
  }

  @override
  Widget build(BuildContext context) {
    if (!isStarted) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Esperando o jogo começar...'),
            SizedBox(
              height: 16.0,
            ),
            CircularProgressIndicator(),
          ],
        ),
      );
    }

    if (winnerId != -1) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            winnerId != 0
                ? Text('O jogador $winnerId venceu!')
                : const Text('Empate!'),
            ElevatedButton(
              onPressed: () {
                widget.client.dispose();
              },
              child: const Text('Jogar novamente'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sua vez: ${playerId == turn ? 'Sim' : 'Não'}',
              style: TextStyle(
                color: playerId == 1 ? Colors.red : Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 36.0,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(board.length ~/ 3, (index) {
                  final start = index * 3;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final value = board[start + i];
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: TextButton(
                            onPressed: () {
                              if (value == 0) {
                                sendMovement(start + i);
                              }
                            },
                            child: Text(
                              values[value] ?? '-',
                              style: TextStyle(
                                fontSize: 24,
                                color: value == 1 ? Colors.red : Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
