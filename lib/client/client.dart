import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:tic_tac_online/client/tcp_message.dart';

enum ClientState {
  disconnected,
  connecting,
  connected,
}

class Client {
  late io.Socket _socket;

  bool _isConnected = false;
  TcpHeader? _tempHeader;

  final _stateController = StreamController<ClientState>.broadcast();
  Stream<ClientState> get onStateChanged => _stateController.stream;

  final Queue<TcpMessage> messages = Queue();
  final List<int> buffer = [];

  Future<bool> connect(String address, int port) async {
    if (_isConnected) {
      throw Exception("Connection already established");
    }

    try {
      _stateController.add(ClientState.connecting);
      _socket = await io.Socket.connect(address, port);
      _socket.listen(_onData, onError: _onError, onDone: _onDone);
      _isConnected = true;
      _stateController.add(ClientState.connected);
      return _isConnected;
    } catch (ex) {
      _stateController.add(ClientState.disconnected);
      log(ex.toString());
      return false;
    }
  }

  Future<void> dispose() async {
    if (!_isConnected) {
      throw Exception("Socket is not connected");
    }

    await _socket.flush();
    _socket.close();
    _socket.destroy();
    _isConnected = false;
  }

  Future<void> send(TcpMessage message) async {
    if (!_isConnected) {
      throw Exception("Socket is not connected");
    }

    _socket.add(message.toBytes());
    await _socket.flush();
  }

  void _onDone() {
    _stateController.add(ClientState.disconnected);
    _isConnected = false;
  }

  void _onError(Object? error) {
    log(error.toString());
    _socket.destroy();
    _stateController.add(ClientState.disconnected);
    _isConnected = false;
  }

  void _onData(Uint8List recv) {
    buffer.addAll(recv);

    while (buffer.isNotEmpty) {
      if (_tempHeader == null && buffer.length >= TcpHeader.expectedSize) {
        _readHeader();
      }

      if (_tempHeader != null && buffer.length >= _tempHeader!.size) {
        _readBody();
      } else {
        break;
      }
    }
  }

  void _readHeader() {
    final data = buffer.sublist(0, TcpHeader.expectedSize);
    buffer.removeRange(0, TcpHeader.expectedSize);
    _tempHeader = TcpHeader.fromBytes(Uint8List.fromList(data));

    if (_tempHeader!.size == 0) {
      messages.add(TcpMessage(_tempHeader!, Uint8List(0)));
      _tempHeader = null;
    }
  }

  void _readBody() {
    if (_tempHeader != null && buffer.length >= _tempHeader!.size) {
      final messageData = buffer.sublist(0, _tempHeader!.size);
      buffer.removeRange(0, _tempHeader!.size);
      final message = TcpMessage(_tempHeader!, Uint8List.fromList(messageData));
      messages.add(message);
      _tempHeader = null;
    }
  }
}
