import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Minimal MQTT 3.1.1 wire fixture for real TCP/WebSocket integration tests.
/// Handles CONNECT, SUBSCRIBE, PINGREQ, QoS 0 PUBLISH and disconnect only.
class MqttTestBroker {
  ServerSocket? _tcp;
  HttpServer? _http;
  final _peers = <_Peer>[];
  final topics = <String>[];
  final clientIds = <String>[];
  final credentials = <List<String>>[];
  bool rejectSubscription = false;
  bool withholdSubscription = false;
  String? webSocketPath;

  int get port => _tcp?.port ?? _http!.port;

  Future<void> start({bool webSocket = false}) async {
    if (webSocket) {
      _http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _http!.listen((request) async {
        webSocketPath = request.uri.path;
        final ws = await WebSocketTransformer.upgrade(
          request,
          protocolSelector: (protocols) => protocols.first,
        );
        final peer = _Peer(
          (bytes) => ws.add(bytes),
          () => unawaited(ws.close()),
        );
        _attach(peer, ws.cast<List<int>>());
      });
    } else {
      _tcp = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      _tcp!.listen((socket) {
        _attach(_Peer(socket.add, socket.destroy), socket);
      });
    }
  }

  void _attach(_Peer peer, Stream<List<int>> input) {
    _peers.add(peer);
    peer.subscription = input.listen(
      (bytes) {
        peer.buffer.addAll(bytes);
        while (peer.buffer.length >= 2) {
          var offset = 1;
          var length = 0;
          var multiplier = 1;
          var complete = false;
          while (offset < peer.buffer.length) {
            final value = peer.buffer[offset++];
            length += (value & 127) * multiplier;
            multiplier *= 128;
            if (value < 128) {
              complete = true;
              break;
            }
          }
          if (!complete || peer.buffer.length < offset + length) return;
          final type = peer.buffer.first >> 4;
          final body = peer.buffer.sublist(offset, offset + length);
          peer.buffer.removeRange(0, offset + length);
          _handle(peer, type, body);
        }
      },
      onError: (Object _) {},
      onDone: () => _peers.remove(peer),
    );
  }

  void _handle(_Peer peer, int type, List<int> body) {
    switch (type) {
      case 1:
        var offset = 10;
        String readString() {
          final length = body[offset] * 256 + body[offset + 1];
          offset += 2;
          final value = utf8.decode(body.sublist(offset, offset + length));
          offset += length;
          return value;
        }
        clientIds.add(readString());
        final auth = <String>[];
        if ((body[7] & 128) != 0) auth.add(readString());
        if ((body[7] & 64) != 0) auth.add(readString());
        credentials.add(auth);
        peer.send([0x20, 2, 0, 0]);
      case 8:
        final length = body[2] * 256 + body[3];
        topics.add(utf8.decode(body.sublist(4, 4 + length)));
        if (!withholdSubscription) {
          peer.send([0x90, 3, body[0], body[1], rejectSubscription ? 0x80 : 0]);
        }
      case 12:
        peer.send([0xd0, 0]);
      case 14:
        peer.close();
    }
  }

  void publish(String topic, String payload, {bool retained = false}) {
    final encodedTopic = utf8.encode(topic);
    final body = [
      encodedTopic.length >> 8,
      encodedTopic.length & 255,
      ...encodedTopic,
      ...utf8.encode(payload),
    ];
    var length = body.length;
    final remaining = <int>[];
    do {
      var byte = length % 128;
      length ~/= 128;
      if (length > 0) byte |= 128;
      remaining.add(byte);
    } while (length > 0);
    for (final peer in List<_Peer>.of(_peers)) {
      peer.send([retained ? 0x31 : 0x30, ...remaining, ...body]);
    }
  }

  void dropClients() {
    for (final peer in List<_Peer>.of(_peers)) {
      peer.close();
    }
    _peers.clear();
  }

  Future<void> close() async {
    for (final peer in List<_Peer>.of(_peers)) {
      await peer.subscription?.cancel();
      peer.close();
    }
    _peers.clear();
    await _tcp?.close();
    await _http?.close(force: true);
  }
}

class _Peer {
  _Peer(this.send, this.close);
  final void Function(List<int>) send;
  final void Function() close;
  final buffer = <int>[];
  StreamSubscription<List<int>>? subscription;
}
