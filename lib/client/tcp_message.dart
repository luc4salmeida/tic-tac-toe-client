import 'dart:typed_data';

enum PackageType {
  startGame,
  playerMove,
  endGame,
  gameState,
}

class TcpHeader {
  int id = 0;
  int size = 0;

  static int get expectedSize => 8;

  TcpHeader(this.id, this.size);

  Uint8List toBytes() {
    final buffer = ByteData(8);
    buffer.setInt32(0, id, Endian.little);
    buffer.setInt32(4, size, Endian.little);
    return buffer.buffer.asUint8List();
  }

  factory TcpHeader.fromBytes(Uint8List bytes) {
    final buffer = ByteData.sublistView(bytes);
    final id = buffer.getInt32(0, Endian.little);
    final size = buffer.getInt32(4, Endian.little);
    return TcpHeader(id, size);
  }
}

class TcpMessage {
  TcpHeader header = TcpHeader(0, 0);
  Uint8List body = Uint8List.fromList([]);

  TcpMessage(this.header, this.body);

  factory TcpMessage.empty(int id) {
    return TcpMessage(TcpHeader(id, 0), Uint8List.fromList([]));
  }

  Uint8List toBytes() {
    final headerBytes = header.toBytes();
    final buffer = Uint8List(headerBytes.length + body.length);
    buffer.setAll(0, headerBytes);
    buffer.setAll(headerBytes.length, body);
    return buffer;
  }

  factory TcpMessage.fromBytes(Uint8List bytes) {
    final header = TcpHeader.fromBytes(bytes.sublist(0, 8));
    final body = bytes.sublist(8);
    return TcpMessage(header, body);
  }

  void addInt(int value) {
    final buffer = ByteData(4);
    buffer.setInt32(0, value, Endian.little);
    body = Uint8List.fromList([...body, ...buffer.buffer.asUint8List()]);
    header.size += 4;
  }

  int popInt() {
    final buffer = ByteData.sublistView(body);
    final value = buffer.getInt32(0, Endian.little);
    body = body.sublist(4);
    header.size -= 4;
    return value;
  }
}
