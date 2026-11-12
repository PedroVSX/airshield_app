
import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  static const String _broker = 'broker.emqx.io';
  static const int _port = 1883;

  MqttServerClient? _client;
  StreamSubscription? _subscription;

  final StreamController<String> _messageController =
      StreamController<String>.broadcast();

  Stream<String> get messages => _messageController.stream;

  String? _currentTopic;

  bool get isConnected =>
      _client?.connectionStatus?.state ==
      MqttConnectionState.connected;

  Future<void> connectToDevice(String macAddress) async {
    
    final mac = macAddress.trim();

    if (mac.isEmpty) {
      throw Exception('MAC do AirShield não informado.');
    }

    final topic = 'airshield/$mac/dados-ambiente';

    print('MQTT: MAC recebido: $mac');
    print('MQTT: Tópico: $topic');
    
    await disconnect();

    final clientId =
        'airshield_app_${DateTime.now().millisecondsSinceEpoch}';

    final client = MqttServerClient.withPort(
      _broker,
      clientId,
      _port,
    );

    _client = client;
    _currentTopic = topic;

    client.logging(on: false);
    client.keepAlivePeriod = 30;
    client.autoReconnect = true;

    client.onConnected = () {
      print('MQTT: Conectado ao broker!');
    };

    client.onDisconnected = () {
      print('MQTT: Desconectado do broker.');
    };

    client.onSubscribed = (subscribedTopic) {
      print('MQTT: Inscrito no tópico: $subscribedTopic');
    };

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    try {
      print('Conectando ao broker MQTT...');

      await client.connect();

      if (client.connectionStatus?.state !=
          MqttConnectionState.connected) {
        throw Exception('Falha na conexão MQTT.');
      }

      print('Broker: $_broker');
      print('Tópico: $topic');

      _subscription = client.updates?.listen((messages) {
        for (final message in messages) {
          if (message.topic != topic) continue;

          final publishMessage =
              message.payload as MqttPublishMessage;

          final payload =
              MqttPublishPayload.bytesToStringAsString(
            publishMessage.payload.message,
          );

          print('Mensagem MQTT recebida: $payload');

          if (!_messageController.isClosed) {
            _messageController.add(payload);
          }
        }
      });

      client.subscribe(topic, MqttQos.atMostOnce);

    } catch (e) {
      print('Erro MQTT: $e');

      client.disconnect();

      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;

    _client?.disconnect();
    _client = null;
    _currentTopic = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
  }
}
